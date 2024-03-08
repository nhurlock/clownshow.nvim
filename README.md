# clownshow.nvim
[Neovim](https://github.com/neovim/neovim) plugin to display live [Jest](https://github.com/facebook/jest) test results and diagnostics directly in your buffer

![clownshow.nvim](https://user-images.githubusercontent.com/9725449/226509636-74f93b20-e7fd-4e34-91b5-45c3975c0425.gif)

## Usage
- `:JestWatch` - starts Jest in watch mode for the current buffer
  - updates on save
  - updates on dependent file changes
- `:JestWatchStop` - stops Jest for the current buffer
  - automatically stops the job on `BufUnload`
- `:JestWatchToggle` - toggles between start/stop states for the current buffer
- `:JestWatchLog` - open the Jest output log window for the current buffer
- `:JestWatchLogToggle` - toggles the Jest output log window for the current buffer

Multiple files can be watched at the same time, simply run the `JestWatch` command on each

## Dependencies
- javascript / typescript treesitter parser must be installed/enabled

## Installation
Install with your package manager:
- With [`lazy.nvim`](https://github.com/folke/lazy.nvim):
  ``` lua
  {
    "nhurlock/clownshow.nvim",
    -- ft = { "typescript", "javascript" },
    -- cmd = "JestWatch",
    event = {
      "BufEnter *.test.[tj]s",
      "BufEnter *.spec.[tj]s"
    },
    config = true
  }
  ```

## Configuration
See full configuration options in the [docs](./doc/clownshow.txt).<br>
Initialize using `setup` with the default options (you don't need to supply these values):
``` lua
require("clownshow").setup({
  mode = "inline", -- "inline" or "above"
  show_icon = true,
  show_text = false,
  project_root = function()
    return vim.fn.fnamemodify(".", ":p")
  end,
  jest_command = function(opts)
    local cmd_path = vim.fn.findfile("node_modules/.bin/jest", vim.fn.fnamemodify(opts.path, ":p:h") .. ";")
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
})
```

Making configuration changes after initial `setup` using `set_options`:
```lua
require("clownshow").set_options({ ... })
```
