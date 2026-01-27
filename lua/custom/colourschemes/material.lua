return {
  'marko-cerovac/material.nvim',
  priority = 1000,
  config = function()
    require('material').setup {
      contrast = {
        terminal = false,
        sidebars = false,
        floating_windows = false,
        cursor_line = false,
        lsp_virtual_text = false,
        non_current_windows = false,
        filetypes = {},
      },
      styles = {
        comments = { italic = true },
        strings = { italic = false },
        keywords = { italic = false },
        functions = { bold = true },
        variables = {},
        operators = {},
        types = {},
      },
      plugins = {
        'nvim-cmp',
        'nvim-tree',
        'telescope',
        'which-key',
        'gitsigns',
        'nvim-web-devicons',
      },
      disable = {
        colored_cursor = false,
        borders = false,
        background = false,
        term_colors = false,
        eob_lines = false,
      },
      high_visibility = {
        lighter = false,
        darker = false,
      },
      lualine_style = 'default',
      async_loading = true,
      custom_colors = nil,
      custom_highlights = {},
    }
  end,
}
