local M = {}

local signs = require 'marquee.signs'
local marks = require 'marquee.marks'

local defaults = {
  sign_group = 'marquee-signs',
  sign_priority = 10,
  signs = true,
  keymaps = true,
  which_key = true,
  mappings = {
    set = 'm',
    delete = 'dm',
    telescope = '<leader>mm',
    clear_all = 'dM',
    toggle_signs = '<leader>ms',
    refresh = '<leader>mr',
  },
  display = {
    telescope = 'primary',
    which_key = 'primary',
  },
}
M.config = nil

M.refresh_signs = signs.refresh
M.toggle_signs = signs.toggle
M.list_marks = marks.list_marks
M.clear = marks.clear_all
M.clear_buffer = marks.clear_buffer
M.delete = marks.delete
M.delete_line = marks.delete_line
M.set = marks.set

local function create_command(name, rhs, opts)
  if vim.fn.exists(':' .. name) == 2 then return end
  vim.api.nvim_create_user_command(name, rhs, opts)
end

local function map(lhs, rhs, desc)
  if not lhs or lhs == '' then return end
  vim.keymap.set('n', lhs, rhs, { desc = desc, noremap = true, silent = true })
end

local function setup_commands()
  local picker = require 'marquee.picker'
  create_command('MarqueeRefresh', M.refresh_signs, { desc = 'Refresh mark signs' })
  create_command('MarqueeToggleSigns', M.toggle_signs, {
    desc = 'Toggle mark signs globally or for a buffer',
    nargs = '?',
  })
  create_command('MarqueeTelescope', picker.open, { desc = 'Marquee Telescope marks' })
  create_command('MarqueeClear', M.clear, { desc = 'Clear primary marks a-z and A-Z' })
  create_command('MarqueeClearBuffer', M.clear_buffer, { desc = 'Clear primary marks in the current buffer' })
  create_command('MarqueeDelete', M.delete, {
    desc = 'Delete a primary mark by name',
    nargs = '?',
  })
  create_command('MarqueeDeleteLine', M.delete_line, { desc = 'Delete primary marks on the current line' })
end

local function setup_keymaps()
  if not M.config.keymaps then return end

  local mappings = M.config.mappings
  local picker = require 'marquee.picker'

  map(mappings.set, M.set, 'Marquee set mark')
  map(mappings.delete, M.delete, 'Marquee delete mark')
  map(mappings.delete .. '-', M.delete_line, 'Marquee delete marks on current line')
  map(mappings.delete .. ' ', M.delete_line, 'Marquee delete marks on current line')
  map(mappings.telescope, picker.open, 'Marquee Telescope marks')
  map(mappings.clear_all, M.clear, 'Marquee clear all marks')
  map(mappings.toggle_signs, '<cmd>MarqueeToggleSigns<CR>', 'Marquee toggle signs')
  map(mappings.refresh, '<cmd>MarqueeRefresh<CR>', 'Marquee refresh signs')
end

local function setup_autocmds()
  vim.api.nvim_create_autocmd('BufEnter', {
    group = vim.api.nvim_create_augroup('marquee-refresh', { clear = true }),
    callback = function(event) signs.refresh_buffer(event.buf) end,
  })
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', vim.deepcopy(defaults), opts or {})

  signs.setup {
    enabled = M.config.signs,
    sign_group = M.config.sign_group,
    sign_priority = M.config.sign_priority,
  }
  setup_commands()
  setup_keymaps()
  require('marquee.which_key').setup(M.config)
  setup_autocmds()

  vim.schedule(signs.refresh)
end

return M
