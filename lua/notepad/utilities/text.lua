local Module = {}
--Wrap a line if line length > max_width
--Works with Unicode.
function Module.wrap_line(line, max_width)
    local out = {}
    local rest = line

    --strdisplaywidth() matches what neovim actually renders
    while vim.fn.strdisplaywidth(rest) > max_width do
        local width = 0
        local idx = 0

        while true do
            --Splits by characters, not bytes; does not break graphemes.
            local ch = vim.fn.strcharpart(rest, idx, 1)
            if ch == "" then break end
            local w = vim.fn.strdisplaywidth(ch)
            if width + w > max_width then break end
            width = width + w
            idx = idx + 1
        end

        table.insert(out, vim.fn.strcharpart(rest, 0, idx))
        rest = vim.fn.strcharpart(rest, idx)
    end

    table.insert(out, rest)
    return out
end

--Helper function to wrap all lines in a table where length > max_width
function Module.wrap_lines(lines, max_width)
    local out = {}
    for _, line in ipairs(lines) do
        vim.list_extend(out, Module.wrap_line(line, max_width))
    end
    return out
end

return Module
