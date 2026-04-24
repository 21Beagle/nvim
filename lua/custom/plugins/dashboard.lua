return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    dependencies = { 'amansingh-afk/milli.nvim' },
    opts = function()
      local splash = require('milli').load({ splash = 'shader' })

      return {
        dashboard = {
          enabled = true,
          width = 60,
          row = nil,
          col = nil,
          preset = {
            pick = nil,
            keys = {
              { icon = ' ', key = 'f', desc = 'Find File', action = ':lua Snacks.picker.files()' },
              { icon = ' ', key = 'n', desc = 'New File', action = ':ene | startinsert' },
              { icon = ' ', key = 'g', desc = 'Find Text', action = ':lua Snacks.picker.grep()' },
              { icon = ' ', key = 'r', desc = 'Recent Files', action = ':lua Snacks.picker.recent()' },
              { icon = ' ', key = 'p', desc = 'Projects', action = ':Telescope persisted' },
              { icon = ' ', key = 'c', desc = 'Config', action = ":lua Snacks.picker.files({ cwd = vim.fn.stdpath('config') })" },
              { icon = ' ', key = 's', desc = 'Restore Session', section = 'session' },
              { icon = '󰒲 ', key = 'L', desc = 'Lazy', action = ':Lazy', enabled = package.loaded.lazy ~= nil },
              { icon = ' ', key = 'q', desc = 'Quit', action = ':qa' },
            },
          },
          sections = {
            { section = 'header', text = table.concat(splash.frames[1], '\n') },
            {
              section = 'projects',
              title = 'Projects',
              indent = 2,
              padding = 1,
            },
            { section = 'keys', gap = 1, padding = 1 },
            { section = 'startup' },
          },
        },
      }
    end,
    config = function(_, opts)
      require('snacks').setup(opts)
      require('milli').snacks({ splash = 'shader', loop = true })
    end,
  },
}
