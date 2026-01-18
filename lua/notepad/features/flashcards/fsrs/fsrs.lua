local clamp = require("notepad.utilities.clamp");

-- | Variable     | Meaning                 |
-- | ------------ | ----------------------- |
-- | `stability`  | how long memory lasts   |
-- | `difficulty` | how hard card feels     |
-- | `r`          | predicted recall chance |
-- | `due`        | next scheduled review   |
-- | `rating`     | user feedback           |

-- Lua implementation of FSRS (Free Spaced Repitition Scheduler) algorithm
local M = {}

-- ----------
-- Ratings
-- ----------
-- Defines the four allowed recall outcomes. Meaning: 
-- - 1: complete failure
-- - 2: barely remembered
-- - 3: remembered with effort
-- - 4: very easy recall
--
M.RATING = {
    AGAIN = 1,
    HARD  = 2,
    GOOD  = 3,
    EASY  = 4,
}

-- ------------------
-- Default weights
-- ------------------
-- Trained parameters
-- Each value scales part of the learning curve.
--
M.DEFAULT_W = {
    0.4, 0.6, 2.4, 5.8, 4.93,
    0.94, 0.86, 0.01, 1.49,
    0.14, 0.94, 2.18, 0.05
}

-- ------------------------
-- Forgetting curve
-- ------------------------
-- Models memory decay. Defined as 
--      r = e^(-t / s)
-- where 
--      t = time since last review (days)
--      s = stability (how long the memory lasts)
--  and
--      r ∈ (0,1]
--
-- Meaning: 
-- - Higher stability = slower forgetting
-- - As `elapsed_days` increases, recall probability decreases
local function forgetting_curve(elapsed_days, stability)
    return math.exp(-elapsed_days / stability)
end

-- -------------------------------------------
-- Initial stability based on first rating
-- -------------------------------------------
-- Called when a card is reviewed for the first time
-- Maps recall quality to initial memory strength
--
--  | Rating | Stability |
--  | ------ | --------- |
--  | AGAIN  | 0.1       |
--  | HARD   | 1.0       |
--  | GOOD   | 3.0       |
--  | EASY   | 5.0       |
--
function M.init_stability(rating)
    if rating == 1 then return 0.1 end
    if rating == 2 then return 1.0 end
    if rating == 3 then return 3.0 end
    return 5.0
end

-- ---------------------
-- Initial difficulty
-- ---------------------
-- Difficulty starts neutral.
-- Difficulty affects **how fast stability grows**.
-- Range is always clamped to `[1, 10]`.
function M.init_difficulty()
    return 5.0
end

-- -----------------------------
-- Core state transition
-- -----------------------------
-- @param state table
--      state.stability - current stability
--      state.difficulty - current difficulty
-- @param rating number - stability rating
-- @param elapsed_days number - days since last review
-- @param w - weight factor 
function M.next_state(state, rating, elapsed_days, w)
    -- Unpack state
    w = w or M.DEFAULT_W

    -- Pull curernt stabilitity and difficulty into local variables to prevent
    -- mutating input directly
    local s = state.stability
    local d = state.difficulty

    -- Estimate how likely the user was to rememebr 
    -- Used to adjust stability growth
    -- If remembered late then bigger boost
    local r = forgetting_curve(elapsed_days, s)

    -- Difficulty update
    -- - Take (rating - 3):
    --      AGAIN:  -2
    --      HARD:   -1
    --      GOOD:   0
    --      EASY:   +1
    --      
    --  - w[6] scales sensitivity
    --  - Clamp keeps difficulty sane
    --
    --  Effect is:
    --      Forgetting = harder card
    --      Easy recall = easier card
    d = clamp(
        d + w[6] * (rating - 3),
        1, 10
    )

    -- Stability update
    if rating < 3 then
        -- Failed recall
        -- Penalizes stability after forgetting
        -- Stability collapses sharply
        -- Encourages quick relearning
        s = w[1] * math.pow(s, w[2])
    else
        -- Successful recall
        -- The FSRS growth formula
        -- Key factors:
        -- - (11 - d): easier cards grow faster
        -- - math.pow(s, -w[4]): diminishing returns
        -- - (1 - r): late recall boosts growth
        -- - exp(...) ensures non-linear growth
        -- 
        -- Result:
        -- - Correct recalls increase interval exponentially, but with diminishing returns over time
        --
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

-- -------------------------------------
-- Calculate Recall Interval in Days
-- -------------------------------------
-- Interval = floor(stability) in days
-- Always >= 1 day
--
function M.next_interval_days(stability)
    return math.max(1, math.floor(stability))
end

-- ---------------------
-- Review a Flashcard
-- ---------------------
-- Public API to FSRS implementation
function M.review(state, rating, now)
    -- Validate input
    assert(type(state) == "table", "state required")
    assert(type(rating) == "number", "rating required")

    -- Time handling
    now = now or os.time()

    -- Compute time since lasst review
    -- If first review, then elapsed_days = 0
    local last = state.last_review or now
    local elapsed_days = math.max(0, (now - last) / 86400)

    -- Fallback to a base state
    -- Ensures safe defaults
    -- Avoids nil math errors
    local base_state = {
        stability = state.stability or 1.0,
        difficulty = state.difficulty or 5.0,
    }

    -- Compute next stability and difficulty
    local next_sd = M.next_state(
        base_state,
        rating,
        elapsed_days,
        M.DEFAULT_W
    )

    -- Compute recall interval
    local interval_days = M.next_interval_days(next_sd.stability)

    -- Persist the updated state
    return {
        stability = next_sd.stability,
        difficulty = next_sd.difficulty,
        last_review = now,
        due = now + interval_days * 86400,
    }
end

return M
