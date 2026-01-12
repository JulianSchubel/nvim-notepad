describe("review flow", function()
    it("updates FSRS state on rating", function()
        local review = require("notepad.features.flashcards.review")
        local card = {
            path = "/tmp/notepad-test-vault/",
            metadata = {
                stability = 2.5,
                difficulty = 5.0,
                due = os.time(),
            },
            content = "Q\n\nA",
        }

        local session = review.start(card)
        local next_state = review.apply_rating(session, 3)

        assert.is_number(next_state.stability)
        assert.is_number(next_state.difficulty)
        assert.is_true(next_state.due > os.time())
    end)
    it("initializes fsrs state when missing", function()
        local review = require("notepad.features.flashcards.review")

        local session = review.start({ metadata = {} })
        assert.is_number(session.fsrs.stability)
    end)
end)
