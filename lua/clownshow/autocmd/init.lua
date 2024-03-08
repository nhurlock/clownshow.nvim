local Object = require("clownshow.object")
local Config = require("clownshow.config")

---@class ClownshowAutocmd
---@field _bufnr number
---@overload fun(bufnr: number): ClownshowAutocmd
local Autocmd = Object("ClownshowAutocmd")

---@param bufnr number buffer to apply autocmds to
function Autocmd:init(bufnr)
  self._bufnr = bufnr
end

-- creates an autocmd for the buffer
---@param event string[]|string events for autocmd
---@param callback fun(): nil callback for processing autocmd
function Autocmd:create(event, callback)
  vim.api.nvim_create_autocmd(event, {
    group = Config.group,
    buffer = self._bufnr,
    callback = callback
  })
end

-- resets the autocmds for the buffer
function Autocmd:reset()
  vim.api.nvim_clear_autocmds({
    group = Config.group,
    buffer = self._bufnr
  })
end

return Autocmd
