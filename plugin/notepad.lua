local notepad = require("notepad")
vim.keymap.set("n", "<leader>nx", notepad.toggle)
vim.keymap.set("n", "<leader>na", notepad.archive)
vim.keymap.set(
    "n",
    "<leader>nn",
    "<cmd>Notepad<cr>",
    { desc = "Open Neovim Notepad" }
)

