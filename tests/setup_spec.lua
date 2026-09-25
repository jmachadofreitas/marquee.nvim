vim.opt.rtp:prepend(vim.fn.getcwd())

local function check(condition, message)
  if not condition then error(message, 2) end
end

-- Stand in for which-key so its integration is tested without the plugin.
local wk_spec = {}
local wk_v3 = { add = function(spec) wk_spec = spec end, show = function() end }
package.loaded['which-key'] = wk_v3
package.loaded['which-key.plugins.marks'] = { expand = function() return {} end }

local warnings = {}
vim.notify = function(message) table.insert(warnings, message) end

local marquee = require 'marquee'
local which_key = require 'marquee.which_key'

local function mapped(lhs) return vim.fn.maparg(lhs, 'n') ~= '' end

local function labelled(lhs)
  for _, entry in ipairs(wk_spec) do
    if entry[1] == lhs then return true end
  end
  return false
end

marquee.setup { keymaps = false }
check(not mapped 'dm' and not mapped 'm', 'keymaps = false must not create mappings')
check(#wk_spec == 0, 'keymaps = false must not register which-key entries')

marquee.setup { mappings = { delete = false, clear_buffer = '' } }
check(not mapped 'dm' and mapped 'dM', 'a mapping set to false must be the only one skipped')
check(not labelled 'dm' and not labelled 'dm|' and not labelled '-', 'disabled mappings must not get which-key labels')
check(labelled 'dM', 'enabled mappings must keep their which-key labels')

package.loaded['which-key'] = { register = function() end }
marquee.setup()
check(not which_key.active, 'which-key without the v3 spec API must be skipped')
package.loaded['which-key'] = wk_v3

marquee.setup { display = { telescope = 'All' } }
check(#warnings == 1 and marquee.config.display.telescope == 'primary', 'an invalid display value must warn and fall back')
check(which_key.active and labelled 'dm' and labelled "<space>'", 'the default setup must register which-key entries')
check(type(require('marquee.health').check) == 'function', 'the health check must load')

local function buffer(name, lines)
  if name then
    vim.cmd.edit(name)
  else
    vim.cmd.enew()
  end
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  return vim.api.nvim_get_current_buf()
end

local function mark(name, line)
  vim.api.nvim_win_set_cursor(0, { line, 0 })
  vim.cmd('normal! m' .. name)
end

local function has_mark(name) return vim.api.nvim_buf_get_mark(0, name)[1] ~= 0 end

local first = buffer(vim.fn.tempname(), { 'one', 'two', 'three' })
mark('a', 1)
mark('B', 2)
marquee.refresh()
check(#vim.fn.sign_getplaced(first, { group = 'marquee-signs' })[1].signs == 2, 'every primary mark must get a sign')

buffer(vim.fn.tempname(), { 'one', 'two', 'three' })
mark('c', 2)
marquee.delete_line()
check(not has_mark 'c', 'delete_line must delete the marks on the current line')
check(vim.api.nvim_get_mark('B', {})[1] == 2, 'delete_line must keep a global mark on the same line of another file')

-- `dm` is a prefix of `dm|`, so `|` reaches the delete mapping after 'timeoutlen'.
mark('d', 1)
vim.fn.getcharstr = function() return '|' end
vim.fn.maparg('dm', 'n', false, true).callback()
check(not has_mark 'd', 'the clear_buffer key must also work through the delete mapping')

buffer(nil, { 'one', 'two' })
mark('e', 2)
check(#marquee.list_marks 'primary' > 0 and marquee.list_marks('primary')[1].mark == 'e', 'marks in an unnamed buffer must be listed')
marquee.delete_line()
check(not has_mark 'e', 'delete_line must work in an unnamed buffer')
