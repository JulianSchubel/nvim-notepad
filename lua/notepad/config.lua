local Module = {}

Module.defaults = {
    layout = "right",
    width_ratio = 0.7,
    height_ratio = 0.7,
    split_width = 40,
    border = "rounded",
    files = {
        notepad = vim.fn.stdpath("data") .. "/notepad/notepad.md",
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
        file = vim.fn.stdpath("data") .. "/notepad/archive.md",
    },
}

function Module.setup(opts)
    Module.opts = vim.tbl_deep_extend("force", Module.defaults, opts or {})
end

return Module
