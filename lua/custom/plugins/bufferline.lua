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
{
  '<leader>bo',
  function()
    local current = vim.api.nvim_get_current_buf()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if buf ~= current and vim.bo[buf].buflisted then
        vim.api.nvim_buf_delete(buf, { force = false })
      end
    end
  end,
  desc = 'Close other buffers',
},
  },
  opts = {
    options = {
      -- Order: left -> right
      sort_by = 'insert_at_end',
      custom_filter = function(bufnr, _)
        if not vim.api.nvim_buf_is_valid(bufnr) then
          return false
        end
        if vim.bo[bufnr].buftype ~= '' then
          return false
        end
        if vim.api.nvim_buf_get_name(bufnr) == '' then
          return false
        end
        if vim.bo[bufnr].modified then
          return true
        end
        if vim.bo[bufnr].buflisted == false then
          return false
        end
        if vim.b[bufnr].bufferline_keep then
          return true
        end
        if vim.b[bufnr].bufferline_touched then
          return true
        end
        return false
      end,
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
