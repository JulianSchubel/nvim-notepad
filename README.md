# Nvim-Notepad

A lightweight, file-backed notepad for Neovim.

Nvim-notepad opens Markdown files in a floating or split window, allowing you to
read and write notes safely while keeping your editing context intact. It
supports single or multiple notepad files, daily notes, Telescope picking, and
Lazy.nvim out of the box. 

Spaced repitition flashcards are available as an optional feature.

![](assets/nvim-notepad.png)

## Features  

- Persistent notes stored on disk
- Picker-based note selection
- No background services or external dependencies
- Supporting commands to add new note items and remove completed note items.
- Spaced repetition flashcards. Supports three definitions of a flashcard:
  1. Inline
  2. Multiline
  3. Obsidian-style callout

## Keymaps

- `<leader>nn`: Open the note picker.

### Notepad Buffer Commands

Within a note buffer:
- `<leader>ni`: Add a new note item.
- `<leader>nx`: Toggle a note item as complete / incomplete.
- `<leader>nr`: Remove completed note items.

### Create a note

In the note picker:

- Press `<Esc>` to enter command mode.
- Press `c` to open the create note prompt.

In the create note prompt:

- Enter the desired notename.
- Cancel by pressing `<Esc>`.

### Create a daily note

In the note picker:
- Press `<Esc>` to enter command mode.
- Press `t` to create a daily note or open today's note if it exists.

### Delete a note

In the note picker:

- Press `<Esc>` to enter command mode.
- Press `d` to delete the selected note.
- Confirm with `y`.
- Cancel with `n` or `<Esc>`.

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

With flashcards enabled

```lua
return {
    "JulianSchubel/nvim-notepad",
    lazy = false,
    cmd = { "Notepad" },
    keys = { "<leader>nn", "<cmd>Notepad<cr>", desc = "Open Neovim Notepad" },
    config = function()
        require("notepad").setup({
            layout = "float",
            width_ratio = 0.8,
            height_ratio = 0.8,
            split_width = 40,
            border = "rounded",
            archive = {
                enabled = true
            },
            flashcards = {
                enabled = true,
                vault_path = vim.fn.expand(<path to obsidian vault or other compatible flashcard directory>)
            },
        });
    end
}

```
