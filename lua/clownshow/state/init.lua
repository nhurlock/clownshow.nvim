local Object = require("clownshow.object")
local Job = require("clownshow.job")
local Marks = require("clownshow.marks")
local Autocmd = require("clownshow.autocmd")
local Usercmd = require("clownshow.usercmd")
local Diagnostics = require("clownshow.diagnostics")
local Identifiers = require("clownshow.identifiers")
local Identifier = require("clownshow.identifiers.identifier")
local job_utils = require("clownshow.job.utils")
local utils = require("clownshow.utils")

---@class ClownshowState
---@field _invalidated boolean
---@field _warn_notified boolean
---@field _bufnr number
---@field _job_info ClownshowJobInfo?
---@field _on_exit fun(): nil
---@field job ClownshowJob
---@field term_usercmd ClownshowUsercmd
---@field marks ClownshowMarks
---@field autocmd ClownshowAutocmd
---@field usercmd ClownshowUsercmd
---@field diagnostics ClownshowDiagnostics
---@field identifiers ClownshowIdentifiers
---@overload fun(bufnr: number, on_exit: fun(): nil): ClownshowState
local State = Object("ClownshowState")

---@param bufnr number buffer to track state for
---@param on_exit fun(): nil function to call on exit once state has been reset
function State:init(bufnr, on_exit)
  self._invalidated = true
  self._warn_notified = false
  self._bufnr = bufnr
  self._job_info = job_utils.get_job_info(self._bufnr)
  self._on_exit = on_exit
  self.job = Job(
    self._bufnr,
    self._job_info.command,
    self._job_info.project_root,
    function(results) self:_handle_results(results) end,
    function() self:reset() end
  )
  self.term_usercmd = Usercmd(self.job._term_bufnr)
  self.marks = Marks(self._bufnr)
  self.autocmd = Autocmd(self._bufnr)
  self.usercmd = Usercmd(self._bufnr)
  self.diagnostics = Diagnostics(self._bufnr, self._job_info.test_file_name)
  self.identifiers = Identifiers(self._bufnr)
end

-- clear buffer state
function State:reset()
  self._invalidated = true
  self._warn_notified = false
  self.term_usercmd:reset()
  self.job:reset()
  self.marks:reset()
  self.autocmd:reset()
  self.usercmd:reset()
  self.diagnostics:reset()
  self.identifiers:reset()
  self._on_exit()
end

-- invalidate the buffer when modified
function State:on_modified_set()
  self._invalidated = utils.is_modified(self._bufnr)
end

-- apply loading states and update identifiers if needed ahead of results
function State:pre_process()
  self._warn_notified = false
  if self._invalidated then
    self._invalidated = false
    self.marks:reset()
    self.diagnostics:reset()
    self.identifiers:update()
  end

  for _, identifier in pairs(self.identifiers:get()) do
    -- set initial "loading" states for all identifiers that are not known to be skipped
    if identifier.status ~= "pending" then
      identifier.status = "loading"
    end
    -- force-apply the initial status mark
    self.marks:status(identifier, nil, true)
  end
end

-- associates a jest assertion to an identifier
---@param assertion ClownshowJestAssertion jest assertion
---@return ClownshowIdentifier? identifier matched identifier
function State:_get_result_identifier(assertion)
  local valid_location, location = pcall(function() return assertion.location.line - 1 end)
  if valid_location then
    local identifier = self.identifiers:get_by_line(location)
    if identifier then
      return identifier
    end
  end

  -- in the event that no identifier can be found
  -- attempt to find one through the stack trace
  if assertion.failureMessages and #assertion.failureMessages > 0 then
    local message_lines = vim.split(assertion.failureMessages[1], "\n", { trimempty = true })
    for _, message_line in ipairs(message_lines) do
      local stack_location = self.diagnostics:get_stack_location(message_line)
      if stack_location then
        local identifier = self.identifiers:get_by_line(stack_location[1])
        if identifier then
          return identifier
        end
      end
    end
  end
end

-- handle jest test results
---@param results ClownshowJestResult[] jest test results
function State:_handle_results(results)
  -- if processing has not yet been run, we cannot apply jest results as there may be line mismatch
  -- this will happen when a non-test buffer triggers jest watch to rerun a test
  if self._invalidated then
    if not self._warn_notified then
      vim.notify(
        "[clownshow.nvim] unsaved changes to test file, Jest results paused until file is saved",
        vim.log.levels.WARN
      )
      self._warn_notified = true
    end
    return
  end
  -- clear old stats before appling new status updates
  self.identifiers:reset_stats()

  -- only handle results for the active test file
  -- this will handle a case where we may have somehow received more than just the original file's results
  results = vim.tbl_filter(function(item)
    return item.name == self._job_info.test_file_path
  end, results)

  ---@type table<number, boolean>
  local updated = {}

  ---@type string?
  local message
  -- apply identifier states based off the test results
  for _, result in ipairs(results) do
    message = result.message
    for _, assertion in ipairs(result.assertionResults) do
      local identifier = self:_get_result_identifier(assertion)
      if identifier then
        message = nil
        if assertion.status == "failed" then
          updated[identifier.line] = true
          identifier:apply_status("failed")
          self.diagnostics:create(identifier, assertion.failureMessages[1])
        elseif assertion.status == "passed" then
          updated[identifier.line] = true
          identifier:apply_status("passed")
        elseif assertion.status == "pending" then
          updated[identifier.line] = true
          identifier:apply_status("pending")
        end
      end
    end
  end

  -- if a message still exists, there was a file-level error
  -- that caused the test suite to not run
  if message and message ~= "" then
    local top_line = Identifier({ line = 0, col = 0, endline = 0 })
    self.diagnostics:create(top_line, message)
  end

  -- any identifiers that still have not been updated get set to skipped
  -- ignore parents here as the stats mark will apply the skipped state mark
  for _, identifier in pairs(self.identifiers:get()) do
    if updated[identifier.line] == nil and identifier.type == "test" then
      identifier:apply_status("pending")
    end
  end

  -- display stats
  for _, identifier in pairs(self.identifiers:get()) do
    self.marks:stats(identifier)
  end

  self.diagnostics:apply()
end

return State
