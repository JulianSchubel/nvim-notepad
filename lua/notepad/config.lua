local files = require("notepad.files")

local Module = {}

local NOTEPAD_DIR = "/notepad"

local defaults = {
    layout = "right",
    width_ratio = 0.7,
    height_ratio = 0.7,
    split_width = 40,
    border = "rounded",
    files = {
        notepad = vim.fn.stdpath("data") .. NOTEPAD_DIR .. "/notepad.md",
        today = function()
            return vim.fn.stdpath("data")
                .. "/notepad/"
                .. os.date("%Y-%m-%d")
                .. ".md"
        end,
    },
}

function Module.setup(opts)
    --Merge user opts and defaults
    Module.opts = vim.tbl_deep_extend("force", defaults, opts or {})

    --Set notepad directory to OS path
    Module.opts.notepad_dir = vim.fn.stdpath("data") .. NOTEPAD_DIR

    --Check whether the notepad directory exists otherwise create it
    if vim.fn.isdirectory(Module.opts.notepad_dir) == 0 then
        --Create the directory and any parent directories necessary
        vim.fn.mkdir(Module.opts.notepad_dir, "p")
    end
    --Load files from disk into config.opts.files 
    files.load_notes(Module.opts)
end

return Module
