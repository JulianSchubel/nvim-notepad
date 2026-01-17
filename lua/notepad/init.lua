local config = require("notepad.config")
local utilities = require("notepad.utilities")
local window = require("notepad.window")
local features = require("notepad.features")
local telescope = require("notepad.ui.telescope")
local metadata = require("notepad.features.flashcards.metadata")

local Module = {}

function Module.setup(opts)
    -- Set Module options
    config.setup(opts);

    -- Fetch stored metadata
    metadata.deserialize();

    --Toggle item as complete / incomplete
    vim.keymap.set("n", "<leader>nx", features.toggle)
    --Remove completed items
    vim.keymap.set("n", "<leader>nr", features.remove_completed)
    --Insert an incomplete item
    vim.keymap.set("n", "<leader>ni", "i- `[]` ")
    --Set entry point command
    vim.api.nvim_create_user_command(
        "Notepad",
        function() telescope.open(config.opts) end,
        { desc = "Open Neovim Notepad" }
    );
    --Bind entry point to keymap
    vim.keymap.set(
        "n",
        "<leader>nn",
        "<cmd>Notepad<cr>",
        { desc = "Open Neovim Notepad" }
    )

    -- Create test command
    vim.api.nvim_create_user_command("NotepadTest", function()
        require("plenary.busted").run()
    end, {})

    vim.api.nvim_create_user_command("NotepadDueToday", function()
        require("notepad.features.flashcards.ui.telescope.daily_picker").open({
            vault_path = require("notepad.config").vault_path,
        })
    end, {})

    vim.api.nvim_create_user_command("NotepadDailyReview", function()
        require("notepad.features.flashcards.daily").run()
    end, {})

    vim.keymap.set("n", "<leader>Fr", function()
        require("notepad.features.flashcards.daily").run()
    end, { desc = "Notepad: Daily review" })

    --    vim.api.nvim_create_autocmd("VimEnter", {
    --        callback = function()
    --            require("notepad.features.flashcards.daily").run()
    --        end,
    --    })
end

function Module.open(name)
    local path = utilities.fs.resolve(name, config.opts)
    local buf = utilities.fs.load_file_buffer(path)
    window.open(buf, path, config.opts)
end

function Module.create(name)
    if not utilities.fs.is_valid_notename(name) then
        vim.notify(
            "Invalid note name. Use letters, numbers, hyphens, and underscores only.",
            vim.log.levels.ERROR
        )
        return
    end
    if config.opts.files[name] then
        vim.notify("Note already exists: " .. name, vim.log.levels.WARN)
        return
    end

    config.opts.files[name] = function()
        return config.opts.notepad_dir .. "/" .. name .. ".md"
    end
    Module.open(name)
end

function Module.delete(name, opts)
    if not utilities.fs.is_valid_notename(name) then
        return nil, "Invalid note"
    end
    local path = utilities.fs.resolve(name, config.opts);
    local ok, err = utilities.fs.delete_file(path);
    if ok then
        vim.notify("loading notes");
    end
    config.opts.files[name] = nil;
    utilities.fs.load_notes(config.opts);
    return ok, err;
end

Module.toggle = features.toggle
Module.remove_completed = features.remove_completed

return Module
