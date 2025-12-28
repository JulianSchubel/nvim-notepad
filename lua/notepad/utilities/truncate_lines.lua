local Module = {}

--Truncate line where length > max_width
--Works with Unicode
function Module.truncate_line(line, max_width)
    local width = 0
    local idx = 0

    while true do
        local char = vim.fn.strcharpart(line, idx, 1)
        if char == "" then break end
        local w = vim.fn.strdisplaywidth(char)
        if width + w > max_width then break end
        width = width + w
        idx = idx + 1
    end

    return vim.fn.strcharpart(line, 0, idx)
end

--Helper function to truncate all lines in a table where length > max_width
function Module.truncate_lines(lines, max_width)
    local out = {}
    for _, line in ipairs(lines) do
        table.insert(out, Module.truncate_line(line, max_width))
    end
    return out
end

return Module
