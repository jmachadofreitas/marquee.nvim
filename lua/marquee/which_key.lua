local M = {}

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
  if not config.which_key then return end

  local ok, which_key = pcall(require, 'which-key')
  if not ok then return end

  local delete_mapping = config.mappings and config.mappings.delete or 'dm'
  local clear_all_mapping = config.mappings and config.mappings.clear_all or 'dM'
  local spec = {
    { '<leader>m', group = '[M]arks' },
    { delete_mapping, group = 'Delete Marks' },
    { delete_mapping, desc = 'Delete mark {a-zA-Z}' },
    { delete_mapping .. '-', desc = 'Delete marks on current line' },
    { delete_mapping .. ' ', desc = 'Delete marks on current line' },
    { clear_all_mapping, desc = 'Delete all primary marks' },
  }

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
    table.insert(spec, 2, { "<space>'", function() show_default_marks "'" end, desc = 'All marks' })
    table.insert(spec, 3, { '<space>`', function() show_default_marks '`' end, desc = 'All marks' })
  else
    use_default_marks()
  end

  which_key.add(spec)
end

return M
