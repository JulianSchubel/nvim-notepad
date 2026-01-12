-- notepad/features/flashcards/schema.lua
local M = {}

local DEFAULT_FSRS = {
    stability = 1.0,
    difficulty = 5.0,
    due = os.time(),
    last_review = nil,
}

local function is_fsrs_state(v)
    return type(v) == "table"
        and type(v.stability) == "number"
        and type(v.difficulty) == "number"
end

function M.default_fsrs_state()
    return vim.deepcopy(DEFAULT_FSRS)
end

function M.ensure(fsrs)
    -- Nil or invalid → default
    if not is_fsrs_state(fsrs) then
        return M.default_fsrs_state()
    end

    -- Normalize missing optional fields
    fsrs.stability = fsrs.stability or DEFAULT_FSRS.stability
    fsrs.difficulty = fsrs.difficulty or DEFAULT_FSRS.difficulty
    fsrs.due = fsrs.due or DEFAULT_FSRS.due
    fsrs.last_review = fsrs.last_review

    return fsrs
end

return M

