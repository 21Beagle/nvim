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

    -- Publish MSBuild errors/warnings into Neovim diagnostics so Telescope builtin.diagnostics sees them.
    local dotnet_build_ns = vim.api.nvim_create_namespace 'dotnet_build'

    local function normalize_path(p)
      if not p or p == '' then
        return nil
      end
      p = p:gsub('"', '')
      return vim.fn.fnamemodify(p, ':p')
    end

    local function parse_msbuild_line(line)
      -- Typical MSBuild lines:
      -- C:\path\File.cs(12,34): error CS1002: ; expected [Proj.csproj]
      -- /path/File.cs(12,34): warning CS0168: ... [Proj.csproj]
      local file, lnum, col, sev, msg = line:match '^(.+)%((%d+),(%d+)%)%s*:%s*(error)%s+(.*)$'
      if not file then
        file, lnum, col, sev, msg = line:match '^(.+)%((%d+),(%d+)%)%s*:%s*(warning)%s+(.*)$'
      end
      if not file then
        return nil
      end

      local severity = (sev == 'error') and vim.diagnostic.severity.ERROR or vim.diagnostic.severity.WARN
      return {
        filename = normalize_path(file),
        lnum = tonumber(lnum),
        col = tonumber(col),
        severity = severity,
        message = msg,
      }
    end

    local function clear_build_diagnostics()
      -- Clear diagnostics for all loaded buffers in this namespace
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        vim.diagnostic.reset(dotnet_build_ns, bufnr)
      end
    end

    local function publish_build_diagnostics(lines)
      clear_build_diagnostics()

      local per_buf = {}

      for _, line in ipairs(lines) do
        local hit = parse_msbuild_line(line)
        if hit and hit.filename then
          local bufnr = vim.fn.bufnr(hit.filename, true)
          pcall(vim.fn.bufload, bufnr)

          per_buf[bufnr] = per_buf[bufnr] or {}
          table.insert(per_buf[bufnr], {
            lnum = math.max((hit.lnum or 1) - 1, 0),
            col = math.max((hit.col or 1) - 1, 0),
            severity = hit.severity,
            message = hit.message,
            source = 'dotnet build',
          })
        end
      end

      for bufnr, diags in pairs(per_buf) do
        vim.diagnostic.set(dotnet_build_ns, bufnr, diags, { underline = true, virtual_text = false, signs = true })
      end
    end

    -- Run dotnet build, SHOW output in a bottom split, and populate Neovim diagnostics.
    local function dotnet_build_to_diagnostics(path, extra_args)
      extra_args = extra_args or ''

      local cmd = { 'dotnet', 'build' }

      if path and path ~= '' then
        table.insert(cmd, path)
      end

      table.insert(cmd, '-nologo')
      table.insert(cmd, '-v:minimal')

      if extra_args ~= '' then
        for a in string.gmatch(extra_args, '%S+') do
          table.insert(cmd, a)
        end
      end

      -- Create/reuse a "build log" scratch buffer so you can watch output
      local bufname = 'dotnet://build'
      local buf = vim.fn.bufnr(bufname, false)
      if buf == -1 then
        buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(buf, bufname)
        vim.bo[buf].buftype = 'nofile'
        vim.bo[buf].bufhidden = 'hide'
        vim.bo[buf].swapfile = false
        vim.bo[buf].filetype = 'log'
      end

      -- Show it in a bottom split (reuse window if already visible)
      local win = vim.fn.bufwinid(buf)
      if win == -1 then
        vim.cmd 'botright split'
        vim.cmd 'resize 12'
        vim.api.nvim_win_set_buf(0, buf)
      else
        vim.api.nvim_set_current_win(win)
      end

      vim.bo[buf].modifiable = true
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { '[dotnet build] starting…', '' })

      local collected = {}

      local function append_lines(data)
        if not data then
          return
        end

        local to_add = {}
        for _, l in ipairs(data) do
          if l ~= '' then
            table.insert(collected, l)
            table.insert(to_add, l)
          end
        end
        if #to_add == 0 then
          return
        end

        if not vim.api.nvim_buf_is_valid(buf) then
          return
        end

        local line_count = vim.api.nvim_buf_line_count(buf)
        vim.api.nvim_buf_set_lines(buf, line_count, line_count, false, to_add)

        -- follow output (only if you're looking at the build buffer)
        local curwin = vim.api.nvim_get_current_win()
        if vim.api.nvim_win_get_buf(curwin) == buf then
          local last = vim.api.nvim_buf_line_count(buf)
          vim.api.nvim_win_set_cursor(curwin, { last, 0 })
        end
      end

      vim.fn.jobstart(cmd, {
        stdout_buffered = false,
        stderr_buffered = false,

        on_stdout = function(_, data)
          vim.schedule(function()
            append_lines(data)
          end)
        end,

        on_stderr = function(_, data)
          vim.schedule(function()
            append_lines(data)
          end)
        end,

        on_exit = function(_, code)
          vim.schedule(function()
            publish_build_diagnostics(collected)

            if vim.api.nvim_buf_is_valid(buf) then
              vim.api.nvim_buf_set_lines(buf, vim.api.nvim_buf_line_count(buf), vim.api.nvim_buf_line_count(buf), false, {
                '',
                ('[dotnet build] exit code %d'):format(code),
                '[dotnet build] diagnostics updated (use <leader>sd)',
              })
            end

            if code == 0 then
              vim.notify('dotnet build: done (diagnostics updated)', vim.log.levels.INFO)
            else
              vim.notify('dotnet build: failed (diagnostics updated)', vim.log.levels.WARN)
            end
          end)
        end,
      })
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

        -- Horizontal split instead of vertical
        vim.cmd 'botright split'
        vim.cmd 'resize 12'
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

    -- Diagnostics (more reliable): defer slightly so Roslyn has time to publish results
    vim.keymap.set('n', '<leader>mm', function()
      vim.defer_fn(function()
        dotnet.diagnostics.get_workspace_diagnostics 'warning'
      end, 400)
    end, { desc = 'workspace diagnostics' })

    -- Build solution: show build output + populate Neovim diagnostics for Telescope builtin.diagnostics (<leader>sd)
    vim.keymap.set('n', '<leader>mb', function()
      dotnet_build_to_diagnostics(vim.fn.getcwd(), '')
    end, { desc = 'dotnet build -> diagnostics (visible)' })
  end,
}
