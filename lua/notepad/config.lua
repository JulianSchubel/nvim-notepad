local files = require("notepad.files")

local Module = {}

local defaults = {
    layout = "right",
    width_ratio = 0.7,
    height_ratio = 0.7,
    split_width = 40,
    border = "rounded",
--    files = {
--        notepad = vim.fn.stdpath("data") .. NOTEPAD_DIR .. "/notepad.md",
--        today = function()
--            return vim.fn.stdpath("data")
--                .. "/notepad/"
--                .. os.date("%Y-%m-%d")
--                .. ".md"
--        end,
--    },
    flashcards = {
        enabled = true,
        vault_path = "/home/js/projects/nvim-notepad/notepad_test_vault",
    },
    _notepad_dir = "/notepad",
}

function Module.setup(opts)
    --Merge user opts and defaults
    Module.opts = vim.tbl_deep_extend("force", defaults, opts or {})

    if type(Module.opts.flashcards.vault_path) ~= "string" then
        error(
            "[nvim-notepad] flashcards.vault_path is required.\n" ..
            "Configure it via require('notepad').setup({ flashcards = { vault_path = '...' } })"
        )
    end


    --Set notepad directory to OS path
    Module.opts.notepad_dir = vim.fn.stdpath("data") .. Module.opts._notepad_dir

    --Check whether the notepad directory exists otherwise create it
    if vim.fn.isdirectory(Module.opts.notepad_dir) == 0 then
        --Create the directory and any parent directories necessary
        vim.fn.mkdir(Module.opts.notepad_dir, "p")
    end
    --Load files from disk into config.opts.files 
    files.load_notes(Module.opts)
end

return Module
