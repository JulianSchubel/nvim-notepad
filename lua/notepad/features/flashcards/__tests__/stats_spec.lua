describe("stats computation", function()
    local compute = require("notepad.features.flashcards.stats.compute")

    it("counts total reviews", function()
        assert.equals(3, compute.total({
            { ts = os.time() },
            { ts = os.time() },
            { ts = os.time() },
        }))
    end)
end)
