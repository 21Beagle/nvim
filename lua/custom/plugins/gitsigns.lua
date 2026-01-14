return {
  {
    'lewis6991/gitsigns.nvim',
    enabled = true,
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      require('gitsigns').setup {
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
      }
    end,
  },
}
