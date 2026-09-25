-- Minimal config used to record the README demo with VHS.
-- Usage: nvim --clean -u assets/demo/init.lua assets/demo/sample.lua
local demo = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local root = vim.fn.fnamemodify(demo, ':h:h')

-- Optional integrations are cloned once into assets/demo/.deps (gitignored),
-- pinned to the commits the demo was recorded with.
local deps = {
  { 'nvim-lua/plenary.nvim', '74b06c6c75e4eeb3108ec01852001636d85a932b' },
  { 'nvim-telescope/telescope.nvim', '40aedd8a68c78a656a10a8d62d80c54af59420fb' },
  { 'folke/which-key.nvim', '3aab2147e74890957785941f0c1ad87d0a44c15a' },
}
local function git(...)
  local output = vim.fn.system { 'git', ... }
  if vim.v.shell_error ~= 0 then error('demo: git ' .. table.concat({ ... }, ' ') .. ' failed:\n' .. output, 0) end
end
for _, dep in ipairs(deps) do
  local path = demo .. '/.deps/' .. dep[1]:match '[^/]+$'
  if not (vim.uv or vim.loop).fs_stat(path) then
    local ok, err = pcall(function()
      git('clone', '--filter=blob:none', '--no-checkout', 'https://github.com/' .. dep[1], path)
      git('-C', path, 'checkout', '--quiet', dep[2])
    end)
    if not ok then
      -- Don't leave a half-cloned plugin behind for the next run to pick up.
      vim.fn.delete(path, 'rf')
      error(err, 0)
    end
  end
  vim.opt.rtp:prepend(path)
end
vim.opt.rtp:prepend(root)

vim.g.mapleader = ' '
vim.o.number = true
vim.o.signcolumn = 'yes:1'
vim.o.cursorline = true
vim.o.termguicolors = true
vim.o.showcmd = true
vim.o.swapfile = false
vim.o.shada = ''
vim.o.timeoutlen = 500
vim.cmd.colorscheme 'habamax'

-- Recording aids, shown in a bar at the top (the tabline): a caption on the
-- left, set from the tape with :Caption, and the keys typed since then on the
-- right.
local bar = { caption = '', keys = '', raw = '' }
local names = { ['<Space>'] = '␣', ['<CR>'] = '⏎', ['<Esc>'] = 'Esc ', ['<BS>'] = '⌫' }
vim.api.nvim_set_hl(0, 'DemoCaption', { fg = '#e4e4e4', bg = '#303030', bold = true })
vim.api.nvim_set_hl(0, 'DemoKeys', { fg = '#1e1e2e', bg = '#f5a97f', bold = true })
vim.o.showtabline = 2

local function render()
  local function escape(text) return (text:gsub('%%', '%%%%')) end
  local typed = bar.keys ~= '' and ('%#DemoKeys# ' .. escape(bar.keys) .. ' ') or ''
  vim.o.tabline = '%#DemoCaption# ' .. escape(bar.caption) .. '%=' .. typed
  vim.cmd.redrawtabline()
end
render()

vim.api.nvim_create_user_command('Caption', function(opts)
  bar.caption = opts.args
  bar.keys, bar.raw, bar.expect = '', '', nil
  render()
  -- Clear the typed command from the command line.
  vim.cmd.echo '""'
end, { nargs = '*' })

-- which-key replays the keys it intercepted about 10 ms later. A chunk that
-- repeats the keys just shown within this window counts as a replay, so the
-- tape's TypingSpeed has to stay above it.
local replay_ms = 30

vim.on_key(function(_, typed)
  -- Show what was typed (before mappings), without which-key's replays.
  if not typed or typed == '' then return end
  local key = typed
  local now = (vim.uv or vim.loop).hrtime() / 1e6
  local quick = now - (bar.any or 0) < replay_ms
  bar.any = now
  if quick then
    if bar.expect and bar.expect:sub(1, #key) == key then
      bar.expect = bar.expect:sub(#key + 1)
      return
    end
    for i = math.max(1, #bar.raw - 10), #bar.raw do
      local tail = bar.raw:sub(i)
      if tail:sub(1, #key) == key then
        bar.expect = tail:sub(#key + 1)
        return
      end
    end
  end
  bar.expect = nil
  bar.raw = (bar.raw .. key):sub(-16)
  local name = vim.fn.keytrans(key):gsub('<[^>]+>', names)
  -- Separate distinct actions with a space so the sequence stays readable.
  if bar.keys ~= '' and now - (bar.last or 0) > 350 then bar.keys = bar.keys .. ' ' end
  bar.last = now
  bar.keys = vim.fn.strcharpart(bar.keys .. name, math.max(0, vim.fn.strchars(bar.keys .. name) - 28))
  vim.schedule(render)
end, vim.api.nvim_create_namespace 'demo-keys')

require('telescope').setup {
  defaults = { layout_strategy = 'horizontal', layout_config = { height = 0.9, width = 0.95, preview_cutoff = 1 } },
}
require('which-key').setup { preset = 'helix', show_help = false, icons = { mappings = false } }
vim.api.nvim_set_hl(0, 'MarqueeSign', { fg = '#f5a97f', bold = true })
require('marquee').setup()
