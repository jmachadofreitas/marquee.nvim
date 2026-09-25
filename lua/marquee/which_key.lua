local M = {}

-- Whether setup() enabled the integration; read by the health check.
M.active = false

local default_marks_expand = nil

local function mark_items(scope)
  local marquee = require 'marquee'
  local labels = require('marquee.marks').labels
  local items = {}

  for _, item in ipairs(marquee.list_marks(scope)) do
    table.insert(items, {
      key = item.mark,
      desc = labels[item.mark] or (item.file_display ~= '' and ('file: ' .. item.file_display) or ''),
      value = vim.trim(item.line ~= '' and item.line or item.file_display),
      highlights = { { 1, 5, 'Number' } },
      lnum = item.lnum,
    })
  end

  if vim.tbl_isempty(items) and scope == 'primary' then return {
    { key = '<ESC>', desc = 'No primary marks set' },
  } end

  return items
end

function M.setup(config)
  M.active = false
  if not config.which_key then return end

  local ok, which_key = pcall(require, 'which-key')
  -- The spec API used below needs which-key v3.
  if not ok or type(which_key.add) ~= 'function' then return end
  M.active = true

  -- Only label mappings that exist: `keymaps = false` disables all of them, and
  -- a single mapping is disabled with `false` or `''`.
  local mappings = config.keymaps and config.mappings or {}
  local function enabled(lhs) return type(lhs) == 'string' and lhs ~= '' end
  local spec = {}
  if config.keymaps then table.insert(spec, { '<leader>m', group = '[M]arks' }) end
  if enabled(mappings.delete) then
    vim.list_extend(spec, {
      { mappings.delete, group = 'Delete Marks' },
      { mappings.delete, desc = 'Delete mark {a-zA-Z}' },
      { mappings.delete .. '-', desc = 'Delete marks on current line' },
      { mappings.delete .. ' ', desc = 'Delete marks on current line' },
    })
  end
  if enabled(mappings.clear_buffer) then table.insert(spec, { mappings.clear_buffer, desc = 'Delete marks in current buffer' }) end
  if enabled(mappings.clear_all) then table.insert(spec, { mappings.clear_all, desc = 'Delete all primary marks' }) end

  local ok_marks, marks_plugin = pcall(require, 'which-key.plugins.marks')
  if not ok_marks then
    which_key.add(spec)
    return
  end

  default_marks_expand = default_marks_expand or marks_plugin.expand

  local function use_primary_marks()
    -- Override which-key's marks plugin so `'` and `` ` `` show only primary
    -- marks when Marquee is configured for that scope.
    rawset(marks_plugin, 'expand', function() return mark_items 'primary' end)
  end

  local function use_default_marks() rawset(marks_plugin, 'expand', default_marks_expand) end

  local function show_default_marks(keys)
    -- Temporarily restore the original marks expander for the <Space> shortcuts.
    use_default_marks()
    local show_ok, err = pcall(which_key.show, { keys = keys, mode = 'n' })
    if config.display.which_key == 'primary' then use_primary_marks() end
    if not show_ok then error(err, 0) end
  end

  if config.display.which_key == 'primary' then
    use_primary_marks()
    if config.keymaps then
      table.insert(spec, { "<space>'", function() show_default_marks "'" end, desc = 'All marks' })
      table.insert(spec, { '<space>`', function() show_default_marks '`' end, desc = 'All marks' })
    end
  else
    use_default_marks()
  end

  which_key.add(spec)
end

return M
