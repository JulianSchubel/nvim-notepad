local Module = {}

function Module.toggle()
    local line = vim.api.nvim_get_current_line()

    if line:match("%- %[ %]") then
        line = line:gsub("%- %[ %]", "- [x]", 1)
    elseif line:match("%- %[x%]") then
        line = line:gsub("%- %[x%]", "- [ ]", 1)
    else
        return
    end

    vim.api.nvim_set_current_line(line)
end

function Module.archive(opts)
    if not opts.archive.enabled then return end

    local buf = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

    local remaining, archived = {}, {}

    for _, line in ipairs(lines) do
        if line:match("%- %[x%]") then
            table.insert(archived, line)
        else
            table.insert(remaining, line)
        end
    end

    if #archived == 0 then return end

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, remaining)
    vim.fn.writefile(archived, opts.archive.file, "a")
end

return Module
