return {
  'esmuellert/codediff.nvim',
  dependencies = { 'MunifTanjim/nui.nvim' },
  cmd = 'CodeDiff',
  keys = {
    {
      '<leader>cd',
      function()
        local function is_displayed(bufnr)
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == bufnr then
              return true
            end
          end
          return false
        end

        local function is_empty_no_name(bufnr)
          if not vim.api.nvim_buf_is_valid(bufnr) then
            return false
          end
          if vim.api.nvim_buf_get_name(bufnr) ~= '' then
            return false
          end
          if vim.bo[bufnr].modified then
            return false
          end
          if is_displayed(bufnr) then
            return false
          end

          local ok_lines, lines = pcall(vim.api.nvim_buf_get_lines, bufnr, 0, -1, false)
          if not ok_lines or lines == nil then
            return false
          end
          if #lines == 0 then
            return true
          end
          if #lines == 1 and (lines[1] == nil or lines[1] == '') then
            return true
          end

          return false
        end

        local function wipe_all_empty_no_name_buffers()
          for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
            if is_empty_no_name(bufnr) then
              pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
            end
          end
        end

        local ok_lifecycle, lifecycle = pcall(require, 'vscode-diff.render.lifecycle')

        local function get_mode(tabpage)
          if not ok_lifecycle or lifecycle == nil or lifecycle.get_mode == nil then
            return nil
          end
          local ok, mode = pcall(lifecycle.get_mode, tabpage)
          if not ok then
            return nil
          end
          return mode
        end

        local function find_session_tab(target_mode)
          for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
            if get_mode(tab) == target_mode then
              return tab
            end
          end
          return nil
        end

        local function cleanup_session(tabpage)
          if ok_lifecycle and lifecycle and lifecycle.cleanup_diff then
            pcall(lifecycle.cleanup_diff, tabpage)
          end
        end

        local function set_all_windows_fixbuf(value)
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_is_valid(win) then
              pcall(vim.api.nvim_win_set_option, win, 'winfixbuf', value)
            end
          end
        end

        local function close_session_in_tab(tabpage)
          local ok_return_tab, return_tab = pcall(vim.api.nvim_tabpage_get_var, tabpage, 'vscode_diff_return_tab')
          local ok_return_win, return_win = pcall(vim.api.nvim_tabpage_get_var, tabpage, 'vscode_diff_return_win')
          local ok_return_buf, return_buf = pcall(vim.api.nvim_tabpage_get_var, tabpage, 'vscode_diff_return_buf')

          cleanup_session(tabpage)

          local tab_count = #vim.api.nvim_list_tabpages()
          if tab_count > 1 then
            if vim.api.nvim_get_current_tabpage() ~= tabpage then
              vim.api.nvim_set_current_tabpage(tabpage)
            end
            pcall(vim.cmd, 'tabclose')
            wipe_all_empty_no_name_buffers()
            vim.schedule(wipe_all_empty_no_name_buffers)
            return
          end

          pcall(vim.cmd, 'only')

          if ok_return_buf and type(return_buf) == 'number' and vim.api.nvim_buf_is_valid(return_buf) then
            pcall(vim.api.nvim_set_current_buf, return_buf)
          else
            local alt = vim.fn.bufnr '#'
            if type(alt) == 'number' and alt > 0 and vim.api.nvim_buf_is_valid(alt) then
              pcall(vim.api.nvim_set_current_buf, alt)
            end
          end

          if
            ok_return_tab
            and type(return_tab) == 'number'
            and vim.api.nvim_tabpage_is_valid(return_tab)
            and return_tab ~= vim.api.nvim_get_current_tabpage()
          then
            vim.api.nvim_set_current_tabpage(return_tab)
          end

          if ok_return_win and type(return_win) == 'number' and vim.api.nvim_win_is_valid(return_win) then
            pcall(vim.api.nvim_set_current_win, return_win)
          end

          wipe_all_empty_no_name_buffers()
          vim.schedule(wipe_all_empty_no_name_buffers)
        end

        local function open_session(cmd)
          set_all_windows_fixbuf(false)

          local return_tab = vim.api.nvim_get_current_tabpage()
          local return_win = vim.api.nvim_get_current_win()
          local return_buf = vim.api.nvim_get_current_buf()

          local ok_open, err = pcall(vim.cmd, cmd)
          if not ok_open then
            if tostring(err):match 'E784' then
              cleanup_session(return_tab)
              ok_open, err = pcall(vim.cmd, cmd)
            end
          end

          if not ok_open then
            vim.notify('CodeDiff failed: ' .. tostring(err), vim.log.levels.ERROR)
            wipe_all_empty_no_name_buffers()
            vim.schedule(wipe_all_empty_no_name_buffers)
            return
          end

          local codediff_tab = vim.api.nvim_get_current_tabpage()
          pcall(vim.api.nvim_tabpage_set_var, codediff_tab, 'vscode_diff_return_tab', return_tab)
          pcall(vim.api.nvim_tabpage_set_var, codediff_tab, 'vscode_diff_return_win', return_win)
          pcall(vim.api.nvim_tabpage_set_var, codediff_tab, 'vscode_diff_return_buf', return_buf)

          wipe_all_empty_no_name_buffers()
          vim.schedule(wipe_all_empty_no_name_buffers)
          vim.defer_fn(wipe_all_empty_no_name_buffers, 80)
          vim.defer_fn(wipe_all_empty_no_name_buffers, 200)
        end

        local function toggle_session(target_mode, cmd)
          wipe_all_empty_no_name_buffers()

          local session_tab = find_session_tab(target_mode)
          local current_tab = vim.api.nvim_get_current_tabpage()

          if session_tab ~= nil then
            if current_tab ~= session_tab then
              vim.api.nvim_set_current_tabpage(session_tab)
              wipe_all_empty_no_name_buffers()
              vim.schedule(wipe_all_empty_no_name_buffers)
              return
            end

            close_session_in_tab(session_tab)
            return
          end

          open_session(cmd)
        end

        toggle_session('explorer', 'CodeDiff')
      end,
      desc = 'CodeDiff: open/focus/close',
    },
    {
      '<leader>ch',
      function()
        local function is_displayed(bufnr)
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == bufnr then
              return true
            end
          end
          return false
        end

        local function is_empty_no_name(bufnr)
          if not vim.api.nvim_buf_is_valid(bufnr) then
            return false
          end
          if vim.api.nvim_buf_get_name(bufnr) ~= '' then
            return false
          end
          if vim.bo[bufnr].modified then
            return false
          end
          if is_displayed(bufnr) then
            return false
          end

          local ok_lines, lines = pcall(vim.api.nvim_buf_get_lines, bufnr, 0, -1, false)
          if not ok_lines or lines == nil then
            return false
          end
          if #lines == 0 then
            return true
          end
          if #lines == 1 and (lines[1] == nil or lines[1] == '') then
            return true
          end

          return false
        end

        local function wipe_all_empty_no_name_buffers()
          for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
            if is_empty_no_name(bufnr) then
              pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
            end
          end
        end

        local ok_lifecycle, lifecycle = pcall(require, 'vscode-diff.render.lifecycle')

        local function get_mode(tabpage)
          if not ok_lifecycle or lifecycle == nil or lifecycle.get_mode == nil then
            return nil
          end
          local ok, mode = pcall(lifecycle.get_mode, tabpage)
          if not ok then
            return nil
          end
          return mode
        end

        local function find_session_tab(target_mode)
          for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
            if get_mode(tab) == target_mode then
              return tab
            end
          end
          return nil
        end

        local function cleanup_session(tabpage)
          if ok_lifecycle and lifecycle and lifecycle.cleanup_diff then
            pcall(lifecycle.cleanup_diff, tabpage)
          end
        end

        local function set_all_windows_fixbuf(value)
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_is_valid(win) then
              pcall(vim.api.nvim_win_set_option, win, 'winfixbuf', value)
            end
          end
        end

        local function close_session_in_tab(tabpage)
          local ok_return_tab, return_tab = pcall(vim.api.nvim_tabpage_get_var, tabpage, 'vscode_diff_return_tab')
          local ok_return_win, return_win = pcall(vim.api.nvim_tabpage_get_var, tabpage, 'vscode_diff_return_win')
          local ok_return_buf, return_buf = pcall(vim.api.nvim_tabpage_get_var, tabpage, 'vscode_diff_return_buf')

          cleanup_session(tabpage)

          local tab_count = #vim.api.nvim_list_tabpages()
          if tab_count > 1 then
            if vim.api.nvim_get_current_tabpage() ~= tabpage then
              vim.api.nvim_set_current_tabpage(tabpage)
            end
            pcall(vim.cmd, 'tabclose')
            wipe_all_empty_no_name_buffers()
            vim.schedule(wipe_all_empty_no_name_buffers)
            return
          end

          pcall(vim.cmd, 'only')

          if ok_return_buf and type(return_buf) == 'number' and vim.api.nvim_buf_is_valid(return_buf) then
            pcall(vim.api.nvim_set_current_buf, return_buf)
          else
            local alt = vim.fn.bufnr '#'
            if type(alt) == 'number' and alt > 0 and vim.api.nvim_buf_is_valid(alt) then
              pcall(vim.api.nvim_set_current_buf, alt)
            end
          end

          if
            ok_return_tab
            and type(return_tab) == 'number'
            and vim.api.nvim_tabpage_is_valid(return_tab)
            and return_tab ~= vim.api.nvim_get_current_tabpage()
          then
            vim.api.nvim_set_current_tabpage(return_tab)
          end

          if ok_return_win and type(return_win) == 'number' and vim.api.nvim_win_is_valid(return_win) then
            pcall(vim.api.nvim_set_current_win, return_win)
          end

          wipe_all_empty_no_name_buffers()
          vim.schedule(wipe_all_empty_no_name_buffers)
        end

        local function open_session(cmd)
          set_all_windows_fixbuf(false)

          local return_tab = vim.api.nvim_get_current_tabpage()
          local return_win = vim.api.nvim_get_current_win()
          local return_buf = vim.api.nvim_get_current_buf()

          local ok_open, err = pcall(vim.cmd, cmd)
          if not ok_open then
            if tostring(err):match 'E784' then
              cleanup_session(return_tab)
              ok_open, err = pcall(vim.cmd, cmd)
            end
          end

          if not ok_open then
            vim.notify('CodeDiff failed: ' .. tostring(err), vim.log.levels.ERROR)
            wipe_all_empty_no_name_buffers()
            vim.schedule(wipe_all_empty_no_name_buffers)
            return
          end

          local codediff_tab = vim.api.nvim_get_current_tabpage()
          pcall(vim.api.nvim_tabpage_set_var, codediff_tab, 'vscode_diff_return_tab', return_tab)
          pcall(vim.api.nvim_tabpage_set_var, codediff_tab, 'vscode_diff_return_win', return_win)
          pcall(vim.api.nvim_tabpage_set_var, codediff_tab, 'vscode_diff_return_buf', return_buf)

          wipe_all_empty_no_name_buffers()
          vim.schedule(wipe_all_empty_no_name_buffers)
          vim.defer_fn(wipe_all_empty_no_name_buffers, 80)
          vim.defer_fn(wipe_all_empty_no_name_buffers, 200)
        end

        local function toggle_session(target_mode, cmd)
          wipe_all_empty_no_name_buffers()

          local session_tab = find_session_tab(target_mode)
          local current_tab = vim.api.nvim_get_current_tabpage()

          if session_tab ~= nil then
            if current_tab ~= session_tab then
              vim.api.nvim_set_current_tabpage(session_tab)
              wipe_all_empty_no_name_buffers()
              vim.schedule(wipe_all_empty_no_name_buffers)
              return
            end

            close_session_in_tab(session_tab)
            return
          end

          open_session(cmd)
        end

        toggle_session('history', 'CodeDiff history')
      end,
      desc = 'CodeDiff history: open/focus/close',
    },
  },
  config = function()
    require('vscode-diff').setup {
      highlights = {
        line_insert = 'DiffAdd',
        line_delete = 'DiffDelete',
        char_insert = nil,
        char_delete = nil,
        char_brightness = nil,
      },
      diff = {
        disable_inlay_hints = true,
        max_computation_time_ms = 5000,
      },
      explorer = {
        position = 'left',
        focus_on_select = true,
        width = 40,
        height = 15,
        indent_markers = true,
        icons = {
          folder_closed = '',
          folder_open = '',
        },
        view_mode = 'list',
        file_filter = {
          ignore = {},
        },
      },
      keymaps = {
        view = {
          quit = 'Q',
          toggle_explorer = '<leader>b',
          next_hunk = ']c',
          prev_hunk = '[c',
          next_file = ']f',
          prev_file = '[f',
          diff_get = 'do',
          diff_put = 'dp',
        },
        explorer = {
          select = '<CR>',
          hover = 'K',
          refresh = 'R',
          toggle_view_mode = 'i',
        },
      },
    }

    local group = vim.api.nvim_create_augroup('VscodeDiffWinFixBuf', { clear = true })

    local function looks_like_codediff_buffer(bufnr)
      if not vim.api.nvim_buf_is_valid(bufnr) then
        return false
      end
      local name = vim.api.nvim_buf_get_name(bufnr)
      local filetype = vim.bo[bufnr].filetype
      if filetype == 'vscode-diff' then
        return true
      end
      if name:match 'vscode%-diff' or name:match 'CodeDiff' then
        return true
      end
      return false
    end

    vim.api.nvim_create_autocmd({ 'BufWinEnter', 'WinEnter' }, {
      group = group,
      callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        if looks_like_codediff_buffer(bufnr) then
          vim.wo.winfixbuf = true
        end
      end,
    })

    vim.api.nvim_create_autocmd({ 'BufWinLeave', 'WinLeave' }, {
      group = group,
      callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        if looks_like_codediff_buffer(bufnr) then
          vim.wo.winfixbuf = false
        end
      end,
    })
  end,
}
