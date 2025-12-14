return {
  {
    'HiPhish/rainbow-delimiters.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
      local rainbow_delimiters = require 'rainbow-delimiters'

      vim.g.rainbow_delimiters = {
        strategy = {
          [''] = rainbow_delimiters.strategy['global'],
          vim = rainbow_delimiters.strategy['local'],
        },
        query = {
          [''] = 'rainbow-delimiters',
          lua = 'rainbow-blocks',
        },
        highlight = {
          'RainbowDelimiterRed',
          'RainbowDelimiterYellow',
          'RainbowDelimiterBlue',
          'RainbowDelimiterOrange',
          'RainbowDelimiterGreen',
          'RainbowDelimiterViolet',
          'RainbowDelimiterCyan',
        },
      }
    end,
  },

  {
    'echasnovski/mini.indentscope',
    version = false,
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
      require('mini.indentscope').setup {
        symbol = '│',
        options = { try_as_border = true },
        draw = {
          animation = function()
            return 0
          end,
        },
      }

      -- MUST match rainbow-delimiters order EXACTLY
      local rainbow = {
        'RainbowDelimiterRed',
        'RainbowDelimiterYellow',
        'RainbowDelimiterBlue',
        'RainbowDelimiterOrange',
        'RainbowDelimiterGreen',
        'RainbowDelimiterViolet',
        'RainbowDelimiterCyan',
      }

      local function hl_exists(name)
        local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = true })
        if ok == false then
          return false
        end
        if hl == nil then
          return false
        end
        return true
      end

      local function syn_hl_at(line, col)
        local id = vim.fn.synID(line, col, true)
        local name = vim.fn.synIDattr(id, 'name')
        if name == nil then
          name = ''
        end
        if name == '' then
          local trans = vim.fn.synIDtrans(id)
          name = vim.fn.synIDattr(trans, 'name')
          if name == nil then
            name = ''
          end
        end
        return name
      end

      local function is_open_delim(ch)
        return ch == '(' or ch == '[' or ch == '{' or ch == '<'
      end

      local function get_shiftwidth()
        local sw = vim.bo.shiftwidth
        if sw == nil or sw == 0 then
          sw = vim.bo.tabstop
        end
        if sw == nil or sw == 0 then
          sw = 2
        end
        return sw
      end

      local function find_nearest_opening_rainbow_hl()
        local pos = vim.api.nvim_win_get_cursor(0)
        local cur_line = pos[1]
        local cur_col = pos[2] + 1

        local min_line = cur_line - 250
        if min_line < 1 then
          min_line = 1
        end

        for l = cur_line, min_line, -1 do
          local text = vim.api.nvim_buf_get_lines(0, l - 1, l, false)[1]
          if text ~= nil then
            local start_col = #text
            if l == cur_line then
              start_col = cur_col
              if start_col > #text then
                start_col = #text
              end
            end

            for c = start_col, 1, -1 do
              local ch = text:sub(c, c)
              if is_open_delim(ch) then
                local hl = syn_hl_at(l, c)
                if hl:find('RainbowDelimiter', 1, true) == 1 then
                  return hl
                end
              end
            end
          end
        end

        return nil
      end

      local function update_scope_colour()
        -- Prefer exact bracket colour (best match).
        local hl = find_nearest_opening_rainbow_hl()

        -- Fallback: if we didn't find a bracket nearby, use indent level cycling
        -- with the SAME rainbow order.
        if hl == nil or hl == '' then
          local line = vim.api.nvim_win_get_cursor(0)[1]
          local indent = vim.fn.indent(line)
          local sw = get_shiftwidth()
          local level = math.floor(indent / sw) + 1
          local idx = ((level - 1) % #rainbow) + 1
          hl = rainbow[idx]
        end

        if hl_exists(hl) == false then
          hl = 'Comment'
        end

        vim.api.nvim_set_hl(0, 'MiniIndentscopeSymbol', { link = hl, nocombine = true })
        vim.api.nvim_set_hl(0, 'MiniIndentscopeSymbolOff', { link = hl, nocombine = true })
      end

      local aug = vim.api.nvim_create_augroup('MiniIndentScopeRainbowFromBrackets', { clear = true })
      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI', 'BufEnter', 'ColorScheme' }, {
        group = aug,
        callback = update_scope_colour,
      })

      update_scope_colour()
    end,
  },

  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = function()
      local dim = {
        'IblIndentRainbowRed',
        'IblIndentRainbowYellow',
        'IblIndentRainbowBlue',
        'IblIndentRainbowOrange',
        'IblIndentRainbowGreen',
        'IblIndentRainbowViolet',
        'IblIndentRainbowCyan',
      }

      return {
        indent = {
          char = '│',
          highlight = dim,
        },

        scope = {
          enabled = false,
        },

        whitespace = {
          remove_blankline_trail = true,
        },

        exclude = {
          filetypes = {
            'neo-tree',
            'neo-tree-popup',
            'help',
            'terminal',
            'lazy',
            'mason',
            'TelescopePrompt',
            'TelescopeResults',
          },
          buftypes = { 'nofile', 'terminal', 'prompt', 'quickfix' },
        },
      }
    end,
    config = function(_, opts)
      local function clamp(v)
        if v < 0 then
          return 0
        end
        if v > 255 then
          return 255
        end
        return v
      end

      local function hex_to_rgb(hex)
        local r = math.floor(hex / 65536) % 256
        local g = math.floor(hex / 256) % 256
        local b = hex % 256
        return r, g, b
      end

      local function rgb_to_hex(r, g, b)
        return (clamp(r) * 65536) + (clamp(g) * 256) + clamp(b)
      end

      local function blend(fg, bg, alpha)
        local fr, fg2, fb = hex_to_rgb(fg)
        local br, bg2, bb = hex_to_rgb(bg)
        local r = math.floor((alpha * fr) + ((1 - alpha) * br) + 0.5)
        local g = math.floor((alpha * fg2) + ((1 - alpha) * bg2) + 0.5)
        local b = math.floor((alpha * fb) + ((1 - alpha) * bb) + 0.5)
        return rgb_to_hex(r, g, b)
      end

      local function hl_exists(name)
        local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
        if ok == false then
          return false
        end
        if hl == nil then
          return false
        end
        return true
      end

      local function ensure_dim_groups()
        local rainbow = {
          'RainbowDelimiterRed',
          'RainbowDelimiterYellow',
          'RainbowDelimiterBlue',
          'RainbowDelimiterOrange',
          'RainbowDelimiterGreen',
          'RainbowDelimiterViolet',
          'RainbowDelimiterCyan',
        }

        local dim = {
          'IblIndentRainbowRed',
          'IblIndentRainbowYellow',
          'IblIndentRainbowBlue',
          'IblIndentRainbowOrange',
          'IblIndentRainbowGreen',
          'IblIndentRainbowViolet',
          'IblIndentRainbowCyan',
        }

        local normal = vim.api.nvim_get_hl(0, { name = 'Normal', link = false })
        local bg = normal.bg
        if bg == nil then
          bg = 0x000000
        end

        local alpha = 0.28

        for i = 1, #dim do
          local src_name = rainbow[i]
          if hl_exists(src_name) == false then
            vim.api.nvim_set_hl(0, dim[i], { link = 'Comment', nocombine = true })
          else
            local src = vim.api.nvim_get_hl(0, { name = src_name, link = true })
            local fg = src.fg
            if fg == nil then
              vim.api.nvim_set_hl(0, dim[i], { link = src_name, nocombine = true })
            else
              vim.api.nvim_set_hl(0, dim[i], {
                fg = blend(fg, bg, alpha),
                nocombine = true,
              })
            end
          end
        end
      end

      ensure_dim_groups()

      local aug = vim.api.nvim_create_augroup('IblRainbowDimHighlights', { clear = true })
      vim.api.nvim_create_autocmd('ColorScheme', {
        group = aug,
        callback = ensure_dim_groups,
      })

      require('ibl').setup(opts)
    end,
  },
}
