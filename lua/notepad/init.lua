local config = require("notepad.config")
local files = require("notepad.files")
local window = require("notepad.window")
local features = require("notepad.features")
local telescope = require("notepad.ui.telescope")

local Module = {}

function Module.setup(opts)
    config.setup(opts)
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
end

function Module.open(name)
    local path = files.resolve(name, config.opts)
    local buf = files.load_file_buffer(path)
    window.open(buf, path, config.opts)
end

function Module.create(name, opts)
    if not files.is_valid_notename(name) then
        vim.notify(
            "Invalid note name. Use letters, numbers, hyphens, and underscores only.",
            vim.log.levels.ERROR
        )
        return
    end
    if opts.files[name] then
        vim.notify("Note already exists: " .. name, vim.log.levels.WARN)
        return
    end

    files.resolve(name, config.opts);
    opts.files[name] = function()
        return opts.notepad_dir .. "/" .. name .. ".md"
    end
    files.load_notes(opts)
end

function Module.delete(name, opts)
    if not files.is_valid_notename(name) then
        return nil, "Invalid note"
    end
    local path = files.resolve(name, config.opts);
    local ok, err = files.delete_file(path);
    if ok then
        vim.notify("loading notes");
    end
    opts.files[name] = nil;
    files.load_notes(opts);
    return ok, err;
end

Module.toggle = features.toggle
Module.remove_completed = features.remove_completed

return Module
