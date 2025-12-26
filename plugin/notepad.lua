vim.api.nvim_create_user_command("Notepad", function()
    require("notepad.telescope").open(require("notepad.config").opts)
end, {})

vim.keymap.set("n", "<leader>nn", "<cmd>Notepad<cr>", { desc = "Open Notepad" })
