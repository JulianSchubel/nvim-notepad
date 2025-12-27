# Nvim-Notepad

A lightweight, file-backed notepad for Neovim.

Nvim-notepad opens Markdown files in a floating or split window, allowing you to read and write notes safely while keeping your editing context intact. It supports single or multiple notepad files, daily notes, Telescope picking, and Lazy.nvim out of the box.

This plugin is currently under development.

## Installation (Lazy.nvim)

```lua
return {
    "JulianSchubel/nvim-notepad",
    cmd = { "Notepad" },
    keys = { "<leader>nn", "<cmd>Notepad<cr>", desc = "Open Neovim Notepad" },
    config = function()
        require("notepad").setup({
            layout = "right",
            width_ratio = 0.8,
            height_ratio = 0.8,
            split_width = 40,
            border = "rounded",
        })
    end
}
```
