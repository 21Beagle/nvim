-- Keybindings
-- jj to escape (works in insert + command-line + terminal modes)
-- Doesn't interfere with single "j" so list scrolling still works.

local map = vim.keymap.set

-- jk / jj to escape insert mode
map('i', 'jj', '<Esc>', { noremap = true, silent = true, desc = 'Exit insert mode' })
map('i', 'jk', '<Esc>', { noremap = true, silent = true, desc = 'Exit insert mode' })

-- Terminal mode: jj -> normal mode
map('t', 'jj', '<C-\\><C-n>', { noremap = true, silent = true, desc = 'Exit terminal mode' })

----------------------------------------------------------------------
-- Ctrl+Backspace in insert mode
-- Many terminals send <C-h> for Ctrl+Backspace
map('i', '<C-h>', '<C-w>', { desc = 'Delete previous word (Ctrl+Backspace)', silent = true })
map('i', '<C-BS>', '<C-w>', { desc = 'Delete previous word (Ctrl+Backspace)', silent = true })

----------------------------------------------------------------------
-- General editor keymaps

-- Select all
map('n', '<C-a>', 'ggVG', { noremap = true, silent = true, desc = 'Select all' })

-- Redo
map('n', '<C-y>', '<C-r>', { noremap = true, silent = true, desc = 'Redo' })
map('i', '<Esc><C-y>', '<C-r>', { noremap = true, silent = true, desc = 'Redo' })

-- Normal: undo
map('n', '<C-z>', 'u', { noremap = true, silent = true, desc = 'Undo' })
map('i', '<C-z>', '<Esc>u', { noremap = true, silent = true, desc = 'Undo' })

-- Ctrl+S to save (normal / insert / visual)
map('n', '<C-s>', '<cmd>w<CR>', { noremap = true, silent = true, desc = 'Save file' })
map('i', '<C-s>', '<Esc><cmd>w<CR>', { noremap = true, silent = true, desc = 'Save file' })

-- VSCode-style navigation (jump list)
map('n', '<A-h>', '<C-o>', { desc = 'Jump back' })
map('n', '<A-l>', '<C-i>', { desc = 'Jump forward' })
-- Move lines up and down
map('n', '<A-Up>', ':m .-2<CR>==', { noremap = true, silent = true, desc = 'Move line up' })
map('n', '<A-k>', ':m .-2<CR>==', { noremap = true, silent = true, desc = 'Move line up' })
map('n', '<A-Down>', ':m .+1<CR>==', { noremap = true, silent = true, desc = 'Move line down' })
map('n', '<A-j>', ':m .+1<CR>==', { noremap = true, silent = true, desc = 'Move line down' })
map('v', '<A-Up>', ":m '<-2<CR>gv=gv", { noremap = true, silent = true, desc = 'Move selection up' })
map('v', '<A-k>', ":m '<-2<CR>gv=gv", { noremap = true, silent = true, desc = 'Move selection up' })
map('v', '<A-Down>', ":m '>+1<CR>gv=gv", { noremap = true, silent = true, desc = 'Move selection down' })
map('v', '<A-j>', ":m '>+1<CR>gv=gv", { noremap = true, silent = true, desc = 'Move selection down' })

