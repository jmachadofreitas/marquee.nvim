local M = {}
local signs = require 'marquee.signs'

M.labels = {
  ['^'] = 'Last position of cursor in insert mode',
  ['.'] = 'Last change in current buffer',
  ['"'] = 'Last exited current buffer',
  ['0'] = 'In last file edited',
  ["'"] = 'Back to line in current buffer where jumped from',
  ['`'] = 'Back to position in current buffer where jumped from',
  ['['] = 'To beginning of previously changed or yanked text',
  [']'] = 'To end of previously changed or yanked text',
  ['<lt>'] = 'To beginning of last visual selection',
  ['>'] = 'To end of last visual selection',
}

function M.normalize_mark(mark)
  if type(mark) ~= 'string' or mark == '' then return nil end
  return mark:sub(-1)
end

function M.is_primary_mark(mark)
  local normalized = M.normalize_mark(mark)
  return normalized ~= nil and normalized:match '^[a-zA-Z]$' ~= nil
end

function M.is_upper_mark(mark)
  local byte = mark:byte()
  return byte >= string.byte 'A' and byte <= string.byte 'Z'
end

local function include_mark(mark, scope)
  scope = scope or 'all'
  if scope == 'all' then return mark ~= nil end
  if scope == 'primary' then return M.is_primary_mark(mark) end
  return false
end

function M.list_marks(scope, opts)
  opts = opts or {}
  local bufnr = opts.bufnr or vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local items = {}
  local seen = {}

  local function add_mark(mark_data, source)
    local mark = M.normalize_mark(mark_data.mark)
    local pos = mark_data.pos
    if not mark or not include_mark(mark, scope) or not pos or pos[2] == 0 then return end

    local mark_bufnr, lnum, col = pos[1], pos[2], pos[3]
    local file = mark_data.file or ((mark_bufnr and mark_bufnr > 0) and vim.api.nvim_buf_get_name(mark_bufnr)) or bufname
    if not file or file == '' then return end

    local key = table.concat({ source, mark_bufnr or 0, lnum, mark, file }, ':')
    if seen[key] then return end
    seen[key] = true

    local line = ''
    -- `getmarklist()` can report unloaded buffers or marks from other files.
    -- Only read line content when the target buffer is available.
    if mark_bufnr and mark_bufnr > 0 and vim.api.nvim_buf_is_loaded(mark_bufnr) then
      line = vim.api.nvim_buf_get_lines(mark_bufnr, lnum - 1, lnum, false)[1] or ''
    end

    table.insert(items, {
      mark = mark,
      line = line,
      lnum = lnum,
      col = col,
      bufnr = mark_bufnr,
      filename = vim.fn.fnamemodify(file, ':p'),
      file_display = vim.fn.fnamemodify(file, ':p:~:.'),
      source = source,
      label = M.labels[mark] or '',
    })
  end

  for _, mark_data in ipairs(vim.fn.getmarklist(bufnr)) do
    add_mark(mark_data, 'local')
  end

  for _, mark_data in ipairs(vim.fn.getmarklist()) do
    add_mark(mark_data, 'global')
  end

  return items
end

function M.line_marks(bufnr, line)
  local items = {}

  for _, item in ipairs(M.list_marks('primary', { bufnr = bufnr })) do
    -- Blank lines still have valid marks, so only the line number matters here.
    if item.lnum == line then table.insert(items, item.mark) end
  end

  return items
end

function M.clear_buffer()
  vim.cmd 'delmarks!'
  signs.refresh_buffer(vim.api.nvim_get_current_buf())
end

function M.clear_all()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      for mark = string.byte 'a', string.byte 'z' do
        pcall(vim.api.nvim_buf_del_mark, bufnr, string.char(mark))
      end
    end
  end

  vim.cmd 'delmarks A-Z'
  signs.refresh()
end

function M.delete_line()
  local bufnr = vim.api.nvim_get_current_buf()
  local line_marks = M.line_marks(bufnr, vim.api.nvim_win_get_cursor(0)[1])
  if vim.tbl_isempty(line_marks) then return end

  local needs_full_refresh = false
  for _, mark in ipairs(line_marks) do
    -- Uppercase marks are global/file marks, so deleting them can affect signs
    -- outside the current buffer and requires a full refresh.
    if M.is_upper_mark(mark) then
      needs_full_refresh = true
      vim.cmd('delmarks ' .. mark)
    else
      pcall(vim.api.nvim_buf_del_mark, bufnr, mark)
    end
  end

  if needs_full_refresh then
    signs.refresh()
  else
    signs.refresh_buffer(bufnr)
  end
end

function M.delete_mark(mark)
  local normalized = M.normalize_mark(mark)
  if normalized == ' ' then
    M.delete_line()
    return
  end

  if normalized == '-' then
    M.delete_line()
    return
  end

  if not normalized or not M.is_primary_mark(normalized) then return end

  if M.is_upper_mark(normalized) then
    vim.cmd('delmarks ' .. normalized)
    signs.refresh()
    return
  end

  pcall(vim.api.nvim_buf_del_mark, vim.api.nvim_get_current_buf(), normalized)
  signs.refresh_buffer(vim.api.nvim_get_current_buf())
end

function M.delete(opts)
  opts = opts or {}
  if opts.args and opts.args ~= '' then
    M.delete_mark(opts.args)
    return
  end

  local ok, mark = pcall(vim.fn.getcharstr)
  if not ok or not mark or mark == '' then return end
  M.delete_mark(mark)
end

function M.set()
  local ok, mark = pcall(vim.fn.getcharstr)
  if not ok or not mark or mark == '' then return end

  vim.cmd.normal { args = { 'm' .. mark }, bang = true }
  if M.is_primary_mark(mark) then signs.refresh_buffer(vim.api.nvim_get_current_buf()) end
end

return M
