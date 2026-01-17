-- Due flashcard telescope picker
local query = require("notepad.features.flashcards.query")
local review_modal = require("notepad.features.flashcards.ui.modal.review_modal")
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local conf = require("telescope.config").values

local M = {}

function M.open(opts)
    opts = opts or {}

    -- Lazy-load Telescope
    local ok, pickers = pcall(require, "telescope.pickers")
    if not ok then
        error("Telescope is required for flashcard UI")
    end

    local vault = opts.vault_path
    local cards = query.due_today(vault)

    pickers.new(opts, {
        prompt_title = "Flashcards Due Today",
        finder = finders.new_table({
            results = cards,
            entry_maker = function(card)
                return {
                    value = card,
                    display = card.question or vim.fn.fnamemodify(card.path, ":t"),
                    ordinal = card.title or card.path,
                    path = card.path,
                }
            end,
        }),
--        previewer = previewers.new_buffer_previewer({
--            define_preview = function(self, entry)
--                vim.api.nvim_buf_set_lines(
--                    self.state.bufnr,
--                    0,
--                    -1,
--                    false,
--                    { entry.question }
--                )
--                vim.bo[self.state.bufnr].filetype = "markdown"
--            end,
--        }),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)
            map("i", "<CR>", function()
                local entry = require("telescope.actions.state").get_selected_entry()
                require("telescope.actions").close(prompt_bufnr)

                if entry then 
                    review_modal.open(entry.value, function()
                        vim.schedule(function()
                            M.open(opts)
                        end)
                    end)
                end;
            end)
            return true
        end,
    }):find()
end

return M

