local modal = require("notepad.ui.modal")
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

local function daily_note()
    local date = os.date("%Y-%m-%d");
    if not require("notepad.config").opts.files[date] then
        require("notepad").create(date);
    end
    require("notepad").open(date);
end

local function confirm_delete(note, on_done)
    local _, modal_buf = modal.show({
        "Delete note?",
        "",
        note,
    }, {
        title = "Confirm deletion",
        exit_prompt = false,
    })

    local buf = vim.api.nvim_get_current_buf()
    --Set keymaps for the current buffer only
    vim.keymap.set("n", "y", function()
        modal.close(modal_buf)
        local ok, err = require("notepad").delete(note, require("notepad.config").opts)
        if not ok then
            modal.show(err, { title = "Error" })
        end
        if on_done then on_done(ok) end
    end, { buffer = buf })
    vim.keymap.set("n", "n", function() modal.close(modal_buf) end, { buffer = buf })
    vim.keymap.set("n", "<Esc>", function() modal.close(modal_buf) end, { buffer = buf })
end

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
                require("notepad").create(name)
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

    --Create a new Telecope picker
    local prompt_bufnr = pickers.new({}, {
        --Sets the picker prompt title 
        prompt_title = "Search Notes",
        --Provides a static list of key strings (each value is derived from the
        --configured logical note names)
        finder = finders.new_table(entries),
        --Use Telescope's default fuzzy sorter (Respects user configuration)
        sorter = conf.generic_sorter({}),
        --Define the custom key behaviour for the picker
        attach_mappings = function(_, map)
            --Select a note
            --Override <Enter> in insert mode
            map("i", "<CR>", function(bufnr)
                --Read the currently seleced item from the picker
                --(.value mathces the original entry from entries)
                local entry = state.get_selected_entry().value
                --Close the Telescope picker
                actions.close(bufnr)

                --Delegate opening to core logic passing the logical name as
                --argument
                require("notepad").open(entry, opts)
            end)
            --Create a note
            map("n", "c", function(bufnr)
                actions.close(bufnr)
                if prompt_new_note(opts, "", 0) == -1 then
                    --If an esc key or no name provided reopen the picker
                    Module.open(opts)
                end
            end)
            --Delete a note
            map("n", "d", function(bufnr)
                local entry = state.get_selected_entry()
                if not entry then return end
                confirm_delete(entry.value, function(deleted)
                    if(deleted) then
                        Module.open(require("notepad.config").opts)
                    end;
                end)
            end)
            map("n", "t", function(bufnr)
                actions.close(bufnr)
                daily_note()
            end)
            --Signal to Telescope that mappings were successfully attached
            --Required for custom mappings to remain active
            return true
        end,
    }):find() --Finalizes picker construction and immediately opens the Telescope window
end

return Module
