local rainbow_groups = {
  'RainbowDelimiterRed',
  'RainbowDelimiterYellow',
  'RainbowDelimiterBlue',
  'RainbowDelimiterOrange',
  'RainbowDelimiterGreen',
  'RainbowDelimiterViolet',
  'RainbowDelimiterCyan',
}

local rainbow_colors_gui = {
  '#E06C75',
  '#E5C07B',
  '#61AFEF',
  '#D19A66',
  '#98C379',
  '#C678DD',
  '#56B6C2',
}

local rainbow_colors_hex = {
  0xE06C75,
  0xE5C07B,
  0x61AFEF,
  0xD19A66,
  0x98C379,
  0xC678DD,
  0x56B6C2,
}

return {
  -- Rainbow brackets
  {
    'HiPhish/rainbow-delimiters.nvim',
    event = 'BufReadPost',
    config = function()
      local hooks = require 'ibl.hooks'

      -- define highlight groups once, reset on colorscheme change
      hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
        for i, group in ipairs(rainbow_groups) do
          vim.api.nvim_set_hl(0, group, { fg = rainbow_colors_gui[i] })
        end

        vim.api.nvim_set_hl(0, 'IblScope', { fg = '#5C6370' })
      end)

      vim.g.rainbow_delimiters = {
        strategy = {
          [''] = require('rainbow-delimiters').strategy.global,
          vim = require('rainbow-delimiters').strategy['local'],
        },
        query = {
          [''] = 'rainbow-delimiters',
          lua = 'rainbow-blocks',
        },
        highlight = rainbow_groups,
      }
    end,
  },

  -- Rainbow indentation + active scope
  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = {
      'TheGLander/indent-rainbowline.nvim',
    },
    opts = function(_, opts)
      local rainbow = require 'indent-rainbowline'

      opts.indent = {
        char = '▏',
        tab_char = '▏',
      }

      opts.scope = {
        enabled = true,
        show_exact_scope = true, -- ⭐ only current scope
        show_start = true,
        show_end = true,
        highlight = 'IblScope',
      }

      opts.exclude = {
        filetypes = {
          'help',
          'lazy',
          'mason',
          'notify',
          'terminal',
          'dashboard',
          'NvimTree',
          'neo-tree',
        },
      }

      return rainbow.make_opts(opts, {
        colors = rainbow_colors_hex,
      })
    end,
  },
}
