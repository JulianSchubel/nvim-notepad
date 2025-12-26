vim.api.nvim_create_user_command("Notepad", function(opts)
    require("notepad").open(opts.args ~= "" and opts.args or nil)
end, { nargs = "?" })

vim.api.nvim_create_user_command("NotepadToggle", function()
  require("notepad").open()
end, { desc = "Toggle Notepad" })

vim.api.nvim_create_user_command("NotepadPick", function()
    require("notepad.telescope").open(require("notepad.config").opts)
end, {})

--vim.keymap.set("n", "<leader>nn", require("notepad").toggle, { desc = "Open Notepad" })
vim.keymap.set("n", "<leader>nn", "<cmd>Notepad<cr>", { desc = "Open Notepad" })
vim.keymap.set("n", "<leader>nt", "<cmd>NotepadToggle<cr>", { desc = "Toggle Notepad" })
vim.keymap.set("n", "<leader>na", require("notepad").archive, { desc = "Archive Notepad" })