-- Window navigation (moved off Shift so Shift can be buffers)
map('n', '<leader>wh', '<C-w><C-h>', { desc = 'Move focus to the left window' })
map('n', '<leader>wl', '<C-w><C-l>', { desc = 'Move focus to the right window' })
map('n', '<leader>wj', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
map('n', '<leader>wk', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Resize splits with Ctrl+hjkl (spam it)
map('n', '<C-h>', '<cmd>vertical resize -5<CR>', { noremap = true, silent = true, desc = 'Resize split left' })
map('n', '<C-l>', '<cmd>vertical resize +5<CR>', { noremap = true, silent = true, desc = 'Resize split right' })
map('n', '<C-j>', '<cmd>resize -2<CR>', { noremap = true, silent = true, desc = 'Resize split down' })
map('n', '<C-k>', '<cmd>resize +2<CR>', { noremap = true, silent = true, desc = 'Resize split up' })

-- Quickfix and location list navigation
map('n', '<leader>qo', '<cmd>copen<CR>', { noremap = true, silent = true, desc = '[Q]uickfix [O]pen' })
map('n', '<leader>qc', '<cmd>cclose<CR>', { noremap = true, silent = true, desc = '[Q]uickfix [C]lose' })
map('n', '<leader>qn', '<cmd>cnext<CR>', { noremap = true, silent = true, desc = '[Q]uickfix [N]ext item' })
map('n', '<leader>qp', '<cmd>cprevious<CR>', { noremap = true, silent = true, desc = '[Q]uickfix [P]revious item' })
map('n', '<leader>ql', '<cmd>lopen<CR>', { noremap = true, silent = true, desc = '[Q]uickfix [L]ocation list open' })
map('n', '<leader>qL', '<cmd>lclose<CR>', { noremap = true, silent = true, desc = '[Q]uickfix [L]ocation list close' })
map('n', ']q', '<cmd>cnext<CR>', { noremap = true, silent = true, desc = 'Next quickfix item' })
map('n', '[q', '<cmd>cprevious<CR>', { noremap = true, silent = true, desc = 'Previous quickfix item' })
map('n', ']l', '<cmd>lnext<CR>', { noremap = true, silent = true, desc = 'Next location-list item' })
map('n', '[l', '<cmd>lprevious<CR>', { noremap = true, silent = true, desc = 'Previous location-list item' })

local cs = require 'custom.config.colorscheme-picker'

vim.keymap.set('n', '<leader>uc', cs.pick, { desc = '[U]I [C]olorscheme picker' })
vim.keymap.set('n', '<leader>un', cs.next, { desc = '[U]I [N]ext colorscheme' })
vim.keymap.set('n', '<leader>up', cs.prev, { desc = '[U]I [P]revious colorscheme' })

-- single-char deletes
vim.keymap.set('n', 'x', '"_x', { noremap = true, desc = 'Delete character without yanking' })
vim.keymap.set('n', 'X', '"_X', { noremap = true, desc = 'Delete previous character without yanking' })

-- "substitute" (delete + insert)
--vim.keymap.set('n', 's', '"_s', { noremap = true })
--vim.keymap.set('n', 'S', '"_S', { noremap = true })
--vim.keymap.set('x', 's', '"_s', { noremap = true })
-- blink auto complete with tab

-- Keep yank register when pasting over a visual selection
vim.keymap.set('x', 'p', '"_dP', { noremap = true, silent = true, desc = 'Paste without replacing register' })
vim.keymap.set('x', 'P', '"_dP', { noremap = true, silent = true, desc = 'Paste without replacing register' })

vim.keymap.set('i', '<Tab>', function()
  local ok, blink = pcall(require, 'blink.cmp')
  if ok and blink.is_visible() and (vim.fn.mode() == 'i' or vim.fn.mode() == 'ic') then
    blink.select_next()
    return
  end

  local ok_snip, luasnip = pcall(require, 'luasnip')
  if ok_snip and luasnip.expand_or_jumpable() then
    luasnip.expand_or_jump()
    return
  end

  local tab = vim.api.nvim_replace_termcodes('<Tab>', true, false, true)
  vim.api.nvim_feedkeys(tab, 'n', false)
end, { noremap = true, silent = true, desc = 'Tab: completion next / snippet / tab' })

vim.keymap.set('i', '<S-Tab>', function()
  local ok, blink = pcall(require, 'blink.cmp')
  if ok and blink.is_visible() and (vim.fn.mode() == 'i' or vim.fn.mode() == 'ic') then
    blink.select_prev()
    return
  end

  local ok_snip, luasnip = pcall(require, 'luasnip')
  if ok_snip and luasnip.jumpable(-1) then
    luasnip.jump(-1)
    return
  end

  local stab = vim.api.nvim_replace_termcodes('<S-Tab>', true, false, true)
  vim.api.nvim_feedkeys(stab, 'n', false)
end, { noremap = true, silent = true, desc = 'S-Tab: completion prev / snippet / fallback' })

-- Bottom terminal toggle (single instance)
do
  local term = {
    bufnr = nil,
    height = 12,
  }

  local function is_valid_buf(bufnr)
    return bufnr ~= nil and vim.api.nvim_buf_is_valid(bufnr)
  end

  local function buf_winid(bufnr)
    local winid = vim.fn.bufwinid(bufnr)
    if winid == nil or winid == -1 then
      return nil
    end
    return winid
  end

  local function enter_terminal_mode()
    pcall(vim.cmd, 'startinsert')
  end

  local function open_terminal_window()
    vim.cmd('botright ' .. term.height .. 'split')
    vim.wo.winfixheight = true

    if is_valid_buf(term.bufnr) then
      vim.api.nvim_set_current_buf(term.bufnr)
      enter_terminal_mode()
      return
    end

    vim.cmd 'terminal'
    term.bufnr = vim.api.nvim_get_current_buf()

    -- keep terminal buffer around when window is closed
    vim.bo[term.bufnr].buflisted = false
    vim.bo[term.bufnr].bufhidden = 'hide'
    vim.bo[term.bufnr].swapfile = false

    enter_terminal_mode()
  end

  local function toggle_bottom_terminal()
    if not is_valid_buf(term.bufnr) then
      term.bufnr = nil
      open_terminal_window()
      return
    end

    local winid = buf_winid(term.bufnr)
    if winid == nil then
      -- buffer exists but window is closed -> reopen
      open_terminal_window()
      return
    end

    if vim.api.nvim_get_current_win() == winid then
      -- focused -> hide
      pcall(vim.cmd, 'stopinsert')
      vim.api.nvim_win_close(winid, true)
      return
    end

    -- open + not focused -> focus
    vim.api.nvim_set_current_win(winid)
    enter_terminal_mode()
  end

  -- keybinding UNCHANGED
  map({ 'n', 't' }, '<C-t>', function()
    toggle_bottom_terminal()
  end, { noremap = true, silent = true, desc = 'Toggle bottom terminal' })

  -- marks stay where YOU put them
  map('n', "<leader>'", function()
    require('telescope.builtin').marks()
  end, { noremap = true, silent = true, desc = 'Marks' })
end
vim.keymap.set('i', '<C-Del>', '<C-o>dw', { noremap = true, desc = 'Delete next word (Ctrl+Delete)' })
vim.keymap.set('n', '<leader>R', function()
  vim.cmd 'silent! restart'
end, { noremap = true, silent = true, desc = 'Restart Neovim' })

-- incremental selection treesitter/lsp
vim.keymap.set({ "n", "x", "o" }, "<A-o>", function()
	if vim.treesitter.get_parser(nil, nil, { error = false }) then
		require("vim.treesitter._select").select_parent(vim.v.count1)
	else
		vim.lsp.buf.selection_range(vim.v.count1)
	end
end, { desc = "Select parent treesitter node or outer incremental lsp selections" })

vim.keymap.set({ "n", "x", "o" }, "<A-i>", function()
	if vim.treesitter.get_parser(nil, nil, { error = false }) then
		require("vim.treesitter._select").select_child(vim.v.count1)
	else
		vim.lsp.buf.selection_range(-vim.v.count1)
	end
end, { desc = "Select child treesitter node or inner incremental lsp selections" })

-- Undotree toggle
vim.cmd("packadd nvim.undotree")
vim.keymap.set("n", "<leader>ut", function()
	require("undotree").open({
		command = math.floor(vim.api.nvim_win_get_width(0) / 3) .. "vnew",
	})
end, { desc = "[U]ndotree toggle" })
