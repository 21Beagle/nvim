return {
  'petertriho/nvim-scrollbar',
  event = 'VeryLazy',
  opts = {
    show = true,
    show_in_active_only = false,
    set_highlights = true,
    folds = 1000,
    max_lines = false,
    handle = {
      text = ' ',
      color = '#5c6370',
      hide_if_all_visible = false,
    },
    marks = {
      Search = { color = '#e5c07b' },
      Error = { color = '#e06c75' },
      Warn = { color = '#d19a66' },
      Info = { color = '#61afef' },
      Hint = { color = '#56b6c2' },
      Misc = { color = '#c678dd' },
    },
    excluded_filetypes = {
      'prompt',
      'TelescopePrompt',
      'noice',
    },
  },
}
