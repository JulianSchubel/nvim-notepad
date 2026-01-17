-- notepad/features/flashcards/review.lua
local fsrs     = require("notepad.features.flashcards.fsrs.fsrs")
local schema   = require("notepad.features.flashcards.schema")
local metadata = require("notepad.features.flashcards.metadata")

local M = {}

function M.start(card)
    assert(card.id, "card missing note_id")

    local note = metadata._state.notes[card.id]
    assert(note, "note not found in metadata store")

    note.fsrs = schema.ensure(note.fsrs) or schema.default_fsrs_state()

    return {
        note  = note,
        start = os.time(),
    }
end

function M.apply_rating(session, rating)
    local now = os.time()

    local next_state = fsrs.review(session.note.fsrs, rating, now)
    assert(next_state, "fsrs.review returned nil")
    next_state.last_review = now;

    session.note.fsrs = next_state

    metadata.serialize()

    return next_state
end

return M

