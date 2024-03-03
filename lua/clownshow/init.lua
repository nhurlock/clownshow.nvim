local State = require("clownshow.state")
local Config = require("clownshow.config")
local utils = require("clownshow.utils")

local M = {}

---@type table<number, ClownshowState>
local _active = {}

---@param bufnr number
local function reset_buffer(bufnr)
  if not _active[bufnr] then return end
  _active[bufnr]:reset()
  vim.api.nvim_buf_del_user_command(bufnr, "JestWatchStop")
  _active[bufnr] = nil
end

---@param bufnr number
local function attach_to_buffer(bufnr)
  if _active[bufnr] then return end
  local state = State(bufnr)
  _active[bufnr] = state

  vim.api.nvim_buf_create_user_command(bufnr, "JestWatchStop", function()
    reset_buffer(bufnr)
  end, {})

  state.autocmd:create("BufWritePost", function() state:pre_process() end)
  state.autocmd:create("BufUnload", function() reset_buffer(bufnr) end)

  state:pre_process()
  state.job:start()
end

M.set_options = Config.update

---@param opts ClownshowOptions
M.setup = function(opts)
  M.set_options(opts)

  vim.api.nvim_create_user_command("JestWatch", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local filetype = utils.get_filetype(bufnr)

    if filetype ~= "typescript" and filetype ~= "javascript" then return end
    attach_to_buffer(bufnr)
  end, {})
end

return M
