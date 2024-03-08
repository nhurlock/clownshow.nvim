local config_utils = require("clownshow.config.utils")

local M = {}

M.opts = require("clownshow.config.defaults")

M.source = "clownshow"

M.ns = vim.api.nvim_create_namespace(M.source)

M.group = vim.api.nvim_create_augroup(M.source, { clear = true })

M.jest_args = table.concat({
  "--json",                 -- required for parsing jest results
  "--watch",                -- update on changes
  "--testLocationInResults" -- required for parsing jest results
}, " ")

---@param opts ClownshowOptions? options to apply, overwriting existing config
---@return ClownshowOptions opts applied options
function M.update(opts)
  if opts and config_utils.validate_options(vim.tbl_deep_extend("force", vim.deepcopy(M.opts), opts)) then
    M.opts = vim.tbl_deep_extend("force", M.opts, opts)
  end
  return M.opts
end

return M
