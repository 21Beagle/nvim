return {
  'GustavEikaas/easy-dotnet.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
    'mfussenegger/nvim-dap',
  },
  config = function()
    local dotnet = require 'easy-dotnet'

    local function is_windows()
      return require('easy-dotnet.extensions').isWindows() == true
    end

    local function path_sep()
      return package.config:sub(1, 1)
    end

    local function join_path(...)
      local sep = path_sep()
      local parts = { ... }
      return table.concat(parts, sep)
    end

    local function prepend_path(dir)
      if type(dir) ~= 'string' or dir == '' then
        return
      end

      if vim.fn.isdirectory(dir) ~= 1 then
        return
      end

      local current = vim.env.PATH or ''
      local path_list_sep = is_windows() and ';' or ':'

      if string.find(current, dir, 1, true) ~= nil then
        return
      end

      vim.env.PATH = dir .. path_list_sep .. current
    end

    local function bootstrap_dotnet_path()
      if not is_windows() then
        return
      end

      prepend_path 'C:\\Program Files\\dotnet'

      local userprofile = os.getenv 'USERPROFILE' or vim.fn.expand '~'
      local dotnet_tools = join_path(userprofile, '.dotnet', 'tools')
      prepend_path(dotnet_tools)
    end

    bootstrap_dotnet_path()

    local function assert_dotnet_available()
      if vim.fn.executable 'dotnet' == 1 then
        return
      end

      vim.schedule(function()
        vim.notify(
          "easy-dotnet: 'dotnet' is not executable in Neovim's PATH. Fix your PATH (or install the .NET SDK) and restart Neovim.",
          vim.log.levels.ERROR
        )
      end)
    end

    assert_dotnet_available()

    local dap = require 'dap'
    local debug_adapter = require('easy-dotnet.constants').debug_adapter_name
    local debugger_path = vim.fn.exepath 'netcoredbg'
    local external_terminal

    if is_windows() then
      external_terminal = {
        -- Windows app execution aliases can be invisible to exepath().
        command = 'wt.exe',
        -- A separate window; preserve the project working directory.
        args = { '-w', '-1', 'nt', '-d', '.', '--' },
      }
      dap.defaults[debug_adapter].external_terminal = external_terminal
      dap.defaults.coreclr.external_terminal = external_terminal
    end

    dotnet.setup {
      external_terminal = external_terminal,
      managed_terminal = { auto_hide = false },
      lsp = {
        enabled = true,
        roslynator_enabled = true,
        easy_dotnet_analyzer_enabled = true,
      },
      debugger = {
        -- nil selects the bundled debugger when netcoredbg is absent from PATH.
        bin_path = debugger_path ~= '' and debugger_path or nil,
        console = external_terminal and 'externalTerminal' or 'integratedTerminal',
        apply_value_converters = true,
        auto_register_dap = true,
        mappings = {
          open_variable_viewer = { lhs = 'T', desc = 'open variable viewer' },
        },
      },
      test_runner = {
        viewmode = 'float',
        mappings = {
          run_test_from_buffer = { lhs = '<leader>mr', desc = 'dotnet run test from buffer' },
          run_all_tests_from_buffer = { lhs = '<leader>ma', desc = 'dotnet run all tests from buffer' },
          debug_test_from_buffer = { lhs = '<leader>mD', desc = 'dotnet debug test from buffer' },
          peek_stack_trace_from_buffer = { lhs = '<leader>mp', desc = 'dotnet peek stack trace from buffer' },
          next_failure = { lhs = ']f', desc = 'next failed test' },
          prev_failure = { lhs = '[f', desc = 'previous failed test' },

          run = { lhs = 'r', desc = 'run test' },
          debug_test = { lhs = 'd', desc = 'debug test' },
          peek_stacktrace = { lhs = 'p', desc = 'peek stacktrace' },
          go_to_file = { lhs = 'g', desc = 'open / go to file' },

          expand = { lhs = '<CR>', desc = 'expand / collapse' },
          expand_node = { lhs = 'L', desc = 'expand children' },
          collapse_all = { lhs = 'H', desc = 'collapse all' },

          run_all = { lhs = 'R', desc = 'run all tests' },

          close = { lhs = 'q', desc = 'close testrunner' },
          refresh_testrunner = { lhs = '<C-r>', desc = 'refresh' },
        },
      },
      picker = 'telescope',
    }

    local dotnet_exception_mode = 'user-unhandled'

    local dotnet_exception_filters = {
      off = {},
      ['user-unhandled'] = { 'user-unhandled' },
      all = { 'all' },
    }

    local dotnet_exception_labels = {
      off = 'off',
      ['user-unhandled'] = 'user-unhandled only',
      all = 'all exceptions',
    }

    local function dotnet_exception_apply(mode, opts)
      opts = opts or {}

      if dotnet_exception_filters[mode] == nil then
        mode = 'user-unhandled'
      end

      dotnet_exception_mode = mode

      dap.defaults.coreclr.exception_breakpoints = dotnet_exception_filters[mode]
      dap.defaults[debug_adapter].exception_breakpoints = dotnet_exception_filters[mode]

      vim.g.dotnet_exception_breakpoints = dotnet_exception_labels[mode]

      local session = dap.session()
      if session and session.config and (session.config.type == 'coreclr' or session.config.type == debug_adapter) then
        dap.set_exception_breakpoints(dotnet_exception_filters[mode])
      end

      if opts.notify ~= false then
        vim.notify('Dotnet exceptions: ' .. dotnet_exception_labels[mode], vim.log.levels.INFO)
      end
    end

    local function dotnet_exception_select()
      vim.ui.select({
        { mode = 'user-unhandled', label = 'User-unhandled only' },
        { mode = 'all', label = 'All exceptions' },
        { mode = 'off', label = 'Off' },
      }, {
        prompt = 'Dotnet exception breakpoints',
        format_item = function(item)
          local marker = item.mode == dotnet_exception_mode and '✓ ' or '  '
          return marker .. item.label
        end,
      }, function(item)
        if item then
          dotnet_exception_apply(item.mode)
        end
      end)
    end

    local function dotnet_exception_cycle()
      if dotnet_exception_mode == 'user-unhandled' then
        dotnet_exception_apply 'all'
        return
      end

      if dotnet_exception_mode == 'all' then
        dotnet_exception_apply 'off'
        return
      end

      dotnet_exception_apply 'user-unhandled'
    end

    dotnet_exception_apply('user-unhandled', { notify = false })

    dap.listeners.after.event_initialized['dotnet_exception_breakpoints'] = function(session)
      if session and session.config and (session.config.type == 'coreclr' or session.config.type == debug_adapter) then
        dotnet_exception_apply(dotnet_exception_mode, { notify = false })
        vim.notify('Dotnet exceptions: ' .. dotnet_exception_labels[dotnet_exception_mode], vim.log.levels.INFO)
      end
    end

    vim.api.nvim_create_user_command('DotnetExceptions', function(opts)
      local mode = opts.args

      if mode == '' or mode == 'menu' then
        dotnet_exception_select()
        return
      end

      if mode == 'cycle' then
        dotnet_exception_cycle()
        return
      end

      if dotnet_exception_filters[mode] == nil then
        vim.notify('Use: DotnetExceptions off|user-unhandled|all|menu|cycle', vim.log.levels.ERROR)
        return
      end

      dotnet_exception_apply(mode)
    end, {
      nargs = '?',
      complete = function()
        return { 'off', 'user-unhandled', 'all', 'menu', 'cycle' }
      end,
    })

    vim.keymap.set('n', '<leader>me', dotnet_exception_select, { desc = 'Dotnet exception breakpoint menu' })

    vim.keymap.set('n', '<leader>mE', dotnet_exception_cycle, { desc = 'Dotnet cycle exception breakpoints' })

    vim.keymap.set('n', '<leader>mU', function()
      dotnet_exception_apply 'user-unhandled'
    end, { desc = 'Dotnet break on user-unhandled exceptions' })

    vim.keymap.set('n', '<leader>mA', function()
      dotnet_exception_apply 'all'
    end, { desc = 'Dotnet break on all exceptions' })

    vim.keymap.set('n', '<leader>mX', function()
      dotnet_exception_apply 'off'
    end, { desc = 'Dotnet disable exception breakpoints' })

    vim.api.nvim_create_user_command('Secrets', function()
      dotnet.secrets()
    end, {})

    local function find_solution_root()
      local buf = vim.api.nvim_get_current_buf()
      local file = vim.api.nvim_buf_get_name(buf)
      local start_dir = file ~= '' and vim.fs.dirname(file) or vim.fn.getcwd()

      local sln = vim.fs.find(function(name)
        return name:match '%.slnx?$' ~= nil
      end, { upward = true, path = start_dir })[1]

      if sln then
        return vim.fs.dirname(sln), sln
      end

      return nil, nil
    end

    local function test_solution_external()
      if not external_terminal then
        dotnet.test_solution()
        return
      end

      local cwd, solution = find_solution_root()
      cwd = cwd or vim.fn.getcwd()
      local function ps_quote(value)
        return "'" .. value:gsub("'", "''") .. "'"
      end
      local command = '& ' .. ps_quote(vim.fn.exepath 'dotnet') .. ' test'
      if solution then
        command = command .. ' ' .. ps_quote(solution)
      end

      local args = vim.list_extend(vim.deepcopy(external_terminal.args), {
        'powershell.exe',
        '-NoLogo',
        '-NoProfile',
        '-NoExit',
        '-Command',
        command,
      })
      local handle, err
      handle, err = vim.uv.spawn(external_terminal.command, { args = args, cwd = cwd, detached = true }, function()
        if handle and not handle:is_closing() then
          handle:close()
        end
      end)
      if handle then
        handle:unref()
      else
        vim.notify('Could not open test terminal: ' .. tostring(err), vim.log.levels.ERROR)
      end
    end

    local function dotnet_cli(args, opts)
      opts = opts or {}

      local cmd = { 'dotnet' }
      vim.list_extend(cmd, args)

      local cwd = opts.cwd or select(1, find_solution_root()) or vim.fn.getcwd()
      local title = opts.title or ('dotnet ' .. table.concat(args, ' '))

      vim.notify(title .. ': ' .. cwd)

      vim.system(cmd, { cwd = cwd, text = true }, function(obj)
        vim.schedule(function()
          if obj.code ~= 0 then
            local msg = obj.stderr ~= '' and obj.stderr or obj.stdout
            vim.notify(msg ~= '' and msg or (title .. ' failed'), vim.log.levels.ERROR)
            return
          end

          vim.notify(title .. ' complete', vim.log.levels.INFO)
          vim.cmd 'checktime'
        end)
      end)
    end

    local function restart_lsp()
      local bufnr = vim.api.nvim_get_current_buf()
      local clients = {}

      if vim.lsp.get_clients then
        clients = vim.lsp.get_clients { bufnr = bufnr }
      else
        clients = vim.lsp.get_active_clients { bufnr = bufnr }
      end

      if vim.fn.exists ':LspRestart' == 2 then
        vim.cmd 'LspRestart'
      else
        vim.lsp.stop_client(clients)
        vim.defer_fn(function()
          vim.cmd 'edit'
        end, 300)
      end

      if #clients == 0 then
        vim.notify('LSP restart requested; no active client was attached to this buffer', vim.log.levels.WARN)
      else
        vim.notify('LSP restart requested', vim.log.levels.INFO)
      end
    end

    local workspace_diagnostics_generation = 0
    local cleared_workspace_diagnostics = {}

    local function get_workspace_diagnostic_namespace()
      local constants = require 'easy-dotnet.constants'
      local clients = {}

      vim.list_extend(clients, vim.lsp.get_clients { name = 'roslyn' })
      vim.list_extend(clients, vim.lsp.get_clients { name = constants.lsp_client_name })

      for _, client in ipairs(clients) do
        local ok, namespace = pcall(vim.lsp.diagnostic.get_namespace, client.id)

        if ok and namespace then
          return namespace
        end
      end

      return vim.api.nvim_create_namespace 'easy-dotnet-diagnostics'
    end

    local function clear_workspace_diagnostics_on_first_change(bufnr)
      if workspace_diagnostics_generation == 0 then
        return
      end

      if cleared_workspace_diagnostics[bufnr] == workspace_diagnostics_generation then
        return
      end

      local namespace = get_workspace_diagnostic_namespace()
      vim.diagnostic.reset(namespace, bufnr)

      cleared_workspace_diagnostics[bufnr] = workspace_diagnostics_generation
    end

    local function workspace_diagnostics()
      workspace_diagnostics_generation = workspace_diagnostics_generation + 1
      cleared_workspace_diagnostics = {}

      dotnet.diagnostics.get_workspace_diagnostics 'warning'
    end

    vim.api.nvim_create_autocmd({ 'InsertCharPre', 'TextChanged' }, {
      pattern = '*.cs',
      callback = function(args)
        clear_workspace_diagnostics_on_first_change(args.buf)
      end,
    })

    vim.keymap.set('n', '<C-p>', function()
      dotnet.run()
    end, { desc = 'Dotnet run project' })

    vim.keymap.set('n', '<leader>mc', function()
      dotnet_cli({ 'clean', '-nologo', '-v:minimal' }, { title = 'Dotnet clean' })
    end, { desc = 'Dotnet clean solution' })

    vim.keymap.set('n', '<leader>mm', workspace_diagnostics, { desc = 'Dotnet workspace diagnostics' })

    vim.keymap.set('n', '<leader>mb', function()
      dotnet.build()
    end, { desc = 'Dotnet build' })

    vim.keymap.set('n', '<leader>mB', workspace_diagnostics, { desc = 'Dotnet workspace diagnostics' })

    vim.keymap.set('n', '<leader>md', function()
      dotnet.debug_profile()
    end, { desc = 'Dotnet debug' })

    vim.keymap.set('n', '<leader>ml', restart_lsp, { desc = 'Dotnet restart LSP' })

    vim.keymap.set('n', '<leader>mL', function()
      dotnet_cli({ 'restore' }, { title = 'Dotnet restore' })
    end, { desc = 'Dotnet restore' })

    vim.keymap.set('n', '<leader>mR', function()
      dotnet.run()
    end, { desc = 'Dotnet run project' })

    vim.keymap.set('n', '<leader>ms', function()
      dotnet.secrets()
    end, { desc = 'Dotnet user secrets' })

    vim.keymap.set('n', '<leader>mt', function()
      dotnet.testrunner()
    end, { desc = 'Dotnet test runner' })

    vim.keymap.set('n', '<leader>mT', test_solution_external, { desc = 'Dotnet test solution in external terminal' })
  end,
}
