-- Keep these on the runtimepath so the colorscheme picker can discover every variant.
local themes = {
  { 'folke/tokyonight.nvim' },
  { 'rose-pine/neovim', name = 'rose-pine' },
  { 'EdenEast/nightfox.nvim' },
  { 'Shatur/neovim-ayu' },
  { 'ellisonleao/gruvbox.nvim' },
  { 'oxfist/night-owl.nvim' },
  { 'projekt0n/github-nvim-theme' },
  { 'olivercederborg/poimandres.nvim' },
  { 'shaunsingh/nord.nvim' },
  { 'AlexvZyl/nordic.nvim' },
  { 'maxmx03/fluoromachine.nvim' },
  { 'Mofiqul/vscode.nvim' },
  { 'slugbyte/lackluster.nvim' },
  -- Oxocarbon ships compiled Lua; its optional rockspec build is unnecessary.
  { 'nyoom-engineering/oxocarbon.nvim', build = false },
  { 'craftzdog/solarized-osaka.nvim' },
  { 'savq/melange-nvim' },
  { 'bluz71/vim-moonfly-colors', name = 'moonfly' },
  { 'bluz71/vim-nightfly-colors', name = 'nightfly' },
  { 'loctvl842/monokai-pro.nvim' },
  { 'ribru17/bamboo.nvim' },
}

for _, theme in ipairs(themes) do
  theme.lazy = false
  theme.priority = 1000
end

return themes
