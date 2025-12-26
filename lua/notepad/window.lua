local Module = {}

function Module.open(path, opts)
    vim.cmd("edit " .. vim.fn.fnameescape(path))
    local buf = vim.api.nvim_get_current_buf()

    local width = math.floor(vim.o.columns * opts.width_ratio)
    local height = math.floor(vim.o.lines * opts.height_ratio)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local win = vim.api.nvim_open_win(buf, true, {
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

    vim.wo[win].wrap = true
    vim.wo[win].linebreak = true
end

return Module
