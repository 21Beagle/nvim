return {
  'nvim-neo-tree/neo-tree.nvim',
  branch = 'v3.x',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons',
    'MunifTanjim/nui.nvim',
  },
  init = function()
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

        vim.cmd 'Neotree toggle'
      end,
      desc = 'Explorer (focus / close)',
    },
  },
  opts = {
    close_if_last_window = true,

    filesystem = {
      follow_current_file = {
        enabled = true,
      },
      use_libuv_file_watcher = true,
    },

    window = {
      position = 'left',
      width = 30,

      -- Prevent Neo-tree “open file” from replacing dap-ui windows if they happen to be focused
      open_files_do_not_replace_types = {
        'neo-tree',
        'dapui_scopes',
        'dapui_breakpoints',
        'dapui_stacks',
        'dapui_watches',
        'dapui_console',
        'dapui_repl',
      },
    },
  },
}
