-- FSRS review UI (uses base modal widget)
local modal = require("notepad.ui.modal")
local review = require("notepad.features.flashcards.review")
local store = require("notepad.features.flashcards.stats.store")
local compute = require("notepad.features.flashcards.stats.compute")
local utilities = require("notepad.utilities")

local M = {}

local RATINGS = {
    ["1"] = 1, -- Again
    ["2"] = 2, -- Hard
    ["3"] = 3, -- Good
    ["4"] = 4, -- Easy
}

function M.open(card, on_done)
    local session = review.start(card)

    local lines = vim.split(card.question, "\n", { plain = true })
    local answer =  vim.split(card.answer, "\n", { plain = true })

    table.insert(lines, "")
    table.insert(lines, "---")
    table.insert(lines, "")
    table.insert(lines, "1 Again   2 Hard   3 Good   4 Easy")
    table.insert(lines, "")
    table.insert(lines, "---")
    table.insert(lines, "")

    local events = store.all()
    local footer = string.format(
      "Reviewed today: %d | Streak: %d days",
      compute.today(events),
      compute.streak(events)
    )
    table.insert(lines, footer);

    local modal_id;
    modal_id = modal.show(lines, {
        title = "Flashcard Review",
        exit_prompt = false,
        input = { enabled = true, filetype = "markdown", on_submit = function(args)
            if utilities.string.trim(args.value) == table.concat(answer) then
                vim.notify("Correct! The answer is: " .. tostring(args.value), vim.log.levels.INFO);
            else
                vim.notify("Incorrect Answer: " .. args.value .. ", Expected: " .. table.concat(answer), vim.log.levels.ERROR);
            end
        end},
    })

    local buf = modal.state[modal_id].content_buffer

    for key, rating in pairs(RATINGS) do
        vim.keymap.set("n", key, function()
            review.apply_rating(session, rating)
                modal.close(modal_id)
            if on_done then on_done() end
        end, { buffer = buf, nowait = true })
    end

--    vim.keymap.set("n", "<Esc>", function()
--        modal.close(modal_id)
--    end, { buffer = buf })
end




return M
