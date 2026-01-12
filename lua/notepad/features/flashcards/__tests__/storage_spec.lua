describe("flashcard storage", function()
    local storage = require("notepad.features.flashcards.storage")

    it("returns a table", function()
        local files = storage.scan_markdown(vim.fn.getcwd())
        assert.is_table(files)
    end)
end)
