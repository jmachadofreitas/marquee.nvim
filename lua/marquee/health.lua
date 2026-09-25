local M = {}

local health = vim.health
local start = health.start or health.report_start
local ok = health.ok or health.report_ok
local warn = health.warn or health.report_warn
local info = health.info or health.report_info
local fail = health.error or health.report_error

function M.check()
  start 'marquee'

  if vim.fn.has 'nvim-0.9' == 1 then
    ok 'Neovim >= 0.9'
  else
    fail 'marquee requires Neovim >= 0.9'
  end

  local config = require('marquee').config
  if config then
    ok 'setup() has been called'
  else
    warn('setup() has not been called', { "Add `require('marquee').setup()` to your config" })
  end

  if pcall(require, 'telescope') then
    ok 'telescope.nvim found'
  else
    info 'telescope.nvim not found: the picker falls back to `:marks`'
  end

  if require('marquee.which_key').active then
    ok 'which-key.nvim integration is active'
  elseif config and not config.which_key then
    info 'which-key integration is turned off (`which_key = false`)'
  elseif config and pcall(require, 'which-key') then
    warn('which-key.nvim found, but its integration is not active', {
      'Make which-key.nvim (v3 or newer) available before `require("marquee").setup()` runs',
    })
  else
    info 'which-key.nvim not found: which-key integration is disabled'
  end
end

return M
