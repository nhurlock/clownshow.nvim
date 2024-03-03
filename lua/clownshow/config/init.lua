local _opts = require("clownshow.config.defaults")

local _source = "clownshow"
local _ns = vim.api.nvim_create_namespace(_source)
local _group = vim.api.nvim_create_augroup(_source, { clear = true })
local _jest_args = { "--watch", "--silent", "--forceExit", "--json", "--testLocationInResults", "--no-colors",
  "--coverage=false" }

local function validate_status_options(status)
  vim.validate({
    is_table = { status, "table" },
    icon = { status.icon, "string" },
    text = { status.text, "string" },
    hl_group = { status.hl_group, "string" },
  })
  return true
end

---@param opts table
local function validate_options(opts)
  vim.validate({
    mode = { opts.mode, function(mode) return mode == "inline" or mode == "above" end, "'above' or 'inline'" },
    jest_command = { opts.jest_command, { "function" } },
    project_root = { opts.project_root, { "function" } },
    show_icon = { opts.show_icon, "boolean" },
    show_text = { opts.show_text, "boolean" },
    passed = { opts.passed, validate_status_options },
    failed = { opts.failed, validate_status_options },
    skipped = { opts.skipped, validate_status_options },
    loading = { opts.loading, validate_status_options }
  })
  return opts
end

local M = {}

function M.get()
  return _opts
end

---@param opts ClownshowOptions?
function M.update(opts)
  if opts then
    _opts = validate_options(vim.tbl_deep_extend("force", _opts, opts))
  end
  return M.get()
end

function M.source()
  return _source
end

function M.ns()
  return _ns
end

function M.group()
  return _group
end

---@return string[]
function M.get_jest_args()
  return _jest_args
end

return M
