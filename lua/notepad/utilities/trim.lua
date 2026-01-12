local function trim(s)
    if type(s) == "string" then
        return s:match("^%s*(.-)%s*$")
    end
    return s;
end

return trim
