describe("Metadata Store", function()
    it("can be required without error", function()
        require("notepad.features.flashcards.metadata_store")
        assert.is_true(true)
    end)

    it("can load/save metadata", function()
        local store = require("notepad.features.flashcards.metadata_store")
        store.deserialize()

        local a = store.resolve("notes/a.md")
        local b = store.resolve("notes/a.md")

        assert(a.id == b.id)

        store.record_rename("notes/a.md", "notes/b.md")

        local c = store.resolve("notes/b.md")
        assert(c.id == a.id)

        store.serialize()
    end)
end)
