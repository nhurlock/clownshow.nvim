local Object = require("clownshow.object")
local Config = require("clownshow.config")
local mark_utils = require("clownshow.marks.utils")

---@class ClownshowMarks
---@field _ns number
---@field _bufnr number
---@overload fun(bufnr: number): ClownshowMarks
local Marks = Object("ClownshowMarks")

---@param bufnr number
function Marks:init(bufnr)
  self._ns = Config.ns()
  self._bufnr = bufnr
end

---@param identifier ClownshowIdentifier
---@param partials ClownshowMarkPartial[]
function Marks:_from(identifier, partials)
  -- when there is nothing to render, make sure we don't have an old mark
  if #partials == 0 then
    if identifier.mark ~= nil then
      vim.api.nvim_buf_del_extmark(self._bufnr, self._ns, identifier.mark)
      identifier.mark = nil
    end
    return
  end

  local config = Config.get()
  local line, col, _ = identifier:get_pos()
  ---@type vim.api.keyset.set_extmark
  local extmark_opts = {
    id = identifier.mark,
    invalidate = true,
    undo_restore = false,
    priority = 100
  }

  -- "above" will be placed "inline" on line 0 otherwise it would be hidden
  if config.mode == "above" and line ~= 0 then
    -- in an "each" (tables) the line/col is not guaranteed to be the highest point for the test
    -- use "above" location instead
    local above = identifier.above
    if above then
      line = above.line
      col = above.col
    end

    -- apply offset padding to align virt_line with code
    partials[1][1] = string.rep(" ", col) .. partials[1][1]

    extmark_opts.virt_lines = { partials }
    extmark_opts.virt_lines_above = true
  else
    extmark_opts.virt_text = partials
  end

  identifier.mark = vim.api.nvim_buf_set_extmark(self._bufnr, self._ns, line, col, extmark_opts)
end

---@param identifier ClownshowIdentifier
---@param status? ClownshowIdentifierStatus
---@param force? boolean
function Marks:status(identifier, status, force)
  self:_from(identifier, { mark_utils.status_mark(identifier, status, force) })
end

---@param identifier ClownshowIdentifier
function Marks:stats(identifier)
  local partials = vim.tbl_map(function(status)
    return mark_utils.status_mark(identifier, status)
  end, { "passed", "failed", "pending" })
  self:_from(identifier, vim.tbl_filter(function(p) return p ~= nil end, partials))
end

function Marks:reset()
  vim.api.nvim_buf_clear_namespace(self._bufnr, self._ns, 0, -1)
end

return Marks
