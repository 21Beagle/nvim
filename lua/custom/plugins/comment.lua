return {
  'numToStr/Comment.nvim',
  keys = {
    {
      '<C-_>',
      function()
        require('Comment.api').toggle.linewise.current()
      end,
      mode = 'n',
      desc = 'Toggle comment (line)',
    },
    {
      '<C-_>',
      function()
        require('Comment.api').toggle.linewise.current()
      end,
      mode = 'i',
      desc = 'Toggle comment (line)',
    },
    {
      '<C-_>',
      function()
        local esc = vim.api.nvim_replace_termcodes('<ESC>', true, false, true)
        vim.api.nvim_feedkeys(esc, 'nx', false)
        require('Comment.api').toggle.linewise(vim.fn.visualmode())
      end,
      mode = 'v',
      desc = 'Toggle comment (selection)',
    },
  },
  config = function()
    require('Comment').setup {
      padding = true,
      sticky = true,
      ignore = '^$',
      toggler = {
        line = '<C-_>',
        block = nil,
      },
      opleader = {
        line = '<C-_>',
        block = nil,
      },
    }
  end,
}
