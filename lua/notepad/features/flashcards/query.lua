local parser  = require("notepad.features.flashcards.parser")
local storage = require("notepad.features.flashcards.storage")
local store = require("notepad.features.flashcards.metadata_store")

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

    local vault_files = storage.scan_markdown(vault_path);

    local cards = parser.parse_files(vault_files);
    for _, card in ipairs(cards) do
        local note = store.resolve(card.source.path)
        -- If note.fsrs == nil, the card is not due.
        if note.fsrs and note.fsrs.due and note.fsrs.due <= now then
            table.insert(due_cards, {
                question = card.question,
                answer = card.answer,
                path = card.source.path,
                note_id = note.id,
                fsrs = note.fsrs
            })
        end
        table.insert(due_cards, {
            question = card.question,
            answer = card.answer,
            path = card.source.path,
            note_id = note.id,
            fsrs = note.fsrs
        })
    end

    return due_cards
end

return M
