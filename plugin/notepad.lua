vim.api.nvim_create_user_command("NotepadOpen", function()
  require("notepad").open()
end, { desc = "Open Notepad" })

vim.api.nvim_create_user_command("NotepadPick", function()
    require("notepad.telescope").open(require("notepad.config").opts)
end, {})

vim.keymap.set("n", "<leader>nt", "<cmd>NotepadOpen<cr>", { desc = "Open Notepad" })
vim.keymap.set("n", "<leader>nn", require("notepad").toggle, { desc = "Open Notepad" })
vim.keymap.set("n", "<leader>na", require("notepad").archive, { desc = "Archive Notepad" })
