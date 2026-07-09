return {
  'j-hui/fidget.nvim',
  event = 'LspAttach',
  opts = {
    progress = {
      display = {
        render_limit = 6,
        done_ttl = 1,
        progress_ttl = math.huge,
      },
    },
    notification = {
      override_vim_notify = true,
    },
  },
}
