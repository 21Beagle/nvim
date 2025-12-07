-- ~/.config/nvim/lua/plugins/diagnostics_view.lua
return {
	{
		"folke/snacks.nvim",
		opts = function(_, opts)
			opts.picker = opts.picker or {}

			opts.picker.diagnostics = vim.tbl_deep_extend("force", opts.picker.diagnostics or {}, {
				layout = {
					preset = "vertical",
					width = 0.98,
					height = 0.92,
					min_width = 120,
				},

				format = function(item)
					local path = item.file or (item.buf and vim.api.nvim_buf_get_name(item.buf)) or ""
					local base = vim.fn.fnamemodify(path, ":t")
					local lnum = (item.lnum or 0) + 1
					local col = (item.col or 0) + 1
					local msg = (item.text or ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
					local left = string.format("%s:%d:%d", base, lnum, col)
					return string.format("%-28s %s", left, msg)
				end,

				preview = function(ctx)
					local win = ctx.win
					local item = ctx.item
					if not win or not vim.api.nvim_win_is_valid(win) or not item then
						return
					end

					local msg_buf = vim.api.nvim_create_buf(false, true)
					vim.bo[msg_buf].buftype = "nofile"
					vim.bo[msg_buf].bufhidden = "wipe"
					vim.bo[msg_buf].swapfile = false
					vim.bo[msg_buf].filetype = "markdown"

					local msg = item.text or ""
					if item.code and item.code ~= "" then
						msg = string.format("**%s**\n\n%s", item.code, msg)
					end
					vim.api.nvim_buf_set_lines(msg_buf, 0, -1, false, vim.split(msg, "\n", { plain = true }))

					vim.api.nvim_win_set_buf(win, msg_buf)
					vim.wo[win].wrap = true

					vim.api.nvim_win_call(win, function()
						vim.cmd("belowright split")
					end)

					local code_win = vim.api.nvim_get_current_win()

					if vim.api.nvim_win_is_valid(win) then
						vim.api.nvim_win_set_height(win, math.max(6, math.floor(vim.o.lines * 0.18)))
					end

					local path = item.file or (item.buf and vim.api.nvim_buf_get_name(item.buf)) or ""
					if path == "" then
						return
					end

					local code_buf = vim.fn.bufadd(path)
					vim.fn.bufload(code_buf)

					vim.api.nvim_win_set_buf(code_win, code_buf)
					vim.wo[code_win].wrap = false
					vim.wo[code_win].number = true
					vim.wo[code_win].relativenumber = false
					vim.wo[code_win].cursorline = true

					local lnum = (item.lnum or 0) + 1
					local col = (item.col or 0) + 1
					pcall(vim.api.nvim_win_set_cursor, code_win, { lnum, math.max(col - 1, 0) })
					vim.api.nvim_win_call(code_win, function()
						vim.cmd("normal! zz")
					end)
				end,
			})

			return opts
		end,
		keys = {
			{
				"<leader>sd",
				function()
					-- IMPORTANT: call the Snacks global entrypoint (matches LazyVim usage)
					Snacks.picker.diagnostics()
				end,
				desc = "Diagnostics (custom view)",
			},
		},
	},
}
