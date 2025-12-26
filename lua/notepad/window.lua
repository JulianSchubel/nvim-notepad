local Module = {
    win = Nil,
}

local function load_file_buffer(path)
  -- Check if buffer already exists
  local buf = vim.fn.bufnr(path, false)

  if buf == -1 then
    buf = vim.fn.bufadd(path)
    vim.fn.bufload(buf)
  end

  return buf
end

local function open_float(buf, opts)
    if Module.win and vim.api.nvim_win_is_valid(Module.win) then
        vim.api.nvim_set_current_win(Module.win)
        return
    end

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

local function open_right_split(buf, opts)
    -- Reuse split window
    if Module.win and vim.api.nvim_win_is_valid(Module.win) then
        vim.api.nvim_win_set_buf(Module.win, buf)
        vim.api.nvim_set_current_win(Module.win)
        return
    end

    -- Create split once
    vim.cmd("botright vsplit")
    vim.cmd("vertical resize " .. opts.split_width)

    Module.win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(Module.win, buf)

    -- Clear state if window is closed
    vim.api.nvim_create_autocmd("NotepadWindowClosed", {
        once = true,
        callback = function()
            Module.win = nil
        end,
    })
end

function Module.open(buf, opts)
    if opts.layout == "right" then
        return open_right_split(buf, opts)
    end

    return open_float(buf, opts)
end

return Module
