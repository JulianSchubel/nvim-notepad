local Files = require("notepad.files")

local Module = {}

local NOTEPAD_DIR = "/notepad"
Module.defaults = {
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

    archive = {
        enabled = true,
        pattern = "^%- %[%x%]",
        file = vim.fn.stdpath("data") .. NOTEPAD_DIR .. "/archive.md",
    },
}

function Module.setup(opts)
    --Merge user opts and defaults
    Module.opts = vim.tbl_deep_extend("force", Module.defaults, opts or {})

    --Set notepad directory to OS path
    Module.opts.notepad_dir = vim.fn.stdpath("data") .. NOTEPAD_DIR

    --Check whether the notepad directory exists otherwise create it
    if vim.fn.isdirectory(Module.opts.notepad_dir) == 0 then
        --Create the directory and any parent directories necessary
        vim.fn.mkdir(Module.opts.notepad_dir, "p")
    end

    vim.notify(Module.opts.files.notepad, vim.log.levels.INFO);

    --Load files from disk into opts.files 
    Files.load_notes(Module.opts)

end

return Module
