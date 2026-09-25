local M = {}

function M.greet(name) return ('Hello, %s!'):format(name) end

function M.sum(list)
  local total = 0
  for _, value in ipairs(list) do
    total = total + value
  end
  return total
end

function M.reverse(list)
  local out = {}
  for i = #list, 1, -1 do
    out[#out + 1] = list[i]
  end
  return out
end

return M
