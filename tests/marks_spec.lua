vim.opt.rtp:prepend(vim.fn.getcwd())

local marks = require 'marquee.marks'

local function assert_same(expected, actual, message)
  if not vim.deep_equal(expected, actual) then error(('%s\nexpected: %s\nactual: %s'):format(message, vim.inspect(expected), vim.inspect(actual))) end
end

local targets = marks._buffer_clear_targets {
  { mark = "'a" },
  { mark = "'z" },
  { mark = "'A" },
  { mark = "'Z" },
  { mark = "'[" },
  { mark = "'." },
  { mark = "'`" },
}

assert_same({ 'a', 'z' }, targets, 'buffer clear must select only local primary marks')

assert_same({}, marks._buffer_clear_targets {}, 'buffer clear must accept an empty mark list')
