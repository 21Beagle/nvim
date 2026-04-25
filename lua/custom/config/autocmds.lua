local bufferline_group = vim.api.nvim_create_augroup('custom-bufferline-state', { clear = true })

vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
  group = bufferline_group,
  callback = function(ev)
    vim.b[ev.buf].bufferline_touched = true
  end,
})

vim.api.nvim_create_autocmd('BufWritePost', {
  group = bufferline_group,
  callback = function(ev)
    vim.b[ev.buf].bufferline_touched = true
    vim.b[ev.buf].bufferline_keep = true
  end,
})

vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead', 'BufEnter' }, {
  group = vim.api.nvim_create_augroup('custom-virtual-buffers', { clear = true }),
  pattern = {
    '*__virtual.html',
    '*__virtual.cs',
    '*__virtual.*',
  },
  callback = function(event)
    vim.bo[event.buf].swapfile = false
    vim.bo[event.buf].undofile = false
    vim.bo[event.buf].backup = false
    vim.bo[event.buf].writebackup = false
    vim.bo[event.buf].bufhidden = 'wipe'
  end,
})
