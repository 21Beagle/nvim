return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    opts = function(_, opts)
      opts.dashboard = opts.dashboard or {}

      opts.dashboard.enabled = true
      opts.dashboard.width = 60
      opts.dashboard.row = nil
      opts.dashboard.col = nil
      opts.dashboard.pane_gap = 4
      opts.dashboard.autokeys = '1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'

      local function is_windows()
        return vim.fn.has 'win32' == 1 or vim.fn.has 'win64' == 1
      end

      local function exe(name)
        return vim.fn.executable(name) == 1
      end

      local function pokemon_cmd()
        if is_windows() then
          if exe 'pokemon-colorscripts' == 1 then
            return 'pokemon-colorscripts -r -b --no-title'
          end

          -- Windows fallback: don't crash dashboard if it's missing
          return 'cmd /c echo pokemon-colorscripts not found (install it or put it on PATH)'
        end

        -- Unix / WSL / macOS
        -- Avoid requiring sleep; snacks terminal section can render without it.
        return "sh -lc 'pokemon-colorscripts -r --no-title'"
      end

      opts.dashboard.preset = opts.dashboard.preset or {}
      opts.dashboard.preset.pick = nil

      opts.dashboard.preset.keys = {
        { icon = ' ', key = 'f', desc = 'Find File', action = ":lua Snacks.dashboard.pick('files')" },
        { icon = ' ', key = 'n', desc = 'New File', action = ':ene | startinsert' },
        { icon = ' ', key = 'g', desc = 'Find Text', action = ":lua Snacks.dashboard.pick('live_grep')" },
        { icon = ' ', key = 'r', desc = 'Recent Files', action = ":lua Snacks.dashboard.pick('oldfiles')" },
        { icon = ' ', key = 'c', desc = 'Config', action = ":lua Snacks.dashboard.pick('files', { cwd = vim.fn.stdpath('config') })" },
        { icon = ' ', key = 's', desc = 'Restore Session', section = 'session' },
        { icon = '󰒲 ', key = 'L', desc = 'Lazy', action = ':Lazy', enabled = package.loaded.lazy ~= nil },
        { icon = ' ', key = 'q', desc = 'Quit', action = ':qa' },
      }

      opts.dashboard.formats = opts.dashboard.formats or {}
      opts.dashboard.formats.icon = opts.dashboard.formats.icon
        or function(item)
          if item.file and (item.icon == 'file' or item.icon == 'directory') then
            return Snacks.dashboard.icon(item.file, item.icon)
          end
          return { item.icon, width = 2, hl = 'icon' }
        end
      opts.dashboard.formats.footer = opts.dashboard.formats.footer or { '%s', align = 'center' }
      opts.dashboard.formats.header = opts.dashboard.formats.header or { '%s', align = 'center' }
      opts.dashboard.formats.file = opts.dashboard.formats.file
        or function(item, ctx)
          local fname = vim.fn.fnamemodify(item.file, ':~')
          if ctx.width and #fname > ctx.width then
            fname = vim.fn.pathshorten(fname)
          end
          if ctx.width and #fname > ctx.width then
            local dir = vim.fn.fnamemodify(fname, ':h')
            local file = vim.fn.fnamemodify(fname, ':t')
            if dir and file then
              file = file:sub(-(ctx.width - #dir - 2))
              fname = dir .. '/…' .. file
            end
          end
          local dir, file = fname:match '^(.*)/(.+)$'
          if dir then
            return { { dir .. '/', hl = 'dir' }, { file, hl = 'file' } }
          end
          return { { fname, hl = 'file' } }
        end

      -- Header becomes the pokemon terminal output
      opts.dashboard.sections = {
        {
          section = 'terminal',
          cmd = pokemon_cmd(),
          random = 900,
          pane = 1,
          indent = 0,
          height = 18,
        },
        { section = 'keys', gap = 1, padding = 1 },
        { section = 'startup' },
      }

      return opts
    end,
  },
}
