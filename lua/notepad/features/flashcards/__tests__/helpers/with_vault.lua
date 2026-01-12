local uv = vim.loop

local M = {}

local function mkdir(path)
    uv.fs_mkdir(path, 448) -- 0700
end

local function write_file(path, content)
    vim.fn.writefile(
        vim.split(content, "\n", { plain = true }),
        path
    )
end

local function rm_rf(path)
    -- Best-effort recursive delete (tests only)
    vim.fn.delete(path, "rf")
end

function M.with_vault(files, fn)
    assert(type(files) == "table", "files must be a table")
    assert(type(fn) == "function", "fn must be a function")

    local root = vim.fn.tempname()
    mkdir(root)

    for rel, content in pairs(files) do
        write_file(root .. "/" .. rel, content)
    end

    local ok, err = pcall(fn, root)

    rm_rf(root)

    if not ok then
        error(err)
    end
end

return M
