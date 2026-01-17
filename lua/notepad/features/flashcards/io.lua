-- notepad/features/flashcards/io.lua

local metadata  = require("notepad.features.flashcards.metadata")
local utilities = require("notepad.utilities")

local M         = {}

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
-- Directory scanning
-- -------------------------
local function scan_dir(dir, results)
    results = results or {}

    local handle = vim.uv.fs_scandir(dir)
    if not handle then return results end

    while true do
        local name, type = vim.uv.fs_scandir_next(handle)
        if not name then break end

        local path = dir .. "/" .. name

        if type == "file" and name:sub(-3) == ".md" then
            local lines = vim.fn.readfile(path)
            local hash  = utilities.hash(lines)
            if hash then
                local note, status = metadata.resolve(path, hash)
                table.insert(results, {
                    path   = path,
                    lines  = lines,
                    hash   = hash,
                    note   = note,
                    status = status, -- optional but useful
                })
            end
        elseif type == "directory" then
            scan_dir(path, results)
        end
    end

    return results
end


-- -------------------------
-- Public scan entrypoint
-- -------------------------
function M.scan_markdown(vault_path)
    vault_path = get_vault_path(vault_path)
    if type(vault_path) ~= "string" then
        return {}
    end

    metadata.deserialize()

    local results = scan_dir(vault_path, {})

    metadata.serialize()

    return results
end

return M
