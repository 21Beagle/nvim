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
              open = 'l',
              remove = 'd',
              edit = 'e',
              repl = 'r',
              toggle = 't',
            },
            layouts = {
              {
                elements = {
                  { id = 'scopes', size = 0.5 },
                  { id = 'stacks', size = 0.5 },
                },
                size = 40,
                position = 'left',
              },
              {
                elements = {
                  { id = 'console', size = 1.0 },
                },
                size = 10,
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
              element = 'console',
            },
          }))
          local dap = require 'dap'

          dap.listeners.after.event_initialized['dapui_config'] = function()
            dapui.open()
          end

          dap.listeners.before.event_terminated['dapui_config'] = function()
            dapui.close()
          end

          dap.listeners.before.event_exited['dapui_config'] = function()
            dapui.close()
          end
        end,
      },
      {
        'theHamsta/nvim-dap-virtual-text',
        opts = {},
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
        '<C-S-F5>',
        function()
          require('dap').restart()
        end,
        desc = 'Debug: Restart',
      },
      {
        '<F9>',
        function()
          require('dap').toggle_breakpoint()
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
        '<C-F9>',
        function()
          require('dap').set_breakpoint(nil, nil, vim.fn.input 'Log point message: ')
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
        '<F7>',
        function()
          require('dapui').toggle { reset = true }
        end,
        desc = 'Debug: Toggle UI',
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
          require('dap').toggle_breakpoint()
        end,
        desc = 'Debug: Toggle Breakpoint',
      },
      {
        '<leader>dB',
        function()
          require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
        end,
        desc = 'Debug: Conditional Breakpoint',
      },
      {
        '<leader>dl',
        function()
          require('dap').set_breakpoint(nil, nil, vim.fn.input 'Log point message: ')
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
          require('dapui').toggle { reset = true }
        end,
        desc = 'Debug: Toggle UI',
      },
      {
        '<leader>de',
        function()
          require('dapui').eval()
        end,
        desc = 'Debug: Eval',
      },
      {
        '<leader>dh',
        function()
          require('dapui').eval(vim.fn.expand '<cword>')
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
          require('dapui').float_element('watches', { enter = true })
        end,
        desc = 'Debug: Watches',
      },
      {
        '<leader>ds',
        function()
          require('dapui').float_element('scopes', { enter = true })
        end,
        desc = 'Debug: Scopes',
      },
      {
        '<leader>dx',
        function()
          require('dapui').float_element('stacks', { enter = true })
        end,
        desc = 'Debug: Stacks',
      },
      {
        '<leader>dp',
        function()
          require('dapui').float_element('breakpoints', { enter = true })
        end,
        desc = 'Debug: Breakpoints',
      },
      {
        '<leader>df',
        function()
          local widgets = require 'dap.ui.widgets'
          widgets.centered_float(widgets.frames)
        end,
        desc = 'Debug: Frames',
      },
      {
        '<leader>dv',
        function()
          local widgets = require 'dap.ui.widgets'
          widgets.centered_float(widgets.scopes)
        end,
        desc = 'Debug: Variables',
      },
    },
    config = function() end,
  },
}
