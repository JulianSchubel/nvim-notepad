local clamp = require("notepad.utilities.clamp");

-- Lua implementation of the official FSRS (Free Spaced Repitition Scheduler) algorithm
local M = {}

-- Ratings (reference)
M.RATING = {
    AGAIN = 1,
    HARD  = 2,
    GOOD  = 3,
    EASY  = 4,
}

-- Default weights
M.DEFAULT_W = {
    0.4, 0.6, 2.4, 5.8, 4.93,
    0.94, 0.86, 0.01, 1.49,
    0.14, 0.94, 2.18, 0.05
}

-- Forgetting curve: r = e^(-t / s)
local function forgetting_curve(elapsed_days, stability)
    return math.exp(-elapsed_days / stability)
end

-- Initial stability based on first rating
function M.init_stability(rating)
    if rating == 1 then return 0.1 end
    if rating == 2 then return 1.0 end
    if rating == 3 then return 3.0 end
    return 5.0
end

-- Initial difficulty (reference default)
function M.init_difficulty()
    return 5.0
end

-- Core FSRS state transition
function M.next_state(state, rating, elapsed_days, w)
    w = w or M.DEFAULT_W

    local s = state.stability
    local d = state.difficulty

    local r = forgetting_curve(elapsed_days, s)

    -- Difficulty update
    d = clamp(
        d + w[6] * (rating - 3),
        1, 10
    )

    -- Stability update
    if rating < 3 then
        -- Failed recall
        s = w[1] * math.pow(s, w[2])
    else
        -- Successful recall
        s = s * (
            1
            + math.exp(w[3])
            * (11 - d)
            * math.pow(s, -w[4])
            * (math.exp((1 - r) * w[5]) - 1)
        )
    end

    return {
        stability = s,
        difficulty = d,
    }
end

-- Interval is floor(stability) days
function M.next_interval_days(stability)
    return math.max(1, math.floor(stability))
end

function M.review(state, rating, now)
    assert(type(state) == "table", "state required")
    assert(type(rating) == "number", "rating required")

    now = now or os.time()

    local last = state.last_review or now
    local elapsed_days = math.max(0, (now - last) / 86400)

    local base_state = {
        stability = state.stability or 1.0,
        difficulty = state.difficulty or 5.0,
    }

    -- Compute next stability + difficulty
    local next_sd = M.next_state(
        base_state,
        rating,
        elapsed_days,
        M.DEFAULT_W
    )

    -- Compute interval
    local interval_days = M.next_interval_days(next_sd.stability)

    return {
        stability = next_sd.stability,
        difficulty = next_sd.difficulty,
        last_review = now,
        due = now + interval_days * 86400,
    }
end

return M
