local parser  = require("notepad.features.flashcards.parser")
local io = require("notepad.features.flashcards.io")
local store = require("notepad.features.flashcards.metadata")
local schema = require("notepad.features.flashcards.schema")

local M = {}

-- Returns a table of cards of the form
-- {
--  question: string,
--  answer: string,
--  path:string,
--  note_id = table,
--  fsrs: table
-- }
function M.due_today(vault_path)
    local now = os.time()
    local due_cards = {}

    local vault_files = io.scan_markdown(vault_path)
    local cards = parser.parse_files(vault_files)

    for _, card in ipairs(cards) do
        assert(card.source.hash, "card missing source.hash")
        if card.note_id then
            local note = store._state.notes[card.note_id]
            if note then
                note.fsrs = note.fsrs or schema.default_fsrs_state()

                card.metadata = {
                    fsrs = note.fsrs
                }

                if note.fsrs.due and note.fsrs.due <= now then
                    table.insert(due_cards, {
                        question = card.question,
                        answer   = card.answer,
                        path     = card.source.path,
                        id       = note.id,
                        fsrs     = note.fsrs
                    })
                end
            end
        end
    end

    return due_cards
end

return M
