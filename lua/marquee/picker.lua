local M = {}

function M.open(opts)
  local ok, pickers = pcall(require, 'telescope.pickers')
  if not ok then
    vim.notify('marquee could not find telescope.nvim, falling back to :marks', vim.log.levels.WARN)
    vim.cmd 'marks'
    return
  end

  local conf = require('telescope.config').values
  local finders = require 'telescope.finders'
  local make_entry = require 'telescope.make_entry'
  local marquee = require 'marquee'

  opts = opts or {}
  opts.bufnr = opts.bufnr or vim.api.nvim_get_current_buf()

  local scope = marquee.config.display.telescope or 'all'
  local items = {}
  local others = {}

  for _, item in ipairs(marquee.list_marks(scope, { bufnr = opts.bufnr })) do
    local name = item.source == 'global' and item.file_display or item.line
    local row = {
      line = string.format('%s %6d %4d %s', item.mark, item.lnum, item.col - 1, name),
      lnum = item.lnum,
      col = item.col,
      filename = item.filename,
    }

    if item.mark:match '%w' then
      table.insert(items, row)
    else
      table.insert(others, row)
    end
  end

  vim.list_extend(items, others)

  pickers
    .new(opts, {
      prompt_title = scope == 'primary' and 'User Marks' or 'Marks',
      finder = finders.new_table {
        results = items,
        entry_maker = opts.entry_maker or make_entry.gen_from_marks(opts),
      },
      previewer = conf.grep_previewer(opts),
      sorter = conf.generic_sorter(opts),
      push_cursor_on_edit = true,
      push_tagstack_on_edit = true,
    })
    :find()
end

return M
