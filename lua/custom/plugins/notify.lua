return {
  {
    'rcarriga/nvim-notify',
    event = 'VeryLazy',
    opts = {
      timeout = 2500,
      stages = 'static',
      background_colour = '#000000',
      fps = 30,
      max_width = 80,
      max_height = 10,
      render = 'compact',
      level = vim.log.levels.WARN,
    },
    config = function(_, opts)
      local notify = require 'notify'

      notify.setup(opts)

      local filtered_messages = {
        'No information available',
        'warning: multiple different client offset_encodings',
      }

      vim.notify = function(message, level, notify_opts)
        level = level or vim.log.levels.INFO

        for _, blocked in ipairs(filtered_messages) do
          if type(message) == 'string' and message:find(blocked, 1, true) then
            return
          end
        end

        if level < vim.log.levels.WARN then
          return
        end

        return notify(message, level, notify_opts)
      end
    end,
  },
}
