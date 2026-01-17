-- Metadata store for flashcard notes
--
-- Identity rules:
-- 1. hash not seen before           -> new note
-- 2. hash seen + same path          -> unchanged
-- 3. hash seen + different path     -> rename / move detected

local uuid = require("notepad.utilities.uuid")

local M = {}

M._state = nil

local function now()
    return os.time()
end

local function empty_state(root)
    return {
        version = 2,
        dir = { root = root },
        paths = {},  -- path -> id
        hashes = {}, -- hash -> id
        notes = {},  -- id -> record
    }
end

-- -----------------------------------
-- Deserialize
-- -----------------------------------
function M.deserialize()
    local FLASHCARD_ROOT =
        vim.fn.stdpath("data")
        .. require("notepad.config").opts.notepad_dir
        .. "/.flashcards"

    local STORE = FLASHCARD_ROOT .. "/flashcards.json"

    if vim.fn.filereadable(STORE) == 0 then
        M._state = empty_state(FLASHCARD_ROOT)
        return M._state
    end

    local text = table.concat(vim.fn.readfile(STORE), "\n")
    M._state = vim.fn.json_decode(text)

    -- Backwards compatibility (v1)
    M._state.paths  = M._state.paths  or {}
    M._state.hashes = M._state.hashes or {}
    M._state.notes  = M._state.notes  or {}

    for _, note in pairs(M._state.notes) do
        note.history = note.history or {}
    end
    return M._state
end

-- -----------------------------------
-- Serialize
-- -----------------------------------
function M.serialize()
    assert(M._state, "Metadata store not loaded")

    local FLASHCARD_ROOT =
        vim.fn.stdpath("data")
        .. require("notepad.config").opts.notepad_dir
        .. "/.flashcards"

    vim.fn.mkdir(FLASHCARD_ROOT, "p")

    local path    = FLASHCARD_ROOT .. "/flashcards.json"
    local tmp     = path .. ".tmp"

    local encoded = vim.fn.json_encode(M._state)
    vim.fn.writefile(vim.split(encoded, "\n"), tmp)
    vim.fn.rename(tmp, path)
end

-- ----------------------------------------
-- Identity resolution
-- ----------------------------------------
-- Resolve or create a note record
-- @param path  string  file path
-- @param hash  string  content hash
-- @returns note, status ("new" | "unchanged" | "renamed")
function M.resolve(path, hash)
    assert(M._state, "Metadata store not loaded")

    if not path or path == "" then
        error("metadata.resolve called with nil/empty path")
    end

    if not hash then
        error("metadata.resolve called with nil hash for path: " .. path)
    end

    local paths  = M._state.paths
    local hashes = M._state.hashes
    local notes  = M._state.notes

    -- Known hash → same logical note
    local id     = hashes[hash]
    if id then
        local note = notes[id]
        assert(note, "corrupt metadata: hash mapped to missing note")

        -- Normalize legacy notes
        note.history = note.history or {}
        note.path    = note.path or path
        note.hash    = hash

        if note.path == path then
            return note, "unchanged"
        end

        -- Rename / move detected
        note.history = note.history or {}
        note.history[tostring(now())] = {
            from = note.path,
            to   = path,
        }

        paths[note.path] = nil
        paths[path] = id
        note.path = path

        return note, "renamed"
    end

    -- New note
    id           = uuid.v4()

    local note   = {
        id      = id,
        path    = path,
        hash    = hash,
        created = now(),
        history = {},
    }

    notes[id]    = note
    paths[path]  = id
    hashes[hash] = id

    return note, "new"
end

-- ----------------------------------------
-- Explicit rename (optional external use)
-- ----------------------------------------
function M.record_rename(old_path, new_path)
    assert(M._state, "Metadata store not loaded")

    local id = M._state.paths[old_path]
    if not id then return nil end

    local note = M._state.notes[id]

    note.history[tostring(now())] = {
        from = old_path,
        to   = new_path,
    }

    note.path = new_path
    M._state.paths[old_path] = nil
    M._state.paths[new_path] = id

    return note
end

-- ----------------------------------------
-- Update card metadata (FSRS, etc.)
-- ----------------------------------------
-- @param id       string  note id
-- @param metadata table  card metadata (e.g. { fsrs = ... })
function M.update_card(id, metadata)
    assert(M._state, "Metadata store not loaded")
    assert(id, "metadata.update_card called without id")
    assert(type(metadata) == "table", "metadata.update_card expects metadata table")

    local note = M._state.notes[id]
    if not note then
        error("metadata.update_card: unknown note id " .. tostring(id))
    end

    -- Attach metadata fields directly to note
    for k, v in pairs(metadata) do
        note[k] = v
    end

    return note
end


return M
