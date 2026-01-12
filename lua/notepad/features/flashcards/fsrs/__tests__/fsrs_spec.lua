local fsrs = require("notepad.flashcards.fsrs")

describe("FSRS reference compliance", function()
    it("initial stability is correct", function()
        assert.equals(0.1, fsrs.init_stability(1))
        assert.equals(1.0, fsrs.init_stability(2))
        assert.equals(3.0, fsrs.init_stability(3))
        assert.equals(5.0, fsrs.init_stability(4))
    end)

    it("produces deterministic next state", function()
        local state = { stability = 3.0, difficulty = 5.0 }
        local next = fsrs.next_state(state, fsrs.RATING.GOOD, 3)

        assert.is_number(next.stability)
        assert.is_number(next.difficulty)
        assert.is_true(next.stability > state.stability)
    end)

    it("interval derives from stability", function()
        assert.equals(3, fsrs.next_interval_days(3.8))
        assert.equals(1, fsrs.next_interval_days(0.2))
    end)
end)

describe("FSRS regression", function()
    it("produces deterministic output", function()
        local now = 1700000000

        local state = {
            stability = 0,
            difficulty = 5,
            reps = 0,
            lapses = 0,
            elapsed_days = 0,
            scheduled_days = 0,
            last_review = nil,
            due = nil,
        }

        local next = fsrs.review(state, 3, now)

        assert.is_number(next.stability)
        assert.is_number(next.difficulty)
        assert.is_true(next.due > now)
    end)

    it("increases stability on good review", function()
        local now = os.time()

        local state = {
            stability = 3,
            difficulty = 5,
            reps = 3,
            lapses = 0,
            elapsed_days = 3,
            scheduled_days = 3,
            last_review = now - 86400 * 3,
            due = now,
        }

        local next = fsrs.review(state, 4, now)
        assert.is_true(next.stability > state.stability)
    end)

    it("resets stability on lapse", function()
        local now = os.time()

        local state = {
            stability = 10,
            difficulty = 4,
            reps = 10,
            lapses = 0,
            elapsed_days = 10,
            scheduled_days = 10,
            last_review = now - 86400 * 10,
            due = now,
        }

        local next = fsrs.review(state, 1, now)
        assert.is_true(next.lapses == 1)
        assert.is_true(next.stability < state.stability)
    end)
end)
