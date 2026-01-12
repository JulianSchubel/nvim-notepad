local M = {}

M.DEFAULT = {
    stability = 0,
    difficulty = 5,
    reps = 0,
    lapses = 0,
    state = "new",
    history = {},
}

function M.ensure(meta)
    meta.nvim_notepad = meta.nvim_notepad or {}
    meta.nvim_notepad.fsrs = vim.tbl_deep_extend(
        "force",
        M.DEFAULT,
        meta.nvim_notepad.fsrs or {}
    )
    return meta
end

return M
