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
---@param pattern string|nil pattern to filter events
---@param callback fun(args: vim.api.keyset.create_autocmd.callback_args): boolean? callback for processing autocmd
function Autocmd:create(event, pattern, callback)
  vim.api.nvim_create_autocmd(event, {
    group = Config.group,
    pattern = pattern,
    buffer = (not pattern and self._bufnr) or nil,
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
