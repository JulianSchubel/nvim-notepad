vim.api.nvim_create_user_command("Notepad", function(opts)
    require("notepad").open(opts.args ~= "" and opts.args or {})
end, { nargs = "?" })

vim.api.nvim_create_user_command("NotepadPick", function()
    require("notepad.telescope").open(require("notepad.config").opts)
end, {})

vim.keymap.set("n", "<leader>nn", "<cmd>Notepad<cr>", { desc = "Open Notepad" })
vim.keymap.set("n", "<leader>np", "<cmd>NotepadPick", { desc = "Open Notepad Picker" })
vim.keymap.set("n", "<leader>nn", require("notepad").toggle, { desc = "Open Notepad" })
vim.keymap.set("n", "<leader>na", require("notepad").archive, { desc = "Archive Notepad" })
