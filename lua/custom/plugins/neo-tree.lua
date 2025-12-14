return {
  'nvim-neo-tree/neo-tree.nvim',
  branch = 'v3.x',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons',
    'MunifTanjim/nui.nvim',
  },
  init = function()
    -- If a neo-tree buffer is left around (session restore / window close / etc),
    -- it can collide with a later neo-tree open. Wipe it when hidden.
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'neo-tree',
      callback = function()
        vim.bo.bufhidden = 'wipe'
      end,
    })
  end,
  keys = {
    {
      '<leader>e',
      function()
        local currentWinId = vim.api.nvim_get_current_win()
        local currentBufferId = vim.api.nvim_win_get_buf(currentWinId)
        local currentFiletype = vim.bo[currentBufferId].filetype

        local neoTreeWinId = nil
        for _, winId in ipairs(vim.api.nvim_list_wins()) do
          local bufferId = vim.api.nvim_win_get_buf(winId)
          if vim.bo[bufferId].filetype == 'neo-tree' then
            neoTreeWinId = winId
            break
          end
        end

        if neoTreeWinId then
          if currentFiletype == 'neo-tree' then
            vim.cmd 'Neotree toggle'
            return
          end

          vim.api.nvim_set_current_win(neoTreeWinId)
          return
        end

        -- Not open: toggle is the one command that actually opens AND focuses reliably
        vim.cmd 'Neotree toggle'
      end,
      desc = 'Explorer (focus / close)',
    },
  },
  opts = {
    filesystem = {
      follow_current_file = {
        enabled = true,
      },
      use_libuv_file_watcher = true,
    },
    window = {
      width = 30,
    },
  },
}
