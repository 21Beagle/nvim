if vim.g.vscode then
  return
end

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end

---@type vim.Option
local rtp = vim.opt.rtp
rtp:prepend(lazypath)

local specs = {}

local function add(module)
  vim.list_extend(specs, require(module))
end

add 'custom.lazy.plugins.core'
add 'custom.lazy.plugins.telescope'
add 'custom.lazy.plugins.lsp'
add 'custom.lazy.plugins.formatting'
add 'custom.lazy.plugins.completion'
add 'custom.lazy.plugins.ui'
add 'custom.lazy.plugins.mini'
add 'custom.lazy.plugins.treesitter'

vim.list_extend(specs, {
  { import = 'custom.plugins' },
  { import = 'custom.colourschemes' },
})

require('lazy').setup(specs, {
  ui = {
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})
