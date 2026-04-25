-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlight' })

-- Diagnostic keymaps

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>', { desc = 'Disabled: use h' })
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>', { desc = 'Disabled: use l' })
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>', { desc = 'Disabled: use k' })
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>', { desc = 'Disabled: use j' })
vim.keymap.set('n', '<leader>wq', function()
  vim.cmd 'vsplit'
end, { desc = 'Split window vertically', silent = true })

vim.keymap.set('n', '<leader>we', function()
  vim.cmd 'split'
end, { desc = 'Split window horizontally', silent = true })

vim.keymap.set('n', '<leader>wo', '<cmd>only<CR>', { desc = 'Close other windows' })
