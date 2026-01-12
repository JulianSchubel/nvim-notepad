local M = {}

-- Overrides os.time so that we can freeze time in place.
function M.with_time(ts, fn)
    local real_time = os.time
    os.time = function() return ts end
    local ok, err = pcall(fn)
    os.time = real_time
    if not ok then error(err) end
end

return M
