-- notepad/features/flashcards/review.lua
local fsrs    = require("notepad.features.flashcards.fsrs.fsrs")
local schema  = require("notepad.features.flashcards.schema")
local storage = require("notepad.features.flashcards.storage")
local metadata = require("notepad.features.flashcards.metadata_store")

local M = {}

function M.start(card)
    card.metadata = card.metadata or {}

    -- Always initialize FSRS state
    local fsrs_state = schema.ensure(card.metadata.fsrs)
        or schema.default_fsrs_state()

    card.metadata.fsrs = fsrs_state

    return {
        card  = card,
        fsrs  = fsrs_state,
        start = os.time(),
    }
end


function M.apply_rating(session, rating)
    assert(session.fsrs, "review session has no fsrs state")
    local now = os.time()

    local next_state = fsrs.review(
        session.fsrs,
        rating,
        now
    )

    -- fsrs.review MUST return a state
    assert(next_state, "fsrs.review returned nil")

    session.card.metadata.fsrs = next_state
    session.fsrs = next_state

    if session.card.path and vim.loop.fs_stat(session.card.path) then
        metadata.serialize()
        --storage.write_card(session.card)
    end

    return next_state
end

return M

