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

    local question = vim.split(card.question, "\n", { plain = true })
    local answer =  vim.split(card.answer, "\n", { plain = true })

    local content_separator = {"", "---", ""}

    local events = store.all()
    local footer = {
        "1 Again   2 Hard   3 Good   4 Easy",
        "",
        "---",
        "",
--        string.format(
--            "Reviewed today: %d | Streak: %d days",
--            compute.today(events),
--            compute.streak(events)
--        ),
    };
    local content = {}
    vim.list_extend(content, question);
    vim.list_extend(content, content_separator);
    vim.list_extend(content, footer);

    local modal_id;
    modal_id = modal.show(content, {
        title = "Flashcard Review",
        exit_prompt = false,
        input = { enabled = true, filetype = "markdown", on_submit = function(args)
            local new_content = {}
            vim.list_extend(new_content, question);
            vim.list_extend(new_content, content_separator);
            vim.list_extend(new_content, answer);
            vim.list_extend(new_content, content_separator);
            vim.list_extend(new_content, footer);
            local title = "";
            if utilities.string.trim(args.value) == table.concat(answer) then
                title = "Correct"
            else
                title = "Incorrect"
            end
            local new_modal_id = modal.show(new_content, {
                title = title,
                exit_prompt = false,
                input = { enable = false, filetype = "markdown" }
            });
            local buf = modal.state[new_modal_id].content_buffer

            for key, rating in pairs(RATINGS) do
                vim.keymap.set("n", key, function()
                    review.apply_rating(session, rating)
                        modal.close(new_modal_id)
                    if on_done and type(on_done) == "function" then on_done() end
                end, { buffer = buf, nowait = true })
            end
        end},
    });

    local buf = modal.state[modal_id].content_buffer

    for key, rating in pairs(RATINGS) do
        vim.keymap.set("n", key, function()
            review.apply_rating(session, rating)
                modal.close(modal_id)
            if on_done and type(on_done) == "function" then on_done() end
        end, { buffer = buf, nowait = true })
    end
end

return M
