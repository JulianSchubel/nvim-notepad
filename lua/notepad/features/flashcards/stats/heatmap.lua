local M = {}

function M.build(events)
    local map = {}

    for _, e in ipairs(events) do
        local day = os.date("%Y-%m-%d", e.ts)
        map[day] = (map[day] or 0) + 1
    end

    return map
end

return M
