return {
  'akinsho/bufferline.nvim',
  version = '*',
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  event = 'VimEnter',
  keys = {
    { '[b', '<cmd>BufferLineCyclePrev<CR>', desc = 'Previous buffer' },
    { ']b', '<cmd>BufferLineCycleNext<CR>', desc = 'Next buffer' },
    { '<leader>bd', '<cmd>bdelete<CR>', desc = 'Delete buffer' },
  },
  opts = {
    options = {
      -- Order: left -> right
      sort_by = 'insert_at_end',

      -- Click behavior
      left_mouse_command = 'buffer %d',
      middle_mouse_command = 'bdelete %d',
      right_mouse_command = 'bdelete %d',

      -- Diagnostics
      diagnostics = 'nvim_lsp',

      -- Visual sizing (THIS is where size comes from)
      buffer_close_icon = '󰅖',
      modified_icon = '●',
      close_icon = '',

      -- Horizontal size controls
      max_name_length = 30,
      max_prefix_length = 15,
      truncate_names = false,

      -- Padding = perceived size
      padding = 6, -- default is 1
      minimum_padding = 6, -- ensures tabs don't collapse

      -- Icons add vertical *perception*
      show_buffer_icons = true,
      show_buffer_close_icons = true,
      show_close_icon = false,

      -- Sidebar offset
      offsets = {
        {
          filetype = 'neo-tree',
          text = ' Explorer ',
          highlight = 'Directory',
          text_align = 'left',
          separator = true,
        },
      },

      -- Separator affects perceived bulk
      separator_style = 'thick',
    },
  },
}
