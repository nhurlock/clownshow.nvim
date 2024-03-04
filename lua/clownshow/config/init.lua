local _opts = require("clownshow.config.defaults")
local config_utils = require("clownshow.config.utils")

local M = {}

M.source = "clownshow"

M.ns = vim.api.nvim_create_namespace(M.source)

M.group = vim.api.nvim_create_augroup(M.source, { clear = true })

M.jest_args = table.concat({
  "--watch",
  "--silent",
  "--forceExit",
  "--json",
  "--testLocationInResults",
  "--no-colors",
  "--coverage=false"
}, " ")

function M.get()
  return _opts
end

---@param opts ClownshowOptions?
function M.update(opts)
  if opts then
    _opts = config_utils.validate_options(vim.tbl_deep_extend("force", _opts, opts))
  end
  return M.get()
end

return M
