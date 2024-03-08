local Object = require("clownshow.object")
local Config = require("clownshow.config")

---@class ClownshowJestAssertion
---@field status ClownshowIdentifierStatus
---@field location { line: number }
---@field failureMessages? string[]

---@class ClownshowJestResult
---@field message string
---@field assertionResults ClownshowJestAssertion[]

---@class ClownshowJestResults
---@field testResults ClownshowJestResult[]

---@alias ClownshowJobOnOutput fun(): nil
---@alias ClownshowJobOnResults fun(results: ClownshowJestResult[]): nil
---@alias ClownshowJobOnExit fun(): nil

---@class ClownshowJob
---@field _bufnr number
---@field _command string
---@field _working_dir string
---@field _buffered_results string
---@field _term_bufnr number
---@field _term_chan number
---@field _on_results ClownshowJobOnResults
---@field _on_exit ClownshowJobOnExit
---@field job? number
---@overload fun(bufnr: number, command: string, working_dir: string, on_results: ClownshowJobOnResults, on_exit: ClownshowJobOnExit): ClownshowJob
local Job = Object("ClownshowJob")

-- jest job for the buffer
---@param bufnr number buffer to create job for
---@param command string jest command to run
---@param working_dir string job working directory
---@param on_results ClownshowJobOnResults results handler
---@param on_exit ClownshowJobOnExit exit handler
function Job:init(bufnr, command, working_dir, on_results, on_exit)
  self._bufnr = bufnr
  self._command = command
  self._working_dir = working_dir
  self._buffered_results = ""
  self:_init_terminal()
  self._on_results = on_results
  self._on_exit = on_exit
end

-- create the new terminal buffer and a pipe-to channel
function Job:_init_terminal()
  local bufnr = vim.api.nvim_create_buf(false, false)
  vim.bo[bufnr].filetype = "clownshow-output"
  self._term_bufnr = bufnr
  self._term_chan = vim.api.nvim_open_term(self._term_bufnr, {})
end

-- handle processing of the jest watch output
---@param data? string[] chunk job output
function Job:_process_output(data)
  if not data then return end
  local config = Config.opts

  ---@type ClownshowJestResults?
  local results = nil

  for i, line in ipairs(data) do
    -- process only the jest result output
    if not results and (self._buffered_results ~= "" or (vim.startswith(line, '{') and string.match(line, "numTotalTests") ~= nil)) then
      -- remove color term codes from output so they don't show up in diagnostics
      local no_term_codes = string.gsub(line, "\\u001b%[[0-9]+m", "")
      self._buffered_results = self._buffered_results .. no_term_codes

      -- if we can properly json decode then we've completed the results
      local status_ok, res = pcall(vim.json.decode, self._buffered_results)
      if status_ok then
        results = res
      end
    else
      -- only apply newlines if there is already output and never newline-postfix
      -- trailing content will always be considered an incomplete line
      -- example:
      --   { l1, l2, l3, l4 }, { l5, l6 } -> l1 \n l2 \n l3 \n l4+l5 \n l6
      if i > 1 then
        vim.api.nvim_chan_send(self._term_chan, "\r\n")
      end

      -- send the terminal channel the line
      vim.api.nvim_chan_send(self._term_chan, line)
    end
  end

  if not results then return end
  self._buffered_results = ""
  -- send jest json results to user if desired
  if config.results_fn ~= nil then
    config.results_fn(vim.deepcopy(results))
  end
  self._on_results(results.testResults or {})
end

-- start the jest job
function Job:start()
  self._buffered_results = ""
  self.job = vim.fn.jobstart(self._command, {
    pty = true,
    stdout_buffered = false,
    cwd = self._working_dir,
    on_stdout = function(_, data)
      self:_process_output(data)
    end,
    on_exit = function()
      self._on_exit()
    end
  })
end

-- clear job state
function Job:reset()
  if self.job then vim.fn.jobstop(self.job) end
  if self._term_bufnr then pcall(vim.api.nvim_buf_delete, self._term_bufnr, { force = true }) end
  vim.fn.chanclose(self._term_chan)
  self._buffered_results = ""
end

return Job
