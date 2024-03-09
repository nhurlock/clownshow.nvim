local Config = require("clownshow.config")

local M = {}

---@class ClownshowJobInfo
---@field test_file_name string
---@field test_file_path string
---@field project_root string
---@field command string

---@param bufnr number buffer to get job info for
---@return ClownshowJobInfo? job_info job info for the buffer
function M.get_job_info(bufnr)
  local config = Config.opts
  local path = vim.api.nvim_buf_get_name(bufnr)

  local project_root = config.project_root({ bufnr = bufnr, path = path })
  if not project_root or project_root == "" then return end

  local jest_cmd = config.jest_command({ bufnr = bufnr, path = path, root = project_root })
  if not jest_cmd or jest_cmd == "" then return end

  return {
    test_file_name = vim.fn.fnamemodify(path, ":t"),
    test_file_path = vim.fn.fnamemodify(path, ":p"),
    project_root = project_root,
    command = jest_cmd .. " " .. Config.jest_args .. " " .. path
  }
end

return M
