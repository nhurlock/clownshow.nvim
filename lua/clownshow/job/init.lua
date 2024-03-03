local Object = require("clownshow.object")

---@class ClownshowJestAssertion
---@field status ClownshowIdentifierStatus
---@field location { line: number }
---@field failureMessages? string[]

---@class ClownshowJestResult
---@field message string
---@field assertionResults ClownshowJestAssertion[]

---@class ClownshowJestOutput
---@field testResults ClownshowJestResult[]

---@alias ClownshowJobOnResults fun(results: ClownshowJestResult[]): nil
---@alias ClownshowJobOnExit fun(): nil

---@class ClownshowJob
---@field _bufnr number
---@field _command string
---@field _working_dir string
---@field _buffered_output string
---@field _on_results ClownshowJobOnResults
---@field _on_exit ClownshowJobOnExit
---@field job? number
---@overload fun(bufnr: number, command: string, working_dir: string, on_results: ClownshowJobOnResults, on_exit: ClownshowJobOnExit): ClownshowJob
local Job = Object("ClownshowJob")

---@param bufnr number
---@param command string
---@param working_dir string
---@param on_results ClownshowJobOnResults
---@param on_exit ClownshowJobOnExit
function Job:init(bufnr, command, working_dir, on_results, on_exit)
  self._bufnr = bufnr
  self._command = command
  self._working_dir = working_dir
  self._buffered_output = ""
  self._on_results = on_results
  self._on_exit = on_exit
end

---@param data? string[]
function Job:_process_output(data)
  if not data then return end

  ---@type ClownshowJestOutput?
  local results = nil

  -- process only the jest result output
  for _, line in ipairs(data) do
    if (self._buffered_output ~= "" or (vim.startswith(line, '{') and string.match(line, "numTotalTests") ~= nil)) then
      self._buffered_output = self._buffered_output .. line
      local status_ok, res = pcall(vim.json.decode, self._buffered_output)
      if status_ok then
        results = res
        break
      end
    end
  end

  if not results then return end
  self._buffered_output = ""
  self._on_results(results.testResults or {})
end

function Job:start()
  self._buffered_output = ""
  self.job = vim.fn.jobstart(self._command, {
    cwd = self._working_dir,
    stdout_buffered = false,
    on_stdout = function(_, data)
      self:_process_output(data)
    end,
    on_exit = function()
      self._on_exit()
    end
  })
end

function Job:reset()
  if self.job then vim.fn.jobstop(self.job) end
  self._buffered_output = ""
end

return Job
