local daily_picker = require("notepad.features.flashcards.ui.telescope.daily_picker")
local config = require("notepad.config")

local M = {}

-- ---------------------------------
-- Open the flashcard interface
-- ---------------------------------
-- The UI entry point for the flashcards feature.
function M.run()
    daily_picker.open({
        vault_path = config.opts.flashcards.vault_path,
    })
end

return M
