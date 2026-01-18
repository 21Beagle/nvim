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
          dapui.setup(opts)

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
      -- Visual Studio / VS Code-ish defaults
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
        '<leader>db',
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

      -- Common VS extras
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

      -- Watches / eval hover-ish
      {
        '<F7>',
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
        desc = 'Debug: Eval (cursor)',
      },
    },
    config = function()
      -- No adapters configured here; your dotnet module sets coreclr adapter when used.
    end,
  },
}
