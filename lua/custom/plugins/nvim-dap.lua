return {
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      {
        'rcarriga/nvim-dap-ui',
        dependencies = {
          'nvim-neotest/nvim-nio',
        },
        opts = {},
        config = function(_, opts)
          local dapui = require 'dapui'

          dapui.setup(vim.tbl_deep_extend('force', opts or {}, {
            mappings = {
              expand = { '<CR>', 'o' },
              open = { 'g', 'p' },
              remove = { 'd', 'r' },
              edit = 'e',
              repl = 'K',
              toggle = 't',
            },
            layouts = {
              {
                elements = {
                  { id = 'breakpoints', size = 0.3 },
                  { id = 'stacks', size = 0.7 },
                },
                size = 80,
                position = 'right',
              },
              {
                elements = {
                  { id = 'scopes', size = 1.0 },
                },
                size = 20,
                position = 'bottom',
              },
            },
            floating = {
              border = 'rounded',
            },
            render = {
              max_value_lines = 1,
            },
            controls = {
              enabled = true,
              element = 'scopes',
            },
          }))

          local dap = require 'dap'
          vim.api.nvim_create_autocmd('FileType', {
            pattern = 'dapui_hover',
            callback = function(args)
              vim.keymap.set('n', 'q', '<cmd>close<cr>', {
                buffer = args.buf,
                silent = true,
              })

              vim.keymap.set('n', '<Esc>', '<cmd>close<cr>', {
                buffer = args.buf,
                silent = true,
              })
            end,
          })
          local function lock_dapui_window(win)
            win = win or vim.api.nvim_get_current_win()

            if not vim.api.nvim_win_is_valid(win) then
              return
            end

            local buf = vim.api.nvim_win_get_buf(win)
            local ft = vim.bo[buf].filetype

            if not ft:match '^dapui_' then
              return
            end

            pcall(function()
              vim.api.nvim_set_option_value('winfixbuf', true, {
                win = win,
              })
            end)

            pcall(function()
              vim.api.nvim_set_option_value('winfixwidth', true, {
                win = win,
              })
            end)

            pcall(function()
              vim.api.nvim_set_option_value('winfixheight', true, {
                win = win,
              })
            end)
          end

          local function open_dapui_layout()
            local current_win = vim.api.nvim_get_current_win()

            pcall(function()
              dapui.open { reset = true }
            end)

            vim.schedule(function()
              for _, win in ipairs(vim.api.nvim_list_wins()) do
                lock_dapui_window(win)
              end

              if vim.api.nvim_win_is_valid(current_win) then
                pcall(vim.api.nvim_set_current_win, current_win)
              end
            end)
          end

          vim.api.nvim_create_autocmd({ 'FileType', 'BufWinEnter', 'WinEnter' }, {
            pattern = 'dapui_*',
            callback = function()
              lock_dapui_window(vim.api.nvim_get_current_win())
            end,
          })

          local function close_dapui_layout()
            pcall(function()
              dapui.close()
            end)
          end

          local function hard_reset_dapui_layout()
            close_dapui_layout()

            for _, win in ipairs(vim.api.nvim_list_wins()) do
              local buf = vim.api.nvim_win_get_buf(win)
              local ft = vim.bo[buf].filetype

              if ft:match '^dapui_' then
                pcall(vim.api.nvim_win_close, win, true)
              end
            end

            open_dapui_layout()
          end
          local function refresh_dapui_scopes()
            local current_win = vim.api.nvim_get_current_win()

            vim.schedule(function()
              pcall(function()
                dapui.open()
              end)

              vim.defer_fn(function()
                if vim.api.nvim_win_is_valid(current_win) then
                  pcall(vim.api.nvim_set_current_win, current_win)
                end
              end, 20)
            end)
          end
          vim.api.nvim_create_user_command('DapUiOpen', open_dapui_layout, {})
          vim.api.nvim_create_user_command('DapUiClose', close_dapui_layout, {})
          vim.api.nvim_create_user_command('DapUiHardReset', hard_reset_dapui_layout, {})

          _G.open_dapui_layout = open_dapui_layout
          _G.close_dapui_layout = close_dapui_layout
          _G.hard_reset_dapui_layout = hard_reset_dapui_layout

          dap.listeners.after.event_initialized['dapui_config'] = function()
            open_dapui_layout()
          end

          dap.listeners.after.event_stopped['dapui_refresh_scopes'] = function()
            refresh_dapui_scopes()
          end

          dap.listeners.after.event_continued['dapui_refresh_scopes'] = function()
            refresh_dapui_scopes()
          end

          dap.listeners.before.event_terminated['dapui_config'] = function()
            close_dapui_layout()
          end

          dap.listeners.before.event_exited['dapui_config'] = function()
            close_dapui_layout()
          end
          local function set_dap_highlights()
            vim.api.nvim_set_hl(0, 'DapBreakpoint', {
              fg = '#ff5555',
            })

            vim.api.nvim_set_hl(0, 'DapBreakpointCondition', {
              fg = '#ffcc90',
            })

            vim.api.nvim_set_hl(0, 'DapBreakpointRejected', {
              fg = '#905555',
            })

            vim.api.nvim_set_hl(0, 'DapLogPoint', {
              fg = '#61afef',
            })

            vim.api.nvim_set_hl(0, 'DapStopped', {
              fg = '#ffcc90',
              bold = true,
            })

            vim.api.nvim_set_hl(0, 'DapStoppedLine', {
              bg = '#4a3f00',
              bold = true,
            })

            vim.fn.sign_define('DapBreakpoint', {
              text = '',
              texthl = 'DapBreakpoint',
              linehl = '',
              numhl = 'DapBreakpoint',
            })

            vim.fn.sign_define('DapBreakpointCondition', {
              text = '',
              texthl = 'DapBreakpointCondition',
              linehl = '',
              numhl = 'DapBreakpointCondition',
            })

            vim.fn.sign_define('DapBreakpointRejected', {
              text = '',
              texthl = 'DapBreakpointRejected',
              linehl = '',
              numhl = 'DapBreakpointRejected',
            })

            vim.fn.sign_define('DapLogPoint', {
              text = '',
              texthl = 'DapLogPoint',
              linehl = '',
              numhl = 'DapLogPoint',
            })

            vim.fn.sign_define('DapStopped', {
              text = '󰁕',
              texthl = 'DapStopped',
              linehl = 'DapStoppedLine',
              numhl = 'DapStoppedLine',
            })
          end

          set_dap_highlights()

          vim.api.nvim_create_autocmd('ColorScheme', {
            callback = set_dap_highlights,
          })

          vim.opt.mouse = 'a'
          vim.opt.signcolumn = 'yes'

          vim.keymap.set('n', '<LeftMouse>', function()
            local mouse = vim.fn.getmousepos()

            if mouse.winid == 0 then
              return '<LeftMouse>'
            end

            local win = mouse.winid
            local buf = vim.api.nvim_win_get_buf(win)

            if vim.bo[buf].buftype ~= '' then
              return '<LeftMouse>'
            end

            local wininfo = vim.fn.getwininfo(win)[1]

            if not wininfo then
              return '<LeftMouse>'
            end

            if mouse.wincol <= wininfo.textoff then
              vim.api.nvim_set_current_win(win)
              vim.api.nvim_win_set_cursor(win, { mouse.line, 0 })
              require('persistent-breakpoints.api').toggle_breakpoint()
              return ''
            end

            return '<LeftMouse>'
          end, {
            expr = true,
            silent = true,
            desc = 'Toggle DAP breakpoint from gutter',
          })

          local function continue_on_invalid_stopped_frame(session)
            vim.defer_fn(function()
              if not session or not session.current_frame then
                return
              end

              local frame = session.current_frame
              local source = frame.source or {}
              local path = source.path
              local line = frame.line

              if not path or not line then
                pcall(function()
                  dap.continue()
                end)
                return
              end

              local bufnr = vim.fn.bufnr(path)

              if bufnr == -1 then
                pcall(function()
                  vim.cmd.edit(vim.fn.fnameescape(path))
                end)

                bufnr = vim.fn.bufnr(path)
              end

              if bufnr == -1 or not vim.api.nvim_buf_is_loaded(bufnr) then
                pcall(function()
                  dap.continue()
                end)
                return
              end

              local line_count = vim.api.nvim_buf_line_count(bufnr)

              if line < 1 or line > line_count then
                vim.notify('DAP stopped on invalid source line, continuing', vim.log.levels.WARN)

                pcall(function()
                  dap.continue()
                end)
              end
            end, 100)
          end

          dap.listeners.after.event_stopped['continue_on_invalid_stopped_frame'] = continue_on_invalid_stopped_frame
        end,
      },
      {
        'theHamsta/nvim-dap-virtual-text',
        opts = {},
      },
      {
        'Weissle/persistent-breakpoints.nvim',
        opts = {
          load_breakpoints_event = { 'BufReadPost' },
        },
      },
    },
    keys = {
      {
        '<F5>',
        function()
          require('dap').continue()
        end,
        desc = 'Debug: Start/Continue',
      },
      {
        '<S-F5>',
        function()
          require('dap').terminate()
        end,
        desc = 'Debug: Stop',
      },
      {
        '<F17>',
        function()
          require('dap').terminate()
        end,
        desc = 'Debug: Stop',
      },
      {
        '<C-S-F5>',
        function()
          require('dap').restart()
        end,
        desc = 'Debug: Restart',
      },
      {
        '<F9>',
        function()
          require('persistent-breakpoints.api').toggle_breakpoint()
        end,
        desc = 'Debug: Toggle Breakpoint',
      },
      {
        '<S-F9>',
        function()
          require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
        end,
        desc = 'Debug: Conditional Breakpoint',
      },
      {
        '<F21>',
        function()
          require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
        end,
        desc = 'Debug: Conditional Breakpoint',
      },
      {
        '<C-F9>',
        function()
          require('persistent-breakpoints.api').set_log_point()
        end,
        desc = 'Debug: Logpoint',
      },
      {
        '<F10>',
        function()
          require('dap').step_over()
        end,
        desc = 'Debug: Step Over',
      },
      {
        '<F11>',
        function()
          require('dap').step_into()
        end,
        desc = 'Debug: Step Into',
      },
      {
        '<S-F11>',
        function()
          require('dap').step_out()
        end,
        desc = 'Debug: Step Out',
      },
      {
        '<F23>',
        function()
          require('dap').step_out()
        end,
        desc = 'Debug: Step Out',
      },
      {
        '<C-F10>',
        function()
          require('dap').run_to_cursor()
        end,
        desc = 'Debug: Run to Cursor',
      },
      {
        '<F8>',
        function()
          require('dap').down()
        end,
        desc = 'Debug: Down Stack',
      },
      {
        '<S-F8>',
        function()
          require('dap').up()
        end,
        desc = 'Debug: Up Stack',
      },
      {
        '<F20>',
        function()
          require('dap').up()
        end,
        desc = 'Debug: Up Stack',
      },
      {
        '<F7>',
        function()
          _G.open_dapui_layout()
        end,
        desc = 'Debug: Open UI',
      },
      {
        '<S-F7>',
        function()
          _G.close_dapui_layout()
        end,
        desc = 'Debug: Close UI',
      },
      {
        '<F19>',
        function()
          _G.close_dapui_layout()
        end,
        desc = 'Debug: Close UI',
      },
      {
        '<leader>dc',
        function()
          require('dap').continue()
        end,
        desc = 'Debug: Continue',
      },
      {
        '<leader>dq',
        function()
          require('dap').terminate()
        end,
        desc = 'Debug: Stop',
      },
      {
        '<leader>dr',
        function()
          require('dap').restart()
        end,
        desc = 'Debug: Restart',
      },
      {
        '<leader>db',
        function()
          require('persistent-breakpoints.api').toggle_breakpoint()
        end,
        desc = 'Debug: Toggle Breakpoint',
      },
      {
        '<leader>dB',
        function()
          require('persistent-breakpoints.api').set_conditional_breakpoint()
        end,
        desc = 'Debug: Conditional Breakpoint',
      },
      {
        '<leader>dl',
        function()
          require('persistent-breakpoints.api').set_log_point()
        end,
        desc = 'Debug: Logpoint',
      },
      {
        '<leader>dn',
        function()
          require('dap').step_over()
        end,
        desc = 'Debug: Step Over',
      },
      {
        '<leader>di',
        function()
          require('dap').step_into()
        end,
        desc = 'Debug: Step Into',
      },
      {
        '<leader>do',
        function()
          require('dap').step_out()
        end,
        desc = 'Debug: Step Out',
      },
      {
        '<leader>du',
        function()
          _G.open_dapui_layout()
        end,
        desc = 'Debug: Open UI',
      },
      {
        '<leader>de',
        function()
          local dapui = require 'dapui'

          dapui.eval()
          dapui.eval()
        end,
        desc = 'Debug: Eval',
      },
      {
        '<leader>dh',
        function()
          local dapui = require 'dapui'
          local word = vim.fn.expand '<cword>'

          dapui.eval(word)
          dapui.eval(word)
        end,
        desc = 'Debug: Eval Word',
      },
      {
        '<leader>dt',
        function()
          require('dap').run_to_cursor()
        end,
        desc = 'Debug: Run to Cursor',
      },
      {
        '<leader>dj',
        function()
          require('dap').down()
        end,
        desc = 'Debug: Down Stack',
      },
      {
        '<leader>dk',
        function()
          require('dap').up()
        end,
        desc = 'Debug: Up Stack',
      },
      {
        '<leader>dw',
        function()
          require('dapui').float_element('watches', {
            enter = true,
            width = math.floor(vim.o.columns * 0.6),
            height = math.floor(vim.o.lines * 0.5),
          })
        end,
        desc = 'Debug: Watches',
      },
      {
        '<leader>ds',
        function()
          require('dapui').float_element('scopes', {
            enter = true,
            width = math.floor(vim.o.columns * 0.6),
            height = math.floor(vim.o.lines * 0.5),
          })
        end,
        desc = 'Debug: Scopes',
      },
      {
        '<leader>dx',
        function()
          require('dapui').float_element('stacks', {
            enter = true,
            width = math.floor(vim.o.columns * 0.6),
            height = math.floor(vim.o.lines * 0.5),
          })
        end,
        desc = 'Debug: Stacks',
      },
      {
        '<leader>dp',
        function()
          require('dapui').float_element('breakpoints', {
            enter = true,
            width = math.floor(vim.o.columns * 0.6),
            height = math.floor(vim.o.lines * 0.5),
          })
        end,
        desc = 'Debug: Breakpoints',
      },
      {
        '<leader>df',
        function()
          local widgets = require 'dap.ui.widgets'
          require('dapui').float_element('frames', {
            enter = true,
            width = math.floor(vim.o.columns * 0.6),
            height = math.floor(vim.o.lines * 0.5),
          })
        end,
        desc = 'Debug: Frames',
      },
    },
    config = function()
      local dap = require 'dap'

      local function reset_dap()
        pcall(function()
          dap.terminate()
        end)

        pcall(function()
          dap.disconnect {
            terminateDebuggee = true,
          }
        end)

        pcall(function()
          require('dapui').close()
        end)

        pcall(function()
          dap.repl.close()
        end)
      end

      vim.api.nvim_create_autocmd('VimLeavePre', {
        callback = reset_dap,
      })

      vim.api.nvim_create_user_command('DapReset', reset_dap, {})

      vim.keymap.set('n', '<leader>dQ', reset_dap, {
        silent = true,
        desc = 'Debug: Reset DAP',
      })
    end,
  },
}
