return {
  {
    'folke/noice.nvim',
    event = 'VimEnter',
    dependencies = {
      'MunifTanjim/nui.nvim',
      'rcarriga/nvim-notify',
    },
    opts = {
      messages = {
        enabled = true,
        view = 'notify',
        view_error = 'notify',
        view_warn = 'notify',
        view_history = 'messages',
      },
      notify = {
        enabled = true,
      },
      popupmenu = {
        enabled = true,
      },
      lsp = {
        progress = { enabled = true },
        hover = { enabled = true },
        signature = { enabled = true },
        message = { enabled = true },
      },
      presets = {
        command_palette = true,
        long_message_to_split = true,
        inc_rename = true,
        lsp_doc_border = true,
      },
      cmdline = {
        enabled = true, -- enable Noice cmdline UI

        view = 'cmdline', -- how the cmdline is shown
        -- other options: "cmdline", "cmdline_popup", "cmdline_popup_center"
      },
    },
    keys = {
      { '<leader>nl', '<cmd>Noice last<CR>', desc = 'Last message' },
      { '<leader>nh', '<cmd>Noice history<CR>', desc = 'Message history' },
      { '<leader>nd', '<cmd>Noice dismiss<CR>', desc = 'Dismiss all' },
    },
  },
}
