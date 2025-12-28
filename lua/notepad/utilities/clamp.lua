--Clamps a value in the interval `[min, max]`
local function clamp(value, min, max)
    return math.min(max, math.max(min, value));
end

return clamp
