return {
  'akinsho/bufferline.nvim',
  version = '*',
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  event = 'VimEnter',
  keys = {
    { '<S-h>', '<cmd>BufferLineCyclePrev<CR>', desc = 'Previous buffer' },
    { '<S-l>', '<cmd>BufferLineCycleNext<CR>', desc = 'Next buffer' },
    { '<leader>bd', '<cmd>bdelete<CR>', desc = 'Delete buffer' },
  },
  opts = {
    options = {
      -- New buffers append to the right (left -> right like you asked)
      sort_by = 'insert_at_end',

      -- Click behavior
      left_mouse_command = 'buffer %d',
      middle_mouse_command = 'bdelete %d',
      right_mouse_command = 'bdelete %d',

      -- Nice defaults
      diagnostics = 'nvim_lsp',
      show_buffer_close_icons = true,
      show_close_icon = false,
      offsets = {
        {
          filetype = 'neo-tree',
          text = 'Explorer',
          highlight = 'Directory',
          text_align = 'left',
          separator = true,
        },
      },
      separator_style = 'slant',
    },
  },
}
