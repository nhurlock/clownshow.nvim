# clownshow.nvim
[Neovim](https://github.com/neovim/neovim) plugin to display live [Jest](https://github.com/facebook/jest) test results and diagnostics directly in your buffer

![clownshow.nvim](https://user-images.githubusercontent.com/9725449/226509636-74f93b20-e7fd-4e34-91b5-45c3975c0425.gif)

## Usage
- `:JestWatch` - starts Jest in watch mode for the current buffer
  - updates on save
  - updates on dependent file changes
- `:JestWatchStop` - stops Jest for the current buffer
  - automatically stops the job on `BufUnload`

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
Initialize using `setup` with the default options:
``` lua
require("clownshow").setup({
  mode = "inline", -- "inline" or "above"
  show_icon = true,
  show_text = false,
  jest_command = function(opts)
    local cmd_path = vim.fn.findfile("node_modules/.bin/jest", vim.fn.fnamemodify(opts.path, ":p:h") .. ";")
    return vim.fn.fnamemodify(cmd_path, ':p')
  end,
  project_root = function()
    return vim.fn.fnamemodify(".", ":p")
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
