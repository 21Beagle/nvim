-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Ctrl + / : toggle line comments (like VS Code / Rider)
map("n", "<C-/>", function()
	require("Comment.api").toggle.linewise.current()
end, opts)

map("v", "<C-/>", function()
	local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
	vim.api.nvim_feedkeys(esc, "nx", false)
	require("Comment.api").toggle.linewise(vim.fn.visualmode())
end, opts)

-- movel lines up and down with alt arrows
map("n", "<A-Up>", ":m .-2<CR>==", opts)
map("n", "<A-Down>", ":m .+1<CR>==", opts)
map("v", "<A-Up>", ":m '<-2<CR>gv=gv", opts)
map("v", "<A-Down>", ":m '>+1<CR>gv=gv", opts)

-- Ctrl+Right / Ctrl+Left move by words (respecting '.' as separator)
map("n", "<C-Right>", "w", opts)
map("n", "<C-Left>", "b", opts)

map("i", "<C-Right>", "<C-o>w", opts)
map("i", "<C-Left>", "<C-o>b", opts)

map("v", "<C-Right>", "w", opts)
map("v", "<C-Left>", "b", opts)

-- Code actions (Ctrl + .) - matches VS / VSCode / Rider
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspGoto", { clear = true }),
	callback = function(ev)
		-- Basic LSP gotos
		map("n", "gd", vim.lsp.buf.definition, opts)
		map("n", "gD", vim.lsp.buf.declaration, opts)
		map("n", "gi", vim.lsp.buf.implementation, opts)
		map("n", "gt", vim.lsp.buf.type_definition, opts)

		map("n", "<C-.>", vim.lsp.buf.code_action, opts)
		map("v", "<C-.>", vim.lsp.buf.code_action, opts)

		map("n", "<F12>", vim.lsp.buf.definition, opts)
		map("v", "<F12>", vim.lsp.buf.definition, opts)
		map("n", "<S-F12>", vim.lsp.buf.references, opts)
		map("v", "<S-F12>", vim.lsp.buf.references, opts)
		-- Leader-based variants
		map("n", "<leader>gd", vim.lsp.buf.definition, opts)

		map("n", "<leader>gV", function()
			vim.cmd("vsplit")
			vim.lsp.buf.definition()
		end, opts)

		map("n", "<leader>gS", function()
			vim.cmd("split")
			vim.lsp.buf.definition()
		end, opts)

		-- Go back (jumplist)
		map("n", "gb", "<C-o>", opts)
		map("n", "K", vim.lsp.buf.hover, opts)
	end,
})
