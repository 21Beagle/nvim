-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
--

-- Make Shift+Arrow start/extend selection (VS :Code-style)
local ok, _ = pcall(vim.cmd, "colorscheme onedark")
if not ok then
	vim.cmd("colorscheme default") -- if the above fails, then use default
end

vim.opt.clipboard = "unnamedplus"
vim.opt.keymodel:append({ "startsel", "stopsel" })
vim.opt.iskeyword:remove(".")
vim.opt.iskeyword:remove("(")
vim.opt.iskeyword:remove(")")
vim.opt.iskeyword:remove(" ")
-- No conceal anywhere (prevents => turning into arrows, etc.)
vim.opt.conceallevel = 0
vim.opt.concealcursor = ""

vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "FileType" }, {
	group = vim.api.nvim_create_augroup("NoConcealAnywhere", { clear = true }),
	callback = function()
		vim.opt_local.conceallevel = 0
		vim.opt_local.concealcursor = ""
	end,
})
vim.opt.selectmode:append("key")
