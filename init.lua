require 'custom.core.globals'
require 'custom.core.options'
require 'custom.core.autocmds'

if vim.g.vscode then
  require('custom.vscode').setup()
  return
end

require 'custom.core.keymaps'
require 'custom.lazy'

require 'custom.config.autocmds'
require 'custom.config.keymaps'

pcall(vim.cmd.colorscheme, 'catppuccin')
