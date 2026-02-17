local M = {}

function M.check()
  vim.health.start("boundary.nvim")

  -- Check Neovim version (vim.lsp.config/enable require 0.11+)
  if vim.fn.has("nvim-0.11") == 1 then
    vim.health.ok("Neovim >= 0.11")
  else
    vim.health.error("Neovim >= 0.11 is required", {
      "boundary.nvim uses vim.lsp.config() and vim.lsp.enable() which require Neovim 0.11+",
    })
  end

  local config = require("boundary").config

  -- Check boundary-lsp executable
  local lsp_cmd = config.cmd[1]
  if vim.fn.executable(lsp_cmd) == 1 then
    vim.health.ok(string.format("'%s' found", lsp_cmd))
  else
    vim.health.error(string.format("'%s' not found", lsp_cmd), {
      "Install boundary-lsp and ensure it is on your PATH",
    })
  end

  -- Check boundary CLI executable
  local boundary_cmd = config.boundary_cmd
  if vim.fn.executable(boundary_cmd) == 1 then
    vim.health.ok(string.format("'%s' CLI found", boundary_cmd))
  else
    vim.health.warn(string.format("'%s' CLI not found", boundary_cmd), {
      "Install the boundary CLI to use :BoundaryAnalyze, :BoundaryScore, :BoundaryCheck, and :BoundaryDiagram",
    })
  end

  -- Check LSP client status
  local clients = vim.lsp.get_clients({ name = "boundary" })
  if #clients > 0 then
    vim.health.ok(string.format("LSP client attached (root: %s)", clients[1].root_dir or "unknown"))
  else
    vim.health.info("LSP client not attached to current buffer")
  end
end

return M
