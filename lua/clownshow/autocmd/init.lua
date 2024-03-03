local Object = require("clownshow.object")
local Config = require("clownshow.config")

---@class ClownshowAutocmd
---@field _group number
---@field _bufnr number
---@overload fun(bufnr: number): ClownshowAutocmd
local Autocmd = Object("ClownshowAutocmd")

---@param bufnr number
function Autocmd:init(bufnr)
  self._group = Config.group()
  self._bufnr = bufnr
end

function Autocmd:create(event, callback)
  vim.api.nvim_create_autocmd(event, {
    group = self._group,
    buffer = self._bufnr,
    callback = callback
  })
end

function Autocmd:reset()
  vim.api.nvim_clear_autocmds({
    group = self._group,
    buffer = self._bufnr
  })
end

return Autocmd
