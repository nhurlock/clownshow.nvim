local M = {}

---@param status any status to validate
---@return boolean valid valid status
function M.validate_status_options(status)
  vim.validate({
    is_table = { status, "table" },
    icon = { status.icon, "string" },
    text = { status.text, "string" },
    hl_group = { status.hl_group, "string" },
  })
  return true
end

---@param opts table options to validate
---@return boolean valid valid options
function M.validate_options(opts)
  vim.validate({
    mode = { opts.mode, function(mode) return mode == "inline" or mode == "above" end, "'above' or 'inline'" },
    show_icon = { opts.show_icon, "boolean" },
    show_text = { opts.show_text, "boolean" },
    project_root = { opts.project_root, "function" },
    jest_command = { opts.jest_command, "function" },
    results_fn = { opts.results_fn, { "function", "nil" } },
    create_output_win = { opts.create_output_win, "function" },
    passed = { opts.passed, M.validate_status_options },
    failed = { opts.failed, M.validate_status_options },
    skipped = { opts.skipped, M.validate_status_options },
    loading = { opts.loading, M.validate_status_options }
  })
  return true
end

return M
