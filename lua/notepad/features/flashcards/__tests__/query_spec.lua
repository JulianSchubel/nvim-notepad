describe("due_today query", function()
    local query = require("notepad.features.flashcards.query")
    local store = require("notepad.features.flashcards.store")
    store.load()
    local note = store.resolve("/test.md")
    note.fsrs = {
        due = 1,
        stability = 2.5,
        difficulty = 5.0,
    }
    store.save()

    local with_time = require("notepad.features.flashcards.__tests__.helpers.with_time").with_time
    local test_vault = "/home/js/projects/nvim-notepad/luau/notepad/notepad_test_vault";
    it("returns a table", function()
        with_time(1700000000, function()
            local cards = query.due_today(test_vault)
            assert.is_table(cards)
        end)
    end)
    it("returns overdue cards", function()
        with_time(1700000000, function()
            local cards = query.due_today(test_vault)
            assert(#cards >= 1)
        end)
    end)
end)
