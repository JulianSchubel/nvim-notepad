-- [[
-- This module handles file resolution and creation
-- ]]

local Module = {}

function Module.resolve(name, opts)
    local entry = opts.files[name] or name;

    local path = type(entry) == "function" and entry() or entry
    local dir = vim.fn.fnamemodify(path, ":h");

    -- Create the file directory if it doesnt exist
    if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir, "p");
    end

    if vim.fn.filereadable(path) == 0 then
        vim.fn.writefile({ "# New Note  ", ""}, path)
    end

    return path
end

function Module.load_file_buffer(path)
  -- Check if buffer already exists
  local buf = vim.fn.bufnr(path, false)

  if buf == -1 then
    buf = vim.fn.bufadd(path)
    vim.fn.bufload(buf)
  end

  return buf
end

return Module
