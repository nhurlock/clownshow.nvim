local M = {}

function M.validate_status_options(status)
  vim.validate({
    is_table = { status, "table" },
    icon = { status.icon, "string" },
    text = { status.text, "string" },
    hl_group = { status.hl_group, "string" },
  })
  return true
end

---@param opts table
function M.validate_options(opts)
  vim.validate({
    mode = { opts.mode, function(mode) return mode == "inline" or mode == "above" end, "'above' or 'inline'" },
    jest_command = { opts.jest_command, { "function" } },
    project_root = { opts.project_root, { "function" } },
    show_icon = { opts.show_icon, "boolean" },
    show_text = { opts.show_text, "boolean" },
    passed = { opts.passed, M.validate_status_options },
    failed = { opts.failed, M.validate_status_options },
    skipped = { opts.skipped, M.validate_status_options },
    loading = { opts.loading, M.validate_status_options }
  })
  return opts
end

return M
