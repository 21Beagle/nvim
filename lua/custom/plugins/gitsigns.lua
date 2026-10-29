return {
  {
    'lewis6991/gitsigns.nvim',
    enabled = true,
    event = { 'BufReadPre', 'BufNewFile' },
    opts = require('kickstart.plugins.gitsigns')[1].opts,
    config = function(_, opts)
      require('gitsigns').setup(vim.tbl_deep_extend('force', opts or {}, {
        signcolumn = true,
        numhl = true,
        linehl = false,
        word_diff = false,

        signs = {
          add = { text = '│' },
          change = { text = '│' },
          delete = { text = '󰍵' },
          topdelete = { text = '󰍵' },
          changedelete = { text = '│' },
          untracked = { text = '┆' },
        },

        current_line_blame = false,
        update_debounce = 100,
        preview_config = { border = 'rounded' },
      }))
    end,
  },
}
