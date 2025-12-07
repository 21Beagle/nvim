-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- jk / jj to escape insert mode
map("i", "jj", "<Esc>", opts)
map("i", "jk", "<Esc>", opts)

----------------------------------------------------------------------
-- Ctrl+Backspace in insert mode
----------------------------------------------------------------------

-- Many terminals send <C-h> for Ctrl+Backspace
vim.keymap.set("i", "<C-h>", "<C-w>", { desc = "Delete previous word (Ctrl+Backspace)", silent = true })

-- Some send <C-BS>
vim.keymap.set("i", "<C-BS>", "<C-w>", { desc = "Delete previous word (Ctrl+Backspace)", silent = true })

----------------------------------------------------------------------
-- General editor keymaps
----------------------------------------------------------------------

map("n", "<CR>", "o<Esc>", opts)
map("n", "<S-CR>", "O<Esc>", opts)

-- Select all
map("n", "<C-a>", "ggVG", opts)

-- Redo
map("n", "<C-y>", "<C-r>", opts)

-- Normal: undo
map("n", "<C-z>", "u", opts)

-- Ctrl+S to save (normal / insert / visual)
map("n", "<C-s>", "<cmd>w<CR>", opts)

-- Move lines up and down with Alt+Up/Down
map("n", "<A-Up>", ":m .-2<CR>==", opts)
map("n", "<A-Down>", ":m .+1<CR>==", opts)
map("v", "<A-Up>", ":m '<-2<CR>gv=gv", opts)
map("v", "<A-Down>", ":m '>+1<CR>gv=gv", opts)

map("n", "<C-\\>", "<cmd>vsplit<CR>", opts)

-- Toggle integrated terminal (leader + ')
map("n", "<leader>'", "<cmd>ToggleTerm direction=float<CR>", opts)

-- "Command palette" (VS Code style) on <leader>p using Snacks commands picker
map("n", "<leader>p", function()
	Snacks.picker.commands()
end, opts)

----------------------------------------------------------------------
-- Comment toggling
----------------------------------------------------------------------

-- Normal mode: toggle comment on current line
vim.keymap.set("n", "<leader>c/", function()
	require("Comment.api").toggle.linewise.current()
end, { desc = "Comment line" })

-- Visual mode: toggle comment on selection
vim.keymap.set("v", "<leader>c/", function()
	local esc = vim.api.nvim_replace_termcodes("<Esc>", false, false, true)
	vim.api.nvim_feedkeys(esc, "nx", true)
	require("Comment.api").toggle.linewise(vim.fn.visualmode())
end, { desc = "Comment selection" })

-- Go to next error
vim.keymap.set("n", "<leader>sn", function()
	vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
end, { desc = "Next Error" })

-- Go to previous error
vim.keymap.set("n", "<leader>sp", function()
	vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
end, { desc = "Previous Error" })
