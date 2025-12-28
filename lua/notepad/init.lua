local config = require("notepad.config")
local files = require("notepad.files")
local window = require("notepad.window")
local utilities = require("notepad.utilities")
local telescope = require("notepad.ui.telescope")
local modal = require("notepad.ui.modal")

local Module = {}

function Module.setup(opts)
    config.setup(opts)
    vim.keymap.set("n", "<leader>nx", utilities.toggle)
    vim.keymap.set("n", "<leader>na", utilities.archive)
    vim.api.nvim_create_user_command(
        "Notepad",
        function() telescope.open(config.opts) end,
        { desc = "Open Neovim Notepad" }
    );
    vim.api.nvim_create_user_command(
        "Modal",
        function() modal.show("Hello, world!") end,
        { desc = "Open modal window" }
    );
    vim.keymap.set(
        "n",
        "<leader>nn",
        "<cmd>Notepad<cr>",
        { desc = "Open Neovim Notepad" }
    )
end

function Module.open(name, opts)
    local path = files.resolve(name, opts)
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

    opts.files[name] = function()
        return opts.notepad_dir .. "/" .. name .. ".md"
    end
    files.load_notes(opts)
end

Module.toggle = utilities.toggle
Module.archive = function() utilities.archive(config.opts) end

return Module
