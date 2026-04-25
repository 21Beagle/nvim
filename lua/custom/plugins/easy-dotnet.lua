return {
  'GustavEikaas/easy-dotnet.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
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
    local function open_float_term(cmd, opts)
      opts = opts or {}
      local width = opts.width or math.floor(vim.o.columns * 0.85)
      local height = opts.height or math.floor(vim.o.lines * 0.30)
      local row = math.floor((vim.o.lines - height) * 0.80)
      local col = math.floor((vim.o.columns - width) / 2)

      local buf = vim.api.nvim_create_buf(false, true)
      vim.bo[buf].buftype = 'nofile'
      vim.bo[buf].bufhidden = 'wipe'
      vim.bo[buf].swapfile = false

      local win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        row = row,
        col = col,
        width = width,
        height = height,
        style = 'minimal',
        border = opts.border or 'rounded',
        title = opts.title or ' dotnet ',
        title_pos = 'center',
      })

      -- Optional: make it feel “UI-like”
      vim.wo[win].winblend = opts.winblend or 0
      vim.wo[win].wrap = false
      vim.wo[win].number = false
      vim.wo[win].relativenumber = false
      vim.wo[win].signcolumn = 'no'

      -- Start terminal job in that buffer
      vim.fn.termopen(cmd, {
        on_exit = function()
          -- keep buffer around; close window automatically if you want:
          if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
          end
        end,
      })
      vim.cmd 'startinsert'
      return buf, win
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
  local file, lnum, col, sev, rest =
    line:match('^(.+)%((%d+),(%d+)%)%s*:%s*(error)%s+(.*)$')
  if not file then
    file, lnum, col, sev, rest =
      line:match('^(.+)%((%d+),(%d+)%)%s*:%s*(warning)%s+(.*)$')
  end
  if not file then
    return nil
  end

  rest = (rest or ''):gsub('%s*%b[]%s*$', '')

  local code, msg = rest:match('^(%S+)%s*:%s*(.*)$')
  local message
  if code and msg and code:match('^[A-Z]+%d+$') then
    message = code .. ': ' .. msg
  else
    message = rest
  end

  local severity = (sev == 'error') and vim.diagnostic.severity.ERROR or vim.diagnostic.severity.WARN
  return {
    filename = normalize_path(file),
    lnum = tonumber(lnum),
    col = tonumber(col),
    severity = severity,
    message = message,
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
        vim.diagnostic.set(dotnet_build_ns, bufnr, diags, { underline = true, virtual_text = true, signs = true })
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
        enabled = true,
        roslynator_enabled = true,
        easy_dotnet_analyzer_enabled = true,
      },
      debugger = {
        -- Prefer Mason netcoredbg if installed; otherwise let easy-dotnet-server fall back to its bundled netcoredbg
        apply_value_converters = true,
        auto_register_dap = true,
        mappings = {
          debug_project = { lhs = '<leader>md', desc = 'dotnet debug project' },
          open_variable_viewer = { lhs = 'T', desc = 'open variable viewer' },
        },
      },
      test_runner = {
        viewmode = 'float',
        enable_buffer_test_execution = true,
        noBuild = false,
      },
      mappings = {
        run_test_from_buffer = { lhs = '<leader>mr', desc = 'dotnet run test from buffer' },
        run_all_tests_from_buffer = { lhs = '<leader>ma', desc = 'dotnet run all tests from buffer' },
        peek_stack_trace_from_buffer = { lhs = '<leader>mp', desc = 'dotnet peek stack trace from buffer' },
        filter_failed_tests = { lhs = '<leader>mT', desc = 'dotnet filter failed tests' },

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

    local function find_solution_root()
      local buf = vim.api.nvim_get_current_buf()
      local file = vim.api.nvim_buf_get_name(buf)
      local start_dir = file ~= '' and vim.fs.dirname(file) or vim.fn.getcwd()

      local sln = vim.fs.find(function(name)
        return name:match '%.sln$' ~= nil
      end, { upward = true, path = start_dir })[1]

      if sln then
        return vim.fs.dirname(sln), sln
      end

      return nil, nil
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

    vim.keymap.set('n', '<C-p>', function()
      dotnet.run_project()
    end, { desc = 'Dotnet run project' })

    vim.keymap.set('n', '<leader>mc', function()
      dotnet_cli({ 'clean', '-nologo', '-v:minimal' }, { title = 'Dotnet clean' })
    end, { desc = 'Dotnet clean solution' })

    -- Diagnostics (more reliable): defer slightly so Roslyn has time to publish results
    vim.keymap.set('n', '<leader>mm', function()
      vim.defer_fn(function()
        dotnet.diagnostics.get_workspace_diagnostics 'warning'
      end, 400)
    end, { desc = 'Dotnet workspace diagnostics' })

    vim.keymap.set('n', '<leader>mb', function()
      dotnet.build()
    end, { desc = 'Dotnet build' })

    vim.keymap.set('n', '<leader>mB', function()
      dotnet_build_to_diagnostics()
    end, { desc = 'Dotnet build with diagnostics' })

    vim.keymap.set('n', '<leader>md', function()
      dotnet.debug()
    end, { desc = 'Dotnet debug' })

    vim.keymap.set('n', '<leader>ml', restart_lsp, { desc = 'Dotnet restart LSP' })

    vim.keymap.set('n', '<leader>mL', function()
      dotnet_cli({ 'restore' }, { title = 'Dotnet restore' })
    end, { desc = 'Dotnet restore' })

    vim.keymap.set('n', '<leader>mR', function()
      dotnet.run_project()
    end, { desc = 'Dotnet run project' })

    vim.keymap.set('n', '<leader>ms', function()
      dotnet.secrets()
    end, { desc = 'Dotnet user secrets' })

    vim.keymap.set('n', '<leader>mt', function()
      dotnet.testrunner()
    end, { desc = 'Dotnet test runner' })
  end,
}
