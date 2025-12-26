local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

local Module = {}

function Module.open(opts)
    local keys = vim.tbl_keys(opts.files)

    pickers.new({}, {
        prompt_title = "Notepad Files",
        finder = finders.new_table(keys),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(_, map)
            map("i", "<CR>", function(bufnr)
                local name = require("telescope.actions.state").get_selected_entry().value
                require("telescope.actions").close(bufnr)
                require("notepad").open(name)
            end)
            return true
        end,
    }):find()
end

return Module
