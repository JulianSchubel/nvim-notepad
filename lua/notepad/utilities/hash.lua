local function hash(lines)
    if not lines or #lines == 0 then
        return nil
    end

    local text = table.concat(lines, "\n")
    if text == "" then
        return nil
    end

    return vim.fn.sha256(text)
end

return hash
