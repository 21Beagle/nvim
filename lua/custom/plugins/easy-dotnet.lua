return {
  'GustavEikaas/easy-dotnet.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
  },
  config = function()
    local dotnet = require 'easy-dotnet'

    dotnet.setup {
      lsp = {
        enabled = true,
        roslynator_enabled = true,
        easy_dotnet_analyzer_enabled = true,
      },
      debugger = {
        auto_register_dap = true,
        mappings = {
          debug_project = { lhs = '<leader>md', desc = 'debug project' },
          open_variable_viewer = { lhs = 'T', desc = 'open variable viewer' },
        },
      },
      test_runner = {
        viewmode = 'float',
        enable_buffer_test_execution = true,
        noBuild = false,
      },
      mappings = {
        run_test_from_buffer = { lhs = '<leader>tr', desc = 'run test from buffer' },
        run_all_tests_from_buffer = { lhs = '<leader>ta', desc = 'run all tests from buffer' },
        peek_stack_trace_from_buffer = { lhs = '<leader>tp', desc = 'peek stack trace from buffer' },
        filter_failed_tests = { lhs = '<leader>tf', desc = 'filter failed tests' },

        run = { lhs = 'r', desc = 'run test' },
        debug_test = { lhs = 'd', desc = 'debug test' },
        peek_stacktrace = { lhs = 'p', desc = 'peek stacktrace' },
        go_to_file = { lhs = 'g', desc = 'open / go to file' },

        expand = { lhs = '<CR>', desc = 'expand / collapse' },
        expand_node = { lhs = 'o', desc = 'expand node' },
        expand_all = { lhs = 'L', desc = 'expand all' },
        collapse_all = { lhs = 'H', desc = 'collapse all' },

        run_all = { lhs = 'R', desc = 'run all tests' },

        close = { lhs = 'q', desc = 'close testrunner' },
        refresh_testrunner = { lhs = '<F5>', desc = 'refresh' },
      },
      picker = 'telescope',
    }

    vim.api.nvim_create_user_command('Secrets', function()
      dotnet.secrets()
    end, {})


    vim.keymap.set('n', '<leader>mm', function()
      vim.defer_fn(function()
        dotnet.diagnostics.get_workspace_diagnostics 'warning'
      end, 400)
    end, { desc = 'workspace diagnostics' })

    vim.keymap.set('n', '<leader>mb', function()
      dotnet.build()
    end, { desc = 'dotnet build' })

    vim.keymap.set('n', '<leader>md', function()
      dotnet.debug()
    end, { desc = 'dotnet debug' })

    vim.keymap.set('n', '<leader>mt', function()
      dotnet.testrunner()
    end, { desc = 'dotnet test' })
  end,
}
