-- lua/notepad/features/flashcards/__tests__/helpers/vault.lua
local M = {}

local uv = vim.loop

local function mkdir(path)
  uv.fs_mkdir(path, 448) -- 0700
end

local function write(path, content)
  vim.fn.writefile(vim.split(content, "\n", { plain = true }), path)
end

function M.create(files)
  local root = vim.fn.tempname()
  mkdir(root)

  for rel, content in pairs(files) do
    local full = root .. "/" .. rel
    write(full, content)
  end

  return root
end

return M

