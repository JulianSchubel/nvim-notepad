local Module = {}

local function load_file_buffer(path)
  -- Check if buffer already exists
  local buf = vim.fn.bufnr(path, false)

  if buf == -1 then
    buf = vim.fn.bufadd(path)
    vim.fn.bufload(buf)
  end

  return buf
end

function Module.open(path, opts)
    --If duplicate windows is not enabled in the configuration reuse the
    --existing window
    if ~opts.duplicate_windows then
        if Module.win and vim.api.nvim_win_is_valid(Module.win) then
            vim.api.nvim_set_current_win(Module.win)
            return
        end
        local buf = load_file_buffer(path)
    end

    vim.cmd("edit " .. vim.fn.fnameescape(path))
    local buf = vim.api.nvim_get_current_buf()

    local width = math.floor(vim.o.columns * opts.width_ratio)
    local height = math.floor(vim.o.lines * opts.height_ratio)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    Module.win = vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      row = row,
      col = col,
      width = width,
      height = height,
      style = "minimal",
      border = opts.border,
    })

    vim.bo[buf].filetype = "markdown"
    vim.bo[buf].bufhidden = "hide"
    vim.bo[buf].modifiable = true

    vim.wo[Module.win].wrap = true
    vim.wo[Module.win].linebreak = true
end

return Module
