local map = vim.keymap.set

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspGoto", { clear = false }),
	callback = function(ev)
		local buf = ev.buf
		local o = { buffer = buf, silent = false, noremap = true }

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
			vim.lsp.buf.code_action()
		end, o)

		------------------------------------------------------------------
		-- HOVER / BACK / RENAME
		------------------------------------------------------------------

		-- Hover (F1) - documentation
		map("n", "<F1>", vim.lsp.buf.hover, o)

		-- Go back (jumplist)
		map("n", "gb", "<C-o>", o)

		map("n", "<F2>", vim.lsp.buf.rename, o)
	end,
})
