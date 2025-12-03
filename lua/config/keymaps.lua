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

----------------------------------------------------------------------
-- LSP keymaps (VS-style, but using Snacks where it makes sense)
----------------------------------------------------------------------

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

----------------------------------------------------------------------
-- Surround visual selection with [], {}, "", ''
----------------------------------------------------------------------

local function surround_visual(open, close)
	local esc = vim.api.nvim_replace_termcodes("<Esc>", false, false, true)
	local keys = "" .. open .. close .. esc .. "h" .. "p"
	keys = vim.api.nvim_replace_termcodes(keys, false, false, true)
	vim.api.nvim_feedkeys(keys, "n", true)
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
	surround_visual("(", ")")
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

----------------------------------------------------------------------
-- dotnet build -> diagnostics
----------------------------------------------------------------------

local dotnet_ns = vim.api.nvim_create_namespace("dotnet_build")

local function dotnet_is_windows()
	return package.config:sub(1, 1) == "\\"
end

local function dotnet_normalize_path(path)
	if dotnet_is_windows() then
		path = path:gsub("\\", "/")
	end
	return path
end

local function dotnet_strip_ansi(line)
	return line:gsub("\27%[[%d;]*m", "")
end

local function dotnet_parse_build_output(lines, cwd)
	cwd = cwd or vim.loop.cwd()
	local diags_by_buf = {}

	for _, raw_line in ipairs(lines) do
		local line = dotnet_strip_ansi(raw_line)

		-- Example: Program.cs(10,13): error CS1002: ; expected [MyProject]
		local file, lnum, col, level, code, msg = line:match("^(.+)%((%d+),(%d+)%)%s*:%s*(%a+)%s+([%w%d]+)%s*:%s*(.+)$")

		if file ~= nil then
			file = dotnet_normalize_path(file)

			local fullpath = vim.fn.fnamemodify(file, ":p")
			if not fullpath:match("^%a:[/\\]") and not fullpath:match("^/") then
				fullpath = dotnet_normalize_path(cwd .. "/" .. file)
			end

			local bufnr = vim.fn.bufadd(fullpath)

			local severity
			local lvl = level:lower()
			if lvl == "error" then
				severity = vim.diagnostic.severity.ERROR
			elseif lvl == "warning" then
				severity = vim.diagnostic.severity.WARN
			else
				severity = vim.diagnostic.severity.INFO
			end

			local diag = {
				lnum = tonumber(lnum) - 1,
				col = tonumber(col) - 1,
				severity = severity,
				source = "dotnet-build",
				code = code,
				message = msg,
			}

			if diags_by_buf[bufnr] == nil then
				diags_by_buf[bufnr] = {}
			end
			table.insert(diags_by_buf[bufnr], diag)
		end
	end

	vim.diagnostic.reset(dotnet_ns)

	for bufnr, diags in pairs(diags_by_buf) do
		vim.diagnostic.set(dotnet_ns, bufnr, diags, { underline = true, virtual_text = false })
	end
end

local function find_sln_dir()
	local start = vim.fn.expand("%:p:h")
	if start == nil or start == "" then
		start = vim.loop.cwd()
	end

	local matches = vim.fs.find(function(name)
		return name:match("%.sln$")
	end, { path = start, upward = true })

	local first = matches[1]
	if first == nil or first == "" then
		return nil
	end

	local dir = vim.fs.dirname(first)
	if dir == nil or dir == "" then
		return nil
	end

	return dir
end

local function dotnet_build()
	local sln_dir = find_sln_dir()
	if sln_dir ~= nil then
		vim.cmd("cd " .. vim.fn.fnameescape(sln_dir))
	end

	local cwd = vim.loop.cwd()
	local lines = {}

	vim.notify("dotnet build (cwd=" .. cwd .. ")", vim.log.levels.INFO)

	local function on_data(_, data)
		if data == nil then
			return
		end
		for _, line in ipairs(data) do
			if line ~= nil and line ~= "" then
				table.insert(lines, line)
			end
		end
	end

	local job_id = vim.fn.jobstart({ "dotnet", "build" }, {
		cwd = cwd,
		stdout_buffered = true,
		stderr_buffered = true,
		on_stdout = on_data,
		on_stderr = on_data,
		on_exit = function(_, code)
			if code ~= 0 then
				vim.notify("dotnet build failed with exit code " .. code, vim.log.levels.ERROR)
			else
				vim.notify("dotnet build succeeded", vim.log.levels.INFO)
			end

			dotnet_parse_build_output(lines, cwd)
		end,
	})

	if job_id <= 0 then
		vim.notify("Failed to start `dotnet build` job", vim.log.levels.ERROR)
	end
end

-- Keybinding: run dotnet build in cwd and populate diagnostics
vim.keymap.set("n", "<leader>mb", dotnet_build, { desc = "dotnet build (populate diagnostics)" })

-- Go to next error
vim.keymap.set("n", "<leader>sn", function()
	vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
end, { desc = "Next Error" })

-- Go to previous error
vim.keymap.set("n", "<leader>sp", function()
	vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
end, { desc = "Previous Error" })
