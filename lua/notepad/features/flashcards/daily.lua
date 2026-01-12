local due_today = require("notepad.features.flashcards.ui.telescope.due_today")
local config = require("notepad.config")

local M = {}

function M.run()
    due_today.open({
        vault_path = config.opts.flashcards.vault_path,
    })
end

return M
