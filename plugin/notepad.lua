vim.api.nvim_create_user_command("Notepad", function(opts)
    require("notepad").open(opts.args ~= "" and opts.args or nil)
end, { nargs = "?" })

vim.api.nvim_create_user_command("NotepadPick", function()
    require("notepad.telescope").open(require("notepad.config").opts)
end, {})

vim.keymap.set("n", "<leader>nt", require("notepad").toggle, { desc = "Toggle Notepad" })
vim.keymap.set("n", "<leader>na", require("notepad").archive, { desc = "Archive Notepad" })
