local Config = require("clownshow.config")

local M = {}

---@class ClownshowJobInfo
---@field test_file_name string
---@field project_root string
---@field command string

---@param bufnr number
---@return ClownshowJobInfo?
function M.get_job_info(bufnr)
  local config = Config.get()
  local path = vim.api.nvim_buf_get_name(bufnr)

  local project_root = config.project_root({ bufnr = bufnr, path = path })
  if not project_root or project_root == "" then return end

  local jest_cmd = config.jest_command({ bufnr = bufnr, path = path, root = project_root })
  if not jest_cmd or jest_cmd == "" then return end

  return {
    test_file_name = vim.fn.fnamemodify(path, ":t"),
    project_root = project_root,
    command = jest_cmd .. " " .. table.concat(Config.get_jest_args(), " ") .. " " .. path
  }
end

return M