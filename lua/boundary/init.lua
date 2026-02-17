local M = {}

M.config = {
  cmd = { "boundary-lsp" },
  boundary_cmd = "boundary",
  filetypes = { "go", "rust", "typescript", "java" },
  root_markers = { ".boundary.toml", ".git" },
  autostart = true,
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

function M.register()
  vim.lsp.config("boundary", {
    cmd = M.config.cmd,
    filetypes = M.config.filetypes,
    root_markers = M.config.root_markers,
  })

  if M.config.autostart then
    vim.lsp.enable("boundary")
  end
end

function M.get_root_dir()
  local clients = vim.lsp.get_clients({ name = "boundary" })
  if clients[1] then
    return clients[1].root_dir
  end
  -- Fallback: search upward for .boundary.toml
  local found = vim.fs.find(".boundary.toml", {
    upward = true,
    path = vim.fn.expand("%:p:h"),
  })
  if found[1] then
    return vim.fn.fnamemodify(found[1], ":h")
  end
  return nil
end

return M
