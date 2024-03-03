local Object = require("clownshow.object")
local Job = require("clownshow.job")
local Marks = require("clownshow.marks")
local Autocmd = require("clownshow.autocmd")
local Diagnostics = require("clownshow.diagnostics")
local Identifiers = require("clownshow.identifiers")
local Identifier = require("clownshow.identifiers.identifier")
local job_utils = require("clownshow.job.utils")

---@class ClownshowState
---@field _processed boolean
---@field _bufnr number
---@field _job_info ClownshowJobInfo?
---@field job ClownshowJob
---@field marks ClownshowMarks
---@field autocmd ClownshowAutocmd
---@field diagnostics ClownshowDiagnostics
---@field identifiers ClownshowIdentifiers
---@overload fun(bufnr: number): ClownshowState
local State = Object("ClownshowState")

---@param bufnr number
function State:init(bufnr)
  self._processed = false
  self._bufnr = bufnr
  self._job_info = job_utils.get_job_info(self._bufnr)
  self.job = Job(
    self._bufnr,
    self._job_info.command,
    self._job_info.project_root,
    function(results) self:_handle_results(results) end,
    function() self:reset() end
  )
  self.marks = Marks(self._bufnr)
  self.autocmd = Autocmd(self._bufnr)
  self.diagnostics = Diagnostics(self._bufnr, self._job_info.test_file_name)
  self.identifiers = Identifiers(self._bufnr)
end

function State:reset()
  self.job:reset()
  self.marks:reset()
  self.autocmd:reset()
  self.diagnostics:reset()
  self.identifiers:reset()
end

function State:pre_process()
  self.marks:reset()
  self.diagnostics:reset()
  self.identifiers:update()

  -- set initial "loading" states for all identifiers that are not known to be skipped
  for _, identifier in pairs(self.identifiers:get()) do
    identifier:reset_stats()

    if identifier.status ~= "pending" then
      identifier.status = "loading"
    end
    -- force-apply the initial status mark
    self.marks:status(identifier, nil, true)
  end

  self._processed = true
end

---@param assertion ClownshowJestAssertion
---@return ClownshowIdentifier?
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

---@param results ClownshowJestResult[]
function State:_handle_results(results)
  -- if processing has not yet been run, force a run before handling results
  -- this will happen when a non-test buffer triggers jest watch to rerun a test
  if not self._processed then self:pre_process() end
  self._processed = false

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
          identifier:apply_status("failed")
          self.diagnostics:create(identifier, assertion.failureMessages[1])
        elseif assertion.status == "passed" then
          identifier:apply_status("passed")
        elseif assertion.status == "pending" then
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

  -- any identifiers that still have a "loading" status get set to skipped
  -- ignore parents here as the stats mark will apply the skipped state mark
  for _, identifier in pairs(self.identifiers:get()) do
    if identifier.status == "loading" and identifier.type == "test" then
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
