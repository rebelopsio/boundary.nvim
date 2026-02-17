# boundary.nvim

Neovim plugin for [boundary](https://github.com/smorgan/boundary), a DDD/Hexagonal Architecture static analysis tool.

Provides LSP integration (diagnostics and hover) via `boundary-lsp` and commands that shell out to the `boundary` CLI for architecture scores, analysis reports, and diagrams.

Requires **Neovim 0.11+** (uses native `vim.lsp.config`/`vim.lsp.enable`).

## Installation

### lazy.nvim

```lua
{
  "smorgan/boundary.nvim",
  opts = {},
}
```

### Default configuration

```lua
require("boundary").setup({
  cmd = { "boundary-lsp" },          -- LSP server command
  boundary_cmd = "boundary",          -- CLI binary for commands
  filetypes = { "go", "rust", "typescript", "java" },
  root_markers = { ".boundary.toml", ".git" },
  autostart = true,                   -- auto-start LSP on matching filetypes
})
```

## Features

### LSP (automatic)

- **Diagnostics** — boundary violations appear as warnings/errors inline
- **Hover** — hover over a symbol to see its component and architectural layer

### Commands

| Command | Description |
|---|---|
| `:BoundaryAnalyze [format]` | Full architecture report (`text`, `json`, or `markdown`) |
| `:BoundaryScore` | Architecture score in a floating window |
| `:BoundaryDiagram [type]` | Mermaid/DOT diagram (`layers`, `dependencies`, `dot`, `dot-dependencies`) |
| `:BoundaryCheck` | Pass/fail check with violation summary |

### Statusline

Add the score to your statusline (e.g., lualine):

```lua
require("lualine").setup({
  sections = {
    lualine_x = {
      { require("boundary.statusline").get },
    },
  },
})
```

The score refreshes automatically when the LSP reports new diagnostics. Call `require("boundary.statusline").refresh()` to trigger a manual refresh.

## Prerequisites

- [boundary](https://github.com/smorgan/boundary) CLI and `boundary-lsp` installed and on your `$PATH`
- A `.boundary.toml` config file in your project root
- Neovim >= 0.11

## License

MIT
