-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
--

-- Make Shift+Arrow start/extend selection (VS :Code-style)
vim.opt.clipboard = "unnamedplus"
vim.opt.keymodel:append({ "startsel", "stopsel" })
vim.opt.iskeyword:remove(".")
vim.opt.selectmode:append("key")
