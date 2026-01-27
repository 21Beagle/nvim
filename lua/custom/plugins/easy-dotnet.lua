return -- lazy.nvim
{
  'GustavEikaas/easy-dotnet.nvim',
  -- 'nvim-telescope/telescope.nvim' or 'ibhagwan/fzf-lua' or 'folke/snacks.nvim'
  -- are highly recommended for a better experience
  dependencies = { 'nvim-lua/plenary.nvim', 'nvim-telescope/telescope.nvim' },
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

      -- avoid duplicating
      if string.find(current, dir, 1, true) ~= nil then
        return
      end

      vim.env.PATH = dir .. path_list_sep .. current
    end

    local function bootstrap_dotnet_path()
      if not is_windows() then
        return
      end

      -- Make sure Neovim can find dotnet.exe
      prepend_path 'C:\\Program Files\\dotnet'

      -- Make sure Neovim can find global tool shims (dotnet-easydotnet, etc.)
      local userprofile = os.getenv 'USERPROFILE' or vim.fn.expand '~'
      local dotnet_tools = join_path(userprofile, '.dotnet', 'tools')
      prepend_path(dotnet_tools)
    end

    bootstrap_dotnet_path()

    local function get_mason_netcoredbg_path()
      local mason_root = join_path(vim.fn.stdpath 'data', 'mason', 'packages', 'netcoredbg', 'netcoredbg')
      if is_windows() then
        local exe_path = join_path(mason_root, 'netcoredbg.exe')
        if vim.fn.filereadable(exe_path) == 1 then
          return exe_path
        end
        return nil
      end

      local bin_path = join_path(mason_root, 'netcoredbg')
      if vim.fn.filereadable(bin_path) == 1 then
        return bin_path
      end
      return nil
    end

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

    local cached_sdk_path = nil

    local function get_sdk_path()
      if cached_sdk_path ~= nil then
        return cached_sdk_path
      end

      -- dotnet --list-sdks returns lines like:
      -- 8.0.100 [C:\Program Files\dotnet\sdk]
      local lines = vim.fn.systemlist { 'dotnet', '--list-sdks' }
      if type(lines) ~= 'table' or #lines == 0 then
        return nil
      end

      local best_version = nil
      local best_path = nil

      local function parse_version(v)
        local major, minor, patch = string.match(v, '^(%d+)%.(%d+)%.(%d+)$')
        if major == nil then
          return nil
        end
        return tonumber(major), tonumber(minor), tonumber(patch)
      end

      local function is_newer(a, b)
        if b == nil then
          return true
        end

        local a1, a2, a3 = parse_version(a)
        local b1, b2, b3 = parse_version(b)
        if a1 == nil or b1 == nil then
          return false
        end

        if a1 ~= b1 then
          return a1 > b1
        end
        if a2 ~= b2 then
          return a2 > b2
        end
        return a3 > b3
      end

      for _, line in ipairs(lines) do
        local version, base = string.match(line, '^(%S+)%s+%[(.-)%]$')
        if version ~= nil and base ~= nil then
          if is_newer(version, best_version) then
            best_version = version
            best_path = base .. '\\' .. version
          end
        end
      end

      cached_sdk_path = best_path
      return cached_sdk_path
    end

    dotnet.setup {
      lsp = {
        enabled = true, -- Enable builtin roslyn lsp
        roslynator_enabled = true, -- Automatically enable roslynator analyzer
        easy_dotnet_analyzer_enabled = true, -- Enable roslyn analyzer from easy-dotnet-server
        analyzer_assemblies = {}, -- Any additional roslyn analyzers you might use like SonarAnalyzer.CSharp
        config = {},
      },

      -- Optional: speeds up + stabilizes SDK discovery (especially on Windows)
      get_sdk_path = get_sdk_path,

      debugger = {
        -- Prefer Mason netcoredbg if installed; otherwise let easy-dotnet-server fall back to its bundled netcoredbg
        bin_path = get_mason_netcoredbg_path(),
        apply_value_converters = true,
        auto_register_dap = true,
        mappings = {
          debug_project = { lhs = '<leader>md', desc = 'debug project' },
          open_variable_viewer = { lhs = 'T', desc = 'open variable viewer' },
        },
      },

      ---@type TestRunnerOptions
      test_runner = {
        ---@type "split" | "vsplit" | "float" | "buf"
        viewmode = 'float',
        ---@type number|nil
        vsplit_width = nil,
        ---@type string|nil "topleft" | "topright"
        vsplit_pos = nil,
        enable_buffer_test_execution = true, --Experimental, run tests directly from buffer
        noBuild = true,
        icons = {
          passed = '',
          skipped = '',
          failed = '',
          success = '',
          reload = '',
          test = '',
          sln = '󰘐',
          project = '󰘐',
          dir = '',
          package = '',
        },
        mappings = {
          run_test_from_buffer = { lhs = '<leader>r', desc = 'run test from buffer' },
          run_all_tests_from_buffer = { lhs = '<leader>t', desc = 'run all tests from buffer' },
          peek_stack_trace_from_buffer = { lhs = '<leader>p', desc = 'peek stack trace from buffer' },
          filter_failed_tests = { lhs = '<leader>fe', desc = 'filter failed tests' },
          debug_test = { lhs = '<leader>mt', desc = 'debug test' },
          go_to_file = { lhs = 'g', desc = 'go to file' },
          run_all = { lhs = '<leader>R', desc = 'run all tests' },
          run = { lhs = '<leader>r', desc = 'run test' },
          peek_stacktrace = { lhs = '<leader>p', desc = 'peek stacktrace of failed test' },
          expand = { lhs = 'o', desc = 'expand' },
          expand_node = { lhs = 'E', desc = 'expand node' },
          expand_all = { lhs = '-', desc = 'expand all' },
          collapse_all = { lhs = 'W', desc = 'collapse all' },
          close = { lhs = 'q', desc = 'close testrunner' },
          refresh_testrunner = { lhs = '<C-r>', desc = 'refresh testrunner' },
        },
        additional_args = {},
      },

      new = {
        project = {
          prefix = 'sln', -- "sln" | "none"
        },
      },

      ---@param action "test" | "restore" | "build" | "run"
      terminal = function(path, action, args)
        args = args or ''
        local commands = {
          run = function()
            return string.format('dotnet run --project %s %s', path, args)
          end,
          test = function()
            return string.format('dotnet test %s %s', path, args)
          end,
          restore = function()
            return string.format('dotnet restore %s %s', path, args)
          end,
          build = function()
            return string.format('dotnet build %s %s', path, args)
          end,
          watch = function()
            return string.format('dotnet watch --project %s %s', path, args)
          end,
        }

        local command = commands[action]()
        if is_windows() then
          command = command .. '\r'
        end
        vim.cmd 'vsplit'
        vim.cmd('term ' .. command)
      end,

      csproj_mappings = true,
      fsproj_mappings = true,

      auto_bootstrap_namespace = {
        type = 'block_scoped',
        enabled = true,
        use_clipboard_json = {
          behavior = 'prompt',
          register = '+',
        },
      },

      server = {
        ---@type nil | "Off" | "Critical" | "Error" | "Warning" | "Information" | "Verbose" | "All"
        log_level = nil,
      },

      picker = 'telescope',
      background_scanning = true,

      notifications = {
        handler = function(start_event)
          local spinner = require('easy-dotnet.ui-modules.spinner').new()
          spinner:start_spinner(start_event.job.name)
          ---@param finished_event JobEvent
          return function(finished_event)
            spinner:stop_spinner(finished_event.result.msg, finished_event.result.level)
          end
        end,
      },

      diagnostics = {
        default_severity = 'error',
        setqflist = false,
      },
    }

    vim.api.nvim_create_user_command('Secrets', function()
      dotnet.secrets()
    end, {})

    vim.keymap.set('n', '<C-p>', function()
      dotnet.run_project()
    end)

    vim.keymap.set('n', '<leader>md', function()
      dotnet.debug()
    end)

    vim.keymap.set('n', '<leader>mb', function()
      dotnet.diagnostics.get_workspace_diagnostics 'warning'
    end)
  end,
}
