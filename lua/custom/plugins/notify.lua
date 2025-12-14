return {
  {
    'rcarriga/nvim-notify',
    event = 'VimEnter',
    opts = {
      timeout = 5000,
      stages = 'fade_in_slide_out',
    },
    config = function(_, opts)
      local notify = require 'notify'
      notify.setup(opts)
      vim.notify = notify
    end,
  },
}
