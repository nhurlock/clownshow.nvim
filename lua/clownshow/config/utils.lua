local M = {}

---@param status string status to validate
---@return fun(opts: any): boolean valid valid status
function M.validate_status_options(status)
  ---@param opts any options to validate
  ---@return boolean valid valid status
  return function(opts)
    vim.validate(status, opts, "table")
    vim.validate(status .. ".icon", opts.icon, "string")
    vim.validate(status .. ".text", opts.text, "string")
    vim.validate(status .. ".hl_group", opts.hl_group, "string")
    return true
  end
end

---@param opts table options to validate
---@return boolean valid valid options
function M.validate_options(opts)
  vim.validate("mode", opts.mode, function(mode) return mode == "inline" or mode == "above" end, "'above' or 'inline'")
  vim.validate("show_icon", opts.show_icon, "boolean")
  vim.validate("show_text", opts.show_text, "boolean")
  vim.validate("project_root", opts.project_root, "function")
  vim.validate("jest_command", opts.jest_command, "function")
  vim.validate("results_fn", opts.results_fn, { "function", "nil" })
  vim.validate("create_output_win", opts.create_output_win, "function")
  vim.validate("passed", opts.passed, M.validate_status_options("passed"))
  vim.validate("failed", opts.failed, M.validate_status_options("failed"))
  vim.validate("skipped", opts.skipped, M.validate_status_options("skipped"))
  vim.validate("loading", opts.loading, M.validate_status_options("loading"))
  return true
end

return M
