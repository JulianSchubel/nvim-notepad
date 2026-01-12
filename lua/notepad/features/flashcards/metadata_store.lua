--[[ 
The store module is responsible for: 
- Deserialize / serializing metadata to the store (flashcards.toml).
- Resolving a note by path to a stable ID.
- Tracking renames.
- Storing per-note metadata (opaque to callers).

Essentially it manages the persistence of state and stable IDs for notes.
--]]

local uuid = require("notepad.utilities.uuid")

local M = {}

M._state = nil

local function now()
  return os.time()
end

local function empty_state(path)
    return {
        version = 1,
        dir = { root = path },
        paths = {}, -- map from path to id
        notes = {}, -- map from id to record
    }
end


-- -----------------------------------
-- Deserialize
-- -----------------------------------
-- Deserializes the flashcards metadata store
function M.deserialize()
    local FLASHCARD_ROOT = vim.fn.stdpath("data") .. require("notepad.config").opts.notepad_dir .. "/.flashcards";
    local FLASHCARD_STORE = "/flashcards.json"
    local path = FLASHCARD_ROOT .. FLASHCARD_STORE

    -- If the file is not readable (does not exist) set the state to the empty
    -- state
    if vim.fn.filereadable(path) == 0 then
        M._state = empty_state(path)
        return M._state
    end

    -- Read the metadata file contents
    local lines = vim.fn.readfile(path)
    -- Concatenate file content newline delimited
    local text = table.concat(lines, "\n")
    -- Deserialize the file content
    local decoded = vim.fn.json_decode(text)
    M._state = decoded
    return M._state
end

-- -----------------------------------
-- Serialize
-- -----------------------------------
-- Serializes metadata to the flashcards metadata store store
function M.serialize()
    -- Make sure there is some state to serialize
    assert(M._state, "Metadata store not loaded");
    local FLASHCARD_ROOT = vim.fn.stdpath("data") .. require("notepad.config").opts.notepad_dir .. "/.flashcards";
    local FLASHCARD_STORE = "/flashcards.json"

    local dir = FLASHCARD_ROOT;
    -- Create the directory path; does nothing if the directory path exists
    vim.fn.mkdir(dir, "p")

    local path = FLASHCARD_ROOT .. FLASHCARD_STORE;
    local tmp_path = path .. ".tmp"

    local encoded = vim.fn.json_encode(M._state);
    -- Atomic writes
    vim.fn.writefile(vim.split(encoded, "\n"), tmp_path)
    vim.fn.rename(tmp_path, path)
end

-- ----------------------------------------
-- Identity resolution
-- ----------------------------------------
-- Resolve a path to a stable ID
function M.resolve(path)
    assert(M._state, "Metadata store not loaded")

    local paths = M._state.paths;
    local notes = M._state.notes;

    -- Check if a known paths
    local id = paths[path]
    if id then
        return notes[id]
    end

    -- New note
    id = uuid.v4();

    paths[path] = id;
    notes[id] = {
        id = id,
        path = path,
        created = now(),
        history = {},
    }

    return notes[id]
end

-- ----------------------------------------
-- Rename tracking
-- ----------------------------------------
function M.record_rename(old_path, new_path)
    assert(M._state, "Metadata store not loaded")

    local id = M._state.paths[old_path]
    if not id then return nil
    end

    local note = M._state.notes[id];
    note.history[tostring(now())] = old_path;
    note.path = new_path;

    M._state.paths[new_path] = id;
    M._state.paths[old_path] = nil;

    return note;
end

return M;
