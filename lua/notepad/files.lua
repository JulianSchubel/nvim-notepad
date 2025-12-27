-- Provides file utility functions and helpers
local Module = {}

-- Determines if the file path provided is valid, if not, create direcotries and the file as necessary
function Module.resolve(name, opts)
    -- Check if name exists as a pre-configured file
    local entry = opts.files[name] or name or nil;

    -- Support lazy / dynamic paths: If the entry is a function; call it,
    -- otherwise use it directly:
    --  ∙ Allows paths to depend on data/time, current project, cwd, etc.
    local path = type(entry) == "function" and entry() or entry
    -- Extract the absolute path to the parent directory (head) of the file path
    local dir = vim.fn.fnamemodify(path, ":h");

    -- Check if the directory exists, if not, create the file directory
    -- ∙ NB: Neovim will fail to write files if the parent directory does not
    -- exist.
    if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir, "p");
    end

    -- Check if the file exists, if not, create the file
    -- ∙ Auto-create files so users never see "file not found" errors
    if vim.fn.filereadable(path) then
        vim.fn.writefile({ "# New Note  ", "" }, path)
    end

    -- Returns a file path that is guaranteed to be valid
    return path
end

--  Ensure a file is loaded into Neovim's buffer list and return its buffer
--  number
function Module.load_file_buffer(path)
    -- Check if a buffer baced by the path already exists
    local buf = vim.fn.bufnr(path, false)

    -- If the buffer is not in the buffer list
    if buf == -1 then
        -- Add the file to Neovim's buffer list
        buf = vim.fn.bufadd(path)
        -- Load the file contents into the buffer; triggers normal buffer lifecycle events
        vim.fn.bufload(buf)
    end

    return buf
end

--Load notes from the directory into the files table: restores state from disk.
--Does not overwrite user-defined configuration entries
function Module.load_notes(opts)
    opts.files = opts.files or {}
    --Iterates over files in the notes directory
    for entry, type_ in vim.fs.dir(opts.notepad_dir) do
        --Check if the type is a file
        if type_ == "file" then
            --Extract the logical name, enforcing naming rules
            local name = entry:match("^([A-Za-z0-9]+)%.md$")
            --If the name is valid and not in the files table (user-defined
            --configuration entries) then construct the
            --file path and add it to the files table
            if name and not opts.files[name] then
                opts.files[name] = function()
                    return opts.notepad_dir .. "/" .. entry
                end
            end
        end
    end
end

--Check if the argument provided is valid notename. That is, a non-empty string that consists only of alphanumeric
--characters, numbers, hyphens, and underscores
function Module.is_valid_notename(name)
    return type(name) == "string"
        and name ~= ""
        and name:match("^[A-Za-z0-9-_]+$") ~= nil
end

--Reads the file located at path returning its contents or `nil` if a file handle
--fails to be acquired.
function Module.read_file(path)
    --Acquire a file handle
    local f = io.open(path, "r")
    --If no file handle return nil
    if not f then return nil end
    --Read the whole file
    local data = f:read("*a");
    --Close file handle
    f:close()
    --Return file content
    return data
end

--Writes data to the file located at path 
function Module.write_file(path, data)
    --Acquire a file handle
    local f = io.open(path, "w")
    --If no file handle return nil
    if not f then return nil end
    --Write data into the file
    f:write(data)
    f:close()
end

return Module
