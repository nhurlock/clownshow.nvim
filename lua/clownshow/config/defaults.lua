---@class ClownshowJestCommandOptions
---@field bufnr number
---@field path string
---@field root string

---@class ClownshowProjectRootOptions
---@field bufnr number
---@field path string

---@class ClownshowStatusOptions
---@field icon? string
---@field text? string
---@field hl_group? string

---@class ClownshowOptions
---@field mode? "inline"|"above" default is `'inline'`
---@field show_icon? boolean default is `true`
---@field show_text? boolean default is `false`
---@field project_root? fun(opts: ClownshowProjectRootOptions): string
---@field jest_command? fun(opts: ClownshowJestCommandOptions): string
---@field results_fn? fun(results: ClownshowJestResults): nil do something with the json jest output
---@field create_output_win fun(): number create a window to display jest output in, return a window id
---defaults to:
---```lua
---{
---  icon = "✓",
---  text = "Passed",
---  hl_group = "LspDiagnosticsInformation"
---}
---```
---@field passed? ClownshowStatusOptions
---defaults to:
---```lua
---{
---  icon = "✗",
---  text = "Failed",
---  hl_group = "LspDiagnosticsError"
---}
---```
---@field failed? ClownshowStatusOptions
---defaults to:
---```lua
---{
---  icon = "⭘",
---  text = "Skipped",
---  hl_group = "LspDiagnosticsWarning"
---}
---```
---@field skipped? ClownshowStatusOptions
---defaults to:
---```lua
---{
---  icon = "●",
---  text = "Loading...",
---  hl_group = "LspDiagnosticsWarning"
---}
---```
---@field loading? ClownshowStatusOptions

---@type ClownshowOptions
return {
  mode = "inline",
  show_icon = true,
  show_text = false,
  project_root = function()
    local cmd_path = vim.fn.findfile("node_modules/.bin/jest", ".;")
    return vim.fn.fnamemodify(cmd_path, ':p:h:h:h')
  end,
  jest_command = function()
    local cmd_path = vim.fn.findfile("node_modules/.bin/jest", ".;")
    return vim.fn.fnamemodify(cmd_path, ':p')
  end,
  create_output_win = function()
    local win = vim.api.nvim_get_current_win()
    vim.cmd("vsplit")
    local output_win = vim.api.nvim_get_current_win()
    vim.wo[output_win].number = false
    vim.wo[output_win].cursorline = false
    vim.wo[output_win].relativenumber = false
    vim.wo[output_win].signcolumn = "yes:1" -- for some padding
    vim.fn.win_gotoid(win)
    return output_win
  end,
  passed = {
    icon = "✓",
    text = "Passed",
    hl_group = "LspDiagnosticsInformation"
  },
  failed = {
    icon = "✗",
    text = "Failed",
    hl_group = "LspDiagnosticsError"
  },
  skipped = {
    icon = "⭘",
    text = "Skipped",
    hl_group = "LspDiagnosticsWarning"
  },
  loading = {
    icon = "●",
    text = "Loading...",
    hl_group = "LspDiagnosticsWarning"
  }
}
