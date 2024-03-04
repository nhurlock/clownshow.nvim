local Object = require("clownshow.object")
local Config = require("clownshow.config")

---@class ClownshowStackLocation
---@field [1] number
---@field [2] number

---@class ClownshowDiagnostics
---@field _bufnr number
---@field _file_name string
---@field diagnostics Diagnostic[]
---@overload fun(bufnr: number, file_name: string): ClownshowDiagnostics
local Diagnostics = Object("ClownshowDiagnostics")

---@param bufnr number
---@param file_name string
function Diagnostics:init(bufnr, file_name)
  self._bufnr = bufnr
  self._file_name = file_name
  self.diagnostics = {}
end

---@param line string
---@return ClownshowStackLocation?
function Diagnostics:get_stack_location(line)
  if line and line:match(self._file_name) then
    for match in string.gmatch(line, "at .*" .. self._file_name .. ":([0-9]+:[0-9]+)") do
      local match_split = vim.split(match, ":")
      return { tonumber(match_split[1]) - 1, tonumber(match_split[2]) - 1 }
    end
  end
end

---@param identifier ClownshowIdentifier
---@param message string
function Diagnostics:create(identifier, message)
  local message_lines = vim.split(message, "\n")
  ---@type string[]
  local err_message = {}
  ---@type number?
  local err_line
  ---@type number?
  local err_col

  -- find a stack trace line matching the test file and identifier scope
  -- set the error location to the specific reference, trim remaining trace
  -- remaining trace will be jest-internal
  for _, message_line in ipairs(message_lines) do
    local stack_location = self:get_stack_location(message_line)
    ---@type number?
    local match_line
    if stack_location then
      match_line = stack_location[1]

      if match_line >= identifier.line and match_line <= identifier.endline then
        err_line = match_line
        err_col = stack_location[2]
      end
    end
    if err_line and err_line ~= match_line then break end
    table.insert(err_message, message_line)
  end

  if err_line then
    -- last line was the error, pop off the last line and extra whitepace
    table.remove(err_message)
    while vim.trim(err_message[#err_message]) == "" do
      table.remove(err_message)
    end
  end

  ---@type Diagnostic
  local diagnostic = {
    bufnr = self._bufnr,
    lnum = err_line or identifier.line,
    col = err_col or 0,
    message = table.concat(err_message, "\n"),
    severity = vim.diagnostic.severity.ERROR,
    source = Config.source,
    user_data = {}
  }
  table.insert(self.diagnostics, diagnostic)
end

function Diagnostics:apply()
  vim.diagnostic.set(Config.ns, self._bufnr, self.diagnostics)
  self.diagnostics = {}
end

function Diagnostics:reset()
  vim.diagnostic.reset(Config.ns, self._bufnr)
  self.diagnostics = {}
end

return Diagnostics
