local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local state = require("telescope.actions.state")
local conf = require("telescope.config").values

local Module = {}

function Module.open(opts)
    local keys = vim.tbl_keys(opts.files)

    pickers.new({}, {
        prompt_title = "Notepads",
        finder = finders.new_table(keys),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(_, map)
            map("i", "<CR>", function(bufnr)
                local name = state.get_selected_entry().value
                actions.close(bufnr)

                -- Delegate to core logic (toggle-safe)
                require("notepad").open(name)
            end)

            return true
        end,
    }):find()
end

return Module
