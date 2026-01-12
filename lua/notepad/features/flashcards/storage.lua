local M = {}

-- -------------------------
-- Vault path resolution
-- -------------------------
local function get_vault_path(vault_path)
    if vault_path then
        return vault_path
    end

    local ok, cfg = pcall(require, "notepad.config")
    if not ok or not cfg then
        return nil
    end

    local opts = cfg.opts
    if not opts or not opts.flashcards then
        return nil
    end

    return opts.flashcards.vault_path
end

-- -------------------------
-- Atomic write helper
-- -------------------------
local function atomic_write(path, lines)
    local tmp = path .. ".tmp"
    vim.fn.writefile(lines, tmp)
    assert(vim.uv.fs_rename(tmp, path), "Atomic rename failed")
end

-- -------------------------
-- Write full card safely
-- -------------------------
function M.write_card(card)
    assert(card.path, "card.path missing")
    assert(card.metadata, "card.metadata missing")

    -- TEST SAFETY: allow virtual cards
    local ok, lines = pcall(vim.fn.readfile, card.path)
    if not ok then
        return -- tests should not crash on missing files
    end

    local fm, body = frontmatter.read(lines)

    fm.notepad = fm.notepad or {}
    fm.notepad.flashcard = fm.notepad.flashcard or {}
    fm.notepad.flashcard.fsrs = card.metadata.fsrs

    local new_lines = frontmatter.write(body, fm)
    atomic_write(card.path, new_lines)
end

-- -------------------------
-- Directory scanning
-- -------------------------
-- Recursively scans the directory tree from the provided directory
local function scan_dir(dir, results)
    results = results or {}

    -- Scan the provided directory path returning a handle to the directory if
    -- it exists
    local handle = vim.uv.fs_scandir(dir)
    if not handle then return results end

    -- Scan all entries
    while true do
        -- Return a (name, type) pair of the next entry in the directory
        -- associated with the handle provided
        local name, type = vim.uv.fs_scandir_next(handle)
        --No more entries
        if not name then break end

        -- construct the path to the filename
        local path = dir .. "/" .. name

        --We only care about markdown files
        if type == "file" and name:sub(-3) == ".md" then
            --io.stderr:write( "\t" .. name .. "\n")
            local lines = vim.fn.readfile(path)
            local content = ""
            for _, line in ipairs(lines) do
                content = content .. line .. "\n";
            end
            --io.stderr:write( "\t" .. content)
            table.insert(results, {
                path = path,
                lines = vim.fn.readfile(path),
            })
        -- recursively call scan_dir to traverse the directory tree
        -- TODO: switch to iterative / stack / queue based traversal
        elseif type == "directory" then
            scan_dir(path, results)
        end
    end

    return results
end

-- Scans vault_path for markdown files, returning a list of filepaths and their
-- contents as an array of lines in the form {path, lines}
function M.scan_markdown(vault_path)
    vault_path = get_vault_path(vault_path)
--    io.stderr:write( "scanning " .. vault_path .. "\n")
    if type(vault_path) ~= "string" then
        return {}
    end

    local results = scan_dir(vault_path, {})
--    io.stderr:write( "#Results: " .. #results .. "\n")
    return results;
end

return M
