local State = require("clownshow.state")
local Config = require("clownshow.config")
local utils = require("clownshow.utils")

local M = {}

---@type table<number, ClownshowState>
local _active = {}

---@param bufnr number buffer to reset
local function reset_buffer(bufnr)
  if not _active[bufnr] then return end
  _active[bufnr]:reset()
  _active[bufnr] = nil
end

---@param bufnr number buffer to attach to
local function attach_to_buffer(bufnr)
  if _active[bufnr] then return end
  local state = State(bufnr)
  _active[bufnr] = state
  local config = Config.opts

  local function log_toggle()
    local winid = vim.fn.bufwinid(state.job._term_bufnr)
    if winid ~= nil and winid ~= -1 then
      pcall(vim.api.nvim_win_hide, vim.fn.bufwinid(state.job._term_bufnr))
    else
      M.show_log(bufnr, config.create_output_win())
    end
  end

  state.usercmd:create("JestWatchLogToggle", log_toggle)
  state.usercmd:create({ "JestWatchStop", "JestWatchToggle" }, M.stop)
  state.usercmd:create("JestWatchLog", M.show_log)

  state.autocmd:create("BufModifiedSet", function() state:on_modified_set() end)
  state.autocmd:create("BufWritePost", function() state:pre_process() end)
  state.autocmd:create("BufUnload", reset_buffer)

  state.term_usercmd:create("JestWatchLogToggle", log_toggle)

  -- start process on-attach
  state:pre_process()
  state.job:start()
end

-- initializes the state for jest watch on a buffer and starts process
---@param bufnr? number buffer to start jest watch
function M.start(bufnr)
  if not bufnr then bufnr = vim.api.nvim_get_current_buf() end
  local filetype = utils.get_filetype(bufnr)

  if filetype ~= "typescript" and filetype ~= "javascript" then return end
  attach_to_buffer(bufnr)
end

-- clears existing state for the buffer
---@param bufnr? number buffer to stop jest watch, defaults to current buffer
function M.stop(bufnr)
  if not bufnr then bufnr = vim.api.nvim_get_current_buf() end
  reset_buffer(bufnr)
end

-- returns the bufnr for the jest output
---@param bufnr? number buffer to get jest output buffer for, default to current buffer
function M.log_bufnr(bufnr)
  if not bufnr then bufnr = vim.api.nvim_get_current_buf() end
  if not _active[bufnr] then return end
  return _active[bufnr].job._term_bufnr
end

-- opens the jest watch log view
---@param bufnr? number buffer to view jest watch log output for, defaults to current buffer
---@param winid? number window to display buffer in, defaults to current window
function M.show_log(bufnr, winid)
  local log_bufnr = M.log_bufnr(bufnr)
  if not log_bufnr then return end

  if winid == nil or winid == -1 then
    winid = Config.opts.create_output_win()
  end
  if winid == nil or winid == -1 then return end

  vim.api.nvim_win_set_buf(winid, log_bufnr)
  vim.fn.win_execute(winid, "norm G", true)
end

M.set_options = Config.update

---@param opts ClownshowOptions clownshow options
function M.setup(opts)
  M.set_options(opts)

  vim.api.nvim_create_user_command("JestWatch", function() M.start() end, {})
  vim.api.nvim_create_user_command("JestWatchToggle", function() M.start() end, {})
end

return M
