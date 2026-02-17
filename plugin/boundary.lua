if vim.g.loaded_boundary then
  return
end
vim.g.loaded_boundary = true

require("boundary").register()
require("boundary.commands").register()
