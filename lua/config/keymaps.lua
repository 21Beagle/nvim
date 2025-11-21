-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

----------------------------------------------------------------------
-- General editor keymaps
----------------------------------------------------------------------

-- Select all
map("n", "<C-a>", "ggVG", opts)

-- Redo
map("n", "<C-y>", "<C-r>", opts)

-- Normal: undo
map("n", "<C-z>", "u", opts)

-- Ctrl+S to save (normal / insert / visual)
map("n", "<C-s>", "<cmd>w<CR>", opts)

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

-- Ctrl+| : vertical split of the current file
map("n", "<C-\\>", "<cmd>vsplit<CR>", opts)

-- Toggle integrated terminal (leader + ')
map("n", "<leader>'", "<cmd>ToggleTerm direction=float<CR>", opts)

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

		map("n", "<F2>", vim.lsp.buf.rename, o)
	end,
})

-- Surround visual selection with [], {}, "", ''
local function surround_visual(open, close)
	-- change selection to open+close, then paste original text between them
	local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
	local keys = "" .. open .. close .. esc .. "h" .. "p"
	keys = vim.api.nvim_replace_termcodes(keys, true, false, true)
	vim.api.nvim_feedkeys(keys, "n", false)
end

-- []  (both [ and ] do the same thing in visual mode)
map("v", "[", function()
	surround_visual("[", "]")
end, opts)

map("v", "]", function()
	surround_visual("[", "]")
end, opts)

map("v", "(", function()
	surround_visual("(", ")")
end, opts)

map("v", ")", function()
	surround_visual(")", ")")
end, opts)

-- {}
map("v", "{", function()
	surround_visual("{", "}")
end, opts)

map("v", "}", function()
	surround_visual("{", "}")
end, opts)

-- ""
map("v", '"', function()
	surround_visual('"', '"')
end, opts)

-- ''
map("v", "'", function()
	surround_visual("'", "'")
end, opts)
