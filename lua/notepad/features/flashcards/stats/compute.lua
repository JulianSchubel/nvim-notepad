local M = {}

function M.today(events)
    local today = os.date("%Y-%m-%d")
    local count = 0

    for _, e in ipairs(events) do
        if os.date("%Y-%m-%d", e.ts) == today then
            count = count + 1
        end
    end

    return count
end

function M.total(events)
    return #events
end

function M.streak(events)
    local days = {}

    for _, e in ipairs(events) do
        local d = os.date("%Y-%m-%d", e.ts)
        days[d] = true
    end

    local streak = 0
    for i = 0, 365 do
        local d = os.date("%Y-%m-%d", os.time() - i * 86400)
        if days[d] then
            streak = streak + 1
        else
            break
        end
    end

    return streak
end

return M
