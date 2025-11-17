-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

----------------------------------------------------------------------
-- General editor keymaps
----------------------------------------------------------------------

----------------------------------------------------------------------
-- VS Code–style Ctrl+A / C / X / Y
----------------------------------------------------------------------

-- If you yanked a whole line with <C-c>, this will paste as a whole line.
map("n", "<C-v>", '"+p', opts)
map("v", "<C-v>", '"+p', opts)
-- Paste in insert mode: go to normal, paste from +, then back to insert
map("i", "<C-v>", function()
	local keys = vim.api.nvim_replace_termcodes('<Esc>"+pi', true, false, true)
	vim.api.nvim_feedkeys(keys, "n", false)
end, opts)

-- Select all
map("n", "<C-a>", "ggVG", opts)
map("v", "<C-a>", "<Esc>ggVG", opts)
map("i", "<C-a>", "<Esc>ggVG", opts)

-- Copy
-- Normal: copy current line (VS Code behaviour when nothing selected)
-- Visual: copy selection
map("n", "<C-c>", '"+yy', opts)
map("i", "<C-c>", '<Esc>"+yyi', opts)
map("v", "<C-c>", '"+y', opts)

-- Cut
-- Normal: cut current line
-- Visual: cut selection
map("i", "<C-x>", '<Esc>"+ddi', opts)
map("n", "<C-x>", '"+dd', opts)
map("v", "<C-x>", '"+d', opts)

-- Redo
map("n", "<C-y>", "<C-r>", opts)
map("v", "<C-y>", "<C-r>", opts)
map("i", "<C-y>", "<C-o><C-r>", opts)

-- Normal: undo
map("n", "<C-z>", "u", opts)

-- Insert: undo but stay in insert mode
map("i", "<C-z>", "<C-o>u", opts)

-- Visual: leave visual, undo, stay in normal
map("v", "<C-z>", "<Esc>u", opts)

-- Ctrl+S to save (normal / insert / visual)
map("n", "<C-s>", "<cmd>w<CR>", opts)
map("i", "<C-s>", "<Esc><cmd>w<CR>a", opts)
map("v", "<C-s>", "<Esc><cmd>w<CR>gv", opts)

-- Move between buffers with Alt+Left/Right
map("n", "<A-Left>", "<cmd>bprevious<CR>", opts)
map("n", "<A-Right>", "<cmd>bnext<CR>", opts)

map("n", "<C-f>", "/", opts)
map("i", "<C-f>", "<Esc>/", opts)

-- Ctrl + / : toggle line comments (like VS Code / Rider)
map("n", "<C-/>", function()
	require("Comment.api").toggle.linewise.current()
end, opts)

map("v", "<C-/>", function()
	local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
	vim.api.nvim_feedkeys(esc, "nx", false)
	require("Comment.api").toggle.linewise(vim.fn.visualmode())
end, opts)

-- Move lines up and down with Alt+Up/Down
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

-- Close buffers
map("n", "<C-q>", "<cmd>bd<CR>", opts)
map("i", "<C-q>", "<Esc><cmd>bd<CR>", opts)

-- Ctrl+| : vertical split of the current file
map("n", "<C-\\>", "<cmd>vsplit<CR>", opts)

-- Toggle file explorer sidebar (like VSCode Ctrl+B)
map("n", "<C-b>", "<cmd>Neotree toggle<CR>", opts)

-- Toggle integrated terminal (leader + ')
map("n", "<leader>'", "<cmd>ToggleTerm direction=float<CR>", opts)

-- Ctrl+P -> project files (same UI as <leader><leader>, Snacks picker)
map("n", "<C-p>", function()
	Snacks.picker.files()
end, opts)

-- "Command palette" (VS Code style) on <leader>p using Snacks commands picker
map("n", "<leader>p", function()
	Snacks.picker.commands()
end, opts)

----------------------------------------------------------------------
-- LSP keymaps (VS-style, but using Snacks where it makes sense)
----------------------------------------------------------------------

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspGoto", { clear = true }),
	callback = function(ev)
		local buf = ev.buf
		local o = { buffer = buf, silent = true, noremap = true }

		-- First, kill any existing <C-.> mappings in this buffer
		pcall(vim.keymap.del, "n", "<C-.>", { buffer = buf })
		pcall(vim.keymap.del, "v", "<C-.>", { buffer = buf })
		pcall(vim.keymap.del, "i", "<C-.>", { buffer = buf })

		------------------------------------------------------------------
		-- GOTO STUFF (Snacks)
		------------------------------------------------------------------

		-- gd / F12: definitions (Snacks picker)
		map("n", "gd", function()
			Snacks.picker.lsp_definitions()
		end, o)

		map("n", "<F12>", function()
			Snacks.picker.lsp_definitions()
		end, o)
		map("v", "<F12>", function()
			Snacks.picker.lsp_definitions()
		end, o)

		-- gi: implementations
		map("n", "gi", function()
			Snacks.picker.lsp_implementations()
		end, o)

		-- gt: type definitions
		map("n", "gt", function()
			Snacks.picker.lsp_type_definitions()
		end, o)

		-- gD: declaration (usually single location, jump direct)
		map("n", "gD", vim.lsp.buf.declaration, o)

		-- gr / Shift+F12: references
		map("n", "gr", function()
			Snacks.picker.lsp_references()
		end, o)
		map("n", "<S-F12>", function()
			Snacks.picker.lsp_references()
		end, o)
		map("v", "<S-F12>", function()
			Snacks.picker.lsp_references()
		end, o)

		------------------------------------------------------------------
		-- SPLIT VARIANTS (explicit only)
		------------------------------------------------------------------

		map("n", "gV", function()
			vim.cmd("vsplit")
			vim.lsp.buf.definition()
		end, o)

		map("n", "<leader>gS", function()
			vim.cmd("split")
			vim.lsp.buf.definition()
		end, o)

		------------------------------------------------------------------
		-- CODE ACTIONS (Ctrl+.) in normal / visual / insert
		------------------------------------------------------------------

		local function code_action()
			vim.lsp.buf.code_action()
		end

		-- Normal + visual
		map("n", "<C-.>", code_action, o)
		map("v", "<C-.>", code_action, o)

		-- Insert: stay in insert, but run code action
		map("i", "<C-.>", function()
			-- call directly; we don't need to leave insert mode for this
			vim.lsp.buf.code_action()
		end, o)

		------------------------------------------------------------------
		-- HOVER / BACK
		------------------------------------------------------------------

		-- Hover (F1) - documentation
		map("n", "<F1>", vim.lsp.buf.hover, o)

		-- Go back (jumplist)
		map("n", "gb", "<C-o>", o)
	end,
})
