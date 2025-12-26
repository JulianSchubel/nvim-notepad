--[[
Toggle is a comparison, not a state.

Recall:
    file is an identity
    buffer is an instance

Compare:
    what is open vs what is requested

Only then decide:
    close
    reuse
    create
--]]
local Module = {
    window = nil,
    filepath = nil,
}

local function open_float(buf, opts)
    if Module.window and vim.api.nvim_win_is_valid(Module.window) then
        vim.api.nvim_set_current_win(Module.window)
        return
    end

    local width = math.floor(vim.o.columns * opts.width_ratio)
    local height = math.floor(vim.o.lines * opts.height_ratio)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    Module.window = vim.api.nvim_open_win(buf, true, {
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

    vim.wo[Module.window].wrap = true
    vim.wo[Module.window].linebreak = true

    -- Clear state if window is closed
    vim.api.nvim_create_autocmd("WinClosed", {
        once = true,
        callback = function()
            Module.window = nil
            Module.filepath = nil
        end
    })
end

local function open_right_split(buf, opts)
    vim.cmd("botright vsplit")
    vim.cmd("vertical resize " .. opts.split_width)

    Module.window = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(Module.window, buf)

    vim.api.nvim_create_autocmd("WinClosed", {
        once = true,
        callback = function()
            Module.window = nil
            Module.filepath = nil
        end
    })
end

function Module.open(buf, path, opts)
    -- Window already exists
    if Module.window and vim.api.nvim_win_is_valid(Module.window) then
        -- Same file then don't do anything
        if Module.filepath == path then
            return
        end

        -- Different file then reuse same window
        Module.window = vim.api.nvim_win_set_buf(Module.window, buf)
        vim.api.nvim_set_current_win(Module.window)

        -- Update the referenced filepath
        Module.filepath = path
        return
    end

    -- No window currently exists
    Module.filepath = path

    -- Determine which window to use based on the configured layout
    if opts.layout == "right" then
        return open_right_split(buf, opts)
    else
        return open_float(buf, opts)
    end
end

function Module.close()
    --Only close a window if one is open and it is valid
    if Module.window and vim.api.nvim_win_is_valid(Module.window) then
        vim.api.nvim_win_close(Module.window, true)
    end
--    Module.window = nil
--    Module.filepath = nil
end

return Module
