local M = {}

local cached_score = nil
local fetching = false

function M.refresh()
  if fetching then
    return
  end

  local root = require("boundary").get_root_dir()
  if not root then
    return
  end

  fetching = true
  local boundary_cmd = require("boundary").config.boundary_cmd

  vim.system(
    { boundary_cmd, "analyze", root, "--format", "json", "--compact" },
    { text = true },
    vim.schedule_wrap(function(result)
      fetching = false
      if result.code ~= 0 then
        return
      end
      local ok, data = pcall(vim.json.decode, result.stdout)
      if ok and data and data.score then
        cached_score = data.score.overall
      end
    end)
  )
end

function M.get()
  if cached_score then
    return string.format("Boundary: %.0f/100", cached_score)
  end
  return ""
end

local group = vim.api.nvim_create_augroup("BoundaryStatusline", { clear = true })

vim.api.nvim_create_autocmd("LspNotification", {
  group = group,
  callback = function(args)
    if args.data and args.data.client_id then
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and client.name == "boundary" then
        M.refresh()
      end
    end
  end,
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = group,
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == "boundary" then
      M.refresh()
    end
  end,
})

return M
