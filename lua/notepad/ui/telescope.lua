--Creates a picker instance
local pickers = require("telescope.pickers")
--Supplies data to display
local finders = require("telescope.finders")
--Common picker actions (close, select, etc)
local actions = require("telescope.actions")
--Access to current picker state (selected entry)
local state = require("telescope.actions.state")
--User configured defaults(sorters, layouts)
local conf = require("telescope.config").values

--Provides the telescope UI layer
local Module = {}

--Prompt the user to input the new notes name
local function prompt_new_note(opts, previous, retry_count)
    local result = 0;
    vim.ui.input(
        {
            prompt = "Note name:",
            default = previous
        },
        function(name)
            if not name then
                result = -1
                return
            end

            if require("notepad.files").is_valid_notename(name) then
                --Create the note
                require("notepad").create(name, opts)
                return
            else
                --Notify the user that the name provided was invalid
                local prefix = ''
                if retry_count > 0 then
                    prefix = '\n'
                end
                vim.notify(prefix .. "Invalid note name", vim.log.levels.ERROR)
                result = prompt_new_note(opts, name, retry_count + 1)
            end
        end
    )
    return result
end

--Open a Telescope picker showing all configured note names and opens the select
--one
function Module.open(opts)
    --Extract the configured logical note names
    local entries = vim.tbl_keys(opts.files)
    --Add the create new note option
    table.insert(entries, "Create new note...")

    --Create a new Telecope picker
    pickers.new({}, {
        --Sets the picker title displayed at the top
        prompt_title = "Notes",
        --Provides a static list of key strings (each value is derived from the
        --configured logical note names)
        finder = finders.new_table(entries),
        --Use Telescope's default fuzzy sorter (Respects user configuration)
        sorter = conf.generic_sorter({}),
        --Define the custom key behaviour for the picker
        attach_mappings = function(_, map)
            --Override <Enter> in insert mode
            map("i", "<CR>", function(bufnr)
                --Read the currently seleced item from the picker
                --(.value mathces the original entry from entries)
                local entry = state.get_selected_entry().value
                --Close the Telescope picker

                actions.close(bufnr)
                if entry == "Create new note..." then
                    if prompt_new_note(opts, "", 0) == -1 then
                        Module.open(opts)
                    else
                        --Delegate opening to core logic passing the logical name as
                        --argument
                        require("notepad").open(entry, opts)
                    end
                else
                    --Delegate opening to core logic passing the logical name as
                    --argument
                    require("notepad").open(entry, opts)
                end
            end)
            --Signal to Telescope that mappings were successfully attached
            --Required for custom mappings to remain active
            return true
        end,
    }):find() --Finalizes picker construction and immediately opens the Telescope window
end

return Module
