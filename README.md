# Nvim-Notepad

A lightweight, file-backed notepad for Neovim.

Nvim-notepad opens Markdown files in a floating or split window, allowing you to
read and write notes safely while keeping your editing context intact. It
supports single or multiple notepad files, daily notes, Telescope picking, and
Lazy.nvim out of the box.

![](assets/nvim-notepad.png)

## Features  

- Persistent notes stored on disk
- Picker-based note selection
- Native Neovim highlight groups (no custom colors required)
- No background services or external dependencies
- Supporting commands to add new note items and remove completed note items.

## Keymaps

- `<leader>nn`: Open the note picker.
- `<leader>ni`: Add a new note item.
- `<leader>nx`: Toggle a note item as complete / incomplete.
- `<leader>nr`: Remove completed note items.

### Delete a note

In the note picker:

- Press `d` to delete the selected note
- Confirm with `y`
- Cancel with `n` or `<Esc>`

Deleted notes are removed from disk immediately.

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
