local Object = require("clownshow.object")

---@class ClownshowUsercmd
---@field _bufnr number
---@field usercmds string[]
---@overload fun(bufnr: number): ClownshowUsercmd
local Usercmd = Object("ClownshowUsercmd")

---@param bufnr number buffer to apply usercmds to
function Usercmd:init(bufnr)
  self._bufnr = bufnr
  self.usercmds = {}
end

-- creates a usercmd for the buffer
---@param name string[]|string name(s) of the command
---@param callback fun(bufnr?: number): nil callback for the command
---@param opts? vim.api.keyset.user_command command options
function Usercmd:create(name, callback, opts)
  if type(name) == "string" then name = { name } end
  for _, n in ipairs(name) do
    vim.api.nvim_buf_create_user_command(self._bufnr, n, function()
      callback(self._bufnr)
    end, opts or {})
    table.insert(self.usercmds, n)
  end
end

-- resets the usercmds for the buffer
function Usercmd:reset()
  for _, name in pairs(self.usercmds) do
    vim.api.nvim_buf_del_user_command(self._bufnr, name)
  end
  self.usercmds = {}
end

return Usercmd
