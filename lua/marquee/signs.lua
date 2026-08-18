local M = {}

---@class MarqueeSignConfig
---@field sign_group string
---@field sign_priority integer
---@field enabled boolean

---@type MarqueeSignConfig?
local cfg = nil
local sign_cache = {}
local signs_by_buffer = {}
local setup_required_msg = 'marquee.setup() must run before marquee.signs is used'

local function normalize_mark(mark)
  if type(mark) ~= 'string' or mark == '' then return nil end
  return mark:sub(-1)
end

local function is_primary_mark(mark)
  local normalized = normalize_mark(mark)
  return normalized ~= nil and normalized:match '^[a-zA-Z]$' ~= nil
end

local function define_sign(mark)
  local name = 'MarqueeSign' .. mark
  if sign_cache[name] then return end

  sign_cache[name] = true
  vim.fn.sign_define(name, {
    text = mark,
    texthl = 'MarkSignHL',
    numhl = 'MarkSignNumHL',
  })
end

local function signs_enabled_for(bufnr)
  local config = assert(cfg, 'marquee.setup() must run before marquee.signs is used')
  local enabled = signs_by_buffer[bufnr]
  if enabled == nil then return config.enabled end
  return enabled
end

local function collect_sign_marks()
  -- `refresh_buffer()` places signs one buffer at a time, so collect marks in
  -- that same shape up front.
  local marks_by_buf = {}
  -- The global and per-buffer mark lists can overlap, so keep a small dedupe
  -- table while merging them.
  local seen = {}

  local function add_mark(mark_data)
    local mark = normalize_mark(mark_data.mark)
    local pos = mark_data.pos
    -- Only letter marks become signs here. `pos[2]` is the 1-based line number;
    -- `0` means there is no line to place a sign on.
    if not mark or not is_primary_mark(mark) or not pos or pos[2] == 0 then return end

    local bufnr = pos[1]
    -- Keep only marks for buffers that are currently loaded, which matches what
    -- `refresh_buffer()` can draw into.
    if not bufnr or bufnr <= 0 or not vim.api.nvim_buf_is_loaded(bufnr) then return end

    -- Signs are line-based, so dedupe by buffer, line, and displayed mark.
    local key = table.concat({ bufnr, pos[2], mark }, ':')
    if seen[key] then return end

    seen[key] = true
    marks_by_buf[bufnr] = marks_by_buf[bufnr] or {}
    table.insert(marks_by_buf[bufnr], {
      -- `sign_place()` expects a numeric id for each placed sign.
      id = bufnr * 1000 + string.byte(mark),
      -- `lnum` passed to `sign_place()` is 1-based, which matches `pos[2]`.
      line = pos[2],
      -- Keep the mark text because it becomes both the displayed sign text and
      -- part of the defined sign name.
      mark = mark,
    })
  end

  -- Start with the global mark list.
  for _, mark_data in ipairs(vim.fn.getmarklist()) do
    add_mark(mark_data)
  end

  -- Then merge in each buffer's local mark list.
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      for _, mark_data in ipairs(vim.fn.getmarklist(bufnr)) do
        add_mark(mark_data)
      end
    end
  end

  return marks_by_buf
end

function M.refresh()
  local marks_by_buf = collect_sign_marks()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    M.refresh_buffer(bufnr, marks_by_buf)
  end
end

function M.refresh_buffer(bufnr, marks_by_buf)
  local config = assert(cfg, setup_required_msg)

  if not vim.api.nvim_buf_is_loaded(bufnr) then return end

  vim.fn.sign_unplace(config.sign_group, { buffer = bufnr })
  if not signs_enabled_for(bufnr) then return end

  local buffer_marks = marks_by_buf or collect_sign_marks()
  for _, sign in ipairs(buffer_marks[bufnr] or {}) do
    define_sign(sign.mark)
    vim.fn.sign_place(sign.id, config.sign_group, 'MarqueeSign' .. sign.mark, bufnr, {
      lnum = sign.line,
      priority = config.sign_priority,
    })
  end
end

function M.toggle(opts)
  local config = assert(cfg, setup_required_msg)
  opts = opts or {}
  local bufnr = opts.args ~= nil and opts.args ~= '' and tonumber(opts.args) or nil

  if bufnr then
    signs_by_buffer[bufnr] = not signs_enabled_for(bufnr)
    M.refresh_buffer(bufnr)
    return
  end

  config.enabled = not config.enabled
  signs_by_buffer = {}
  M.refresh()
end

---@param opts MarqueeSignConfig
function M.setup(opts)
  cfg = opts
  signs_by_buffer = {}
  vim.api.nvim_set_hl(0, 'MarkSignHL', { default = true, link = 'DiagnosticHint' })
  vim.api.nvim_set_hl(0, 'MarkSignNumHL', { default = true, link = 'MarkSignHL' })
end

return M
