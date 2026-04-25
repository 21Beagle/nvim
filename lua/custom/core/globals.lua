vim.opt.shortmess:append 'I'
vim.opt.termguicolors = true

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.g.python3_host_prog = vim.fn.exepath 'python3'
-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true
