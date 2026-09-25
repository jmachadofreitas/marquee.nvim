local M = {}

function M.clamp(value, min, max) return math.max(min, math.min(max, value)) end

function M.round(value) return math.floor(value + 0.5) end

return M
