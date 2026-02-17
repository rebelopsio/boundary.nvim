local M = {}

local function get_root()
  local root = require("boundary").get_root_dir()
  if not root then
    vim.notify("boundary: no project root found", vim.log.levels.WARN)
  end
  return root
end

local function open_scratch_buffer(lines, filetype)
  vim.cmd("vnew")
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  if filetype then
    vim.bo[buf].filetype = filetype
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
end

local function run_cmd(args, opts)
  opts = opts or {}
  local boundary_cmd = require("boundary").config.boundary_cmd

  vim.system(
    vim.list_extend({ boundary_cmd }, args),
    { text = true },
    vim.schedule_wrap(function(result)
      if result.code ~= 0 and not opts.allow_nonzero then
        local err = result.stderr ~= "" and result.stderr or result.stdout
        vim.notify("boundary: " .. (err or "command failed"), vim.log.levels.ERROR)
        return
      end
      if opts.on_success then
        opts.on_success(result)
      end
    end)
  )
end

function M.analyze(format)
  local root = get_root()
  if not root then return end

  format = format or "text"
  run_cmd({ "analyze", root, "--format", format }, {
    on_success = function(result)
      local lines = vim.split(result.stdout, "\n", { trimempty = true })
      local ft = format == "json" and "json" or nil
      open_scratch_buffer(lines, ft)
    end,
  })
end

function M.score()
  local root = get_root()
  if not root then return end

  run_cmd({ "analyze", root, "--format", "json", "--compact" }, {
    on_success = function(result)
      local ok, data = pcall(vim.json.decode, result.stdout)
      if not ok or not data or not data.score then
        vim.notify("boundary: failed to parse score", vim.log.levels.ERROR)
        return
      end

      local s = data.score
      local lines = {
        "Boundary Architecture Score",
        string.rep("─", 35),
        string.format("  Overall:              %.1f / 100", s.overall),
        string.format("  Layer Isolation:      %.1f / 100", s.layer_isolation),
        string.format("  Dependency Direction: %.1f / 100", s.dependency_direction),
        string.format("  Interface Coverage:   %.1f / 100", s.interface_coverage),
        string.rep("─", 35),
        string.format("  Components: %d   Violations: %d", data.component_count or 0, #(data.violations or {})),
      }

      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.bo[buf].modifiable = false

      local width = 40
      local height = #lines + 2
      vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = math.floor((vim.o.lines - height) / 2),
        col = math.floor((vim.o.columns - width) / 2),
        style = "minimal",
        border = "rounded",
        title = " Boundary ",
        title_pos = "center",
      })

      vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, silent = true })
      vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", { buffer = buf, silent = true })
    end,
  })
end

function M.diagram(diagram_type)
  local root = get_root()
  if not root then return end

  diagram_type = diagram_type or "layers"
  run_cmd({ "diagram", root, "--diagram-type", diagram_type }, {
    on_success = function(result)
      local lines = vim.split(result.stdout, "\n", { trimempty = true })
      open_scratch_buffer(lines, "markdown")
    end,
  })
end

function M.check()
  local root = get_root()
  if not root then return end

  run_cmd({ "check", root, "--format", "text" }, {
    allow_nonzero = true,
    on_success = function(result)
      local output = result.stdout .. (result.stderr or "")
      local lines = vim.split(output, "\n", { trimempty = true })
      local level = result.code == 0 and vim.log.levels.INFO or vim.log.levels.WARN
      vim.notify(table.concat(lines, "\n"), level, { title = "Boundary Check" })
    end,
  })
end

function M.register()
  vim.api.nvim_create_user_command("BoundaryAnalyze", function(opts)
    M.analyze(opts.fargs[1])
  end, {
    nargs = "?",
    complete = function()
      return { "text", "json", "markdown" }
    end,
    desc = "Run boundary architecture analysis",
  })

  vim.api.nvim_create_user_command("BoundaryScore", function()
    M.score()
  end, {
    desc = "Show boundary architecture score",
  })

  vim.api.nvim_create_user_command("BoundaryDiagram", function(opts)
    M.diagram(opts.fargs[1])
  end, {
    nargs = "?",
    complete = function()
      return { "layers", "dependencies", "dot", "dot-dependencies" }
    end,
    desc = "Generate boundary architecture diagram",
  })

  vim.api.nvim_create_user_command("BoundaryCheck", function()
    M.check()
  end, {
    desc = "Run boundary architecture check",
  })
end

return M
