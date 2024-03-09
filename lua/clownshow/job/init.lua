local Object = require("clownshow.object")
local Config = require("clownshow.config")

local allowed_jest_term_inputs = { "w", "c", "t", "q", "\r", "\x1b" }
local ignored_jest_input_strings = {
  "run all tests",
  "changed files",
  "run only failed tests",
  "filter by a filename regex pattern"
}

---@param line string line input from jest watch
---@return boolean result if the line should be ignored
local function is_ignored_jest_input(line)
  local match = string.match(line, "Press.+to (.*)%.")
  return match ~= nil and vim.tbl_contains(ignored_jest_input_strings, match)
end

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

-- create the new terminal buffer and a pipe-to channel for filtering
function Job:_init_terminal()
  local term_allow_all = false
  local bufnr = vim.api.nvim_create_buf(false, false)
  vim.bo[bufnr].filetype = "clownshow-output"
  self._term_bufnr = bufnr
  self._term_chan = vim.api.nvim_open_term(self._term_bufnr, {
    on_input = function(_, _, _, data)
      if self.job and term_allow_all or vim.tbl_contains(allowed_jest_term_inputs, data) then
        -- 't' command in jest watch will allow filtering test names, allow user to enter any char for name
        if data == "t" then term_allow_all = true end
        -- if a return or escape is input, we can always fallback to input restriction
        if data == "\r" or data == "\x1b" then term_allow_all = false end

        -- special case with 'c' which usually would clear filters in jest watch
        -- we want to allow clearing of a 't'-entered test name, without clearing the file filter
        -- so we send a 't' instead and a return to clear the 't'-entered test name, leaving the file name filter
        if not term_allow_all and data == "c" then
          vim.api.nvim_chan_send(self.job, "\x74")
          vim.schedule(function()
            vim.api.nvim_chan_send(self.job, "\x0d")
          end)
        else
          -- all other input is allowed
          vim.api.nvim_chan_send(self.job, data)
        end
      end
    end
  })
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
    elseif not is_ignored_jest_input(line) then
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
