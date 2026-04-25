-- Keybindings
-- jj to escape (works in insert + command-line + terminal modes)
-- Doesn't interfere with single "j" so list scrolling still works.

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- jk / jj to escape insert mode
map('i', 'jj', '<Esc>', opts)
map('i', 'jk', '<Esc>', opts)

-- Terminal mode: jj -> normal mode
map('t', 'jj', '<C-\\><C-n>', opts)

----------------------------------------------------------------------
-- Ctrl+Backspace in insert mode
-- Many terminals send <C-h> for Ctrl+Backspace
map('i', '<C-h>', '<C-w>', { desc = 'Delete previous word (Ctrl+Backspace)', silent = true })
map('i', '<C-BS>', '<C-w>', { desc = 'Delete previous word (Ctrl+Backspace)', silent = true })

----------------------------------------------------------------------
-- General editor keymaps

-- Select all
map('n', '<C-a>', 'ggVG', opts)

-- Redo
map('n', '<C-y>', '<C-r>', opts)
map('i', '<Esc><C-y>', '<C-r>', opts)

-- Normal: undo
map('n', '<C-z>', 'u', opts)
map('i', '<C-z>', '<Esc>u', opts)

-- Ctrl+S to save (normal / insert / visual)
map('n', '<C-s>', '<cmd>w<CR>', opts)
map('i', '<C-s>', '<Esc><cmd>w<CR>', opts)

-- VSCode-style navigation (jump list)
map('n', '<A-h>', '<C-o>', { desc = 'Jump back' })
map('n', '<A-l>', '<C-i>', { desc = 'Jump forward' })
-- Move lines up and down
map('n', '<A-Up>', ':m .-2<CR>==', opts)
map('n', '<A-k>', ':m .-2<CR>==', opts)
map('n', '<A-Down>', ':m .+1<CR>==', opts)
map('n', '<A-j>', ':m .+1<CR>==', opts)
map('v', '<A-Up>', ":m '<-2<CR>gv=gv", opts)
map('v', '<A-k>', ":m '<-2<CR>gv=gv", opts)
map('v', '<A-Down>', ":m '>+1<CR>gv=gv", opts)
map('v', '<A-j>', ":m '>+1<CR>gv=gv", opts)

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

local cs = require 'custom.config.colorscheme-picker'

vim.keymap.set('n', '<leader>cs', cs.pick, { desc = 'Pick colorscheme' })
vim.keymap.set('n', '<leader>cn', cs.next, { desc = 'Next colorscheme' })
vim.keymap.set('n', '<leader>cp', cs.prev, { desc = 'Prev colorscheme' })

-- single-char deletes
vim.keymap.set('n', 'x', '"_x', { noremap = true })
vim.keymap.set('n', 'X', '"_X', { noremap = true })

-- "substitute" (delete + insert)
--vim.keymap.set('n', 's', '"_s', { noremap = true })
--vim.keymap.set('n', 'S', '"_S', { noremap = true })
--vim.keymap.set('x', 's', '"_s', { noremap = true })
-- blink auto complete with tab

-- Keep yank register when pasting over a visual selection
vim.keymap.set('x', 'p', '"_dP', { noremap = true, silent = true })
vim.keymap.set('x', 'P', '"_dP', { noremap = true, silent = true })

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
vim.keymap.set('i', '<C-BS>', '<C-w>', { noremap = true })
vim.keymap.set('i', '<C-Del>', '<C-o>dw', { noremap = true })
vim.keymap.set('n', '<leader>R', function()
  vim.cmd 'silent! restart'
end, { noremap = true, silent = true, desc = 'Homepage' })
