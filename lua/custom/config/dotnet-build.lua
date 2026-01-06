----------------------------------------------------------------------
-- dotnet build -> diagnostics (+ live output buffer)
----------------------------------------------------------------------

local M = {}

local dotnet_ns = vim.api.nvim_create_namespace 'dotnet_build'

-- Build output window (single instance)
local build_out = {
  bufnr = nil,
  winid = nil,
  height = 12,
}

local function dotnet_is_windows()
  return package.config:sub(1, 1) == '\\'
end

local function dotnet_normalize_path(path)
  if dotnet_is_windows() then
    path = path:gsub('\\', '/')
  end
  return path
end

local function dotnet_strip_ansi(line)
  line = line:gsub('\27%[[%d;]*m', '')
  line = line:gsub('\r', '')
  return line
end

local function build_out_is_valid_buf(bufnr)
  return bufnr ~= nil and vim.api.nvim_buf_is_valid(bufnr)
end

local function build_out_buf_winid(bufnr)
  local winid = vim.fn.bufwinid(bufnr)
  if winid == nil or winid == -1 then
    return nil
  end
  return winid
end

local function build_out_close_window()
  if not build_out_is_valid_buf(build_out.bufnr) then
    return
  end

  local winid = build_out_buf_winid(build_out.bufnr)
  if winid ~= nil and vim.api.nvim_win_is_valid(winid) then
    pcall(vim.api.nvim_win_close, winid, true)
  end
end

local function build_out_add_highlights(start_lnum, end_lnum)
  if not build_out_is_valid_buf(build_out.bufnr) then
    return
  end

  local ok, buf_lines = pcall(vim.api.nvim_buf_get_lines, build_out.bufnr, start_lnum, end_lnum, false)
  if not ok or buf_lines == nil then
    return
  end

  local function add_pattern_hl(line_idx, text, pattern, hl_group)
    local from = 1
    while true do
      local s, e = text:find(pattern, from)
      if s == nil then
        return
      end
      vim.api.nvim_buf_add_highlight(build_out.bufnr, dotnet_ns, hl_group, line_idx, s - 1, e)
      from = e + 1
    end
  end

  for i, text in ipairs(buf_lines) do
    local lnum = start_lnum + (i - 1)

    add_pattern_hl(lnum, text, ':%s*error%s+', 'DiagnosticError')
    add_pattern_hl(lnum, text, ':%s*warning%s+', 'DiagnosticWarn')
    add_pattern_hl(lnum, text, '[Ee]rror', 'DiagnosticError')
    add_pattern_hl(lnum, text, '[Ww]arning', 'DiagnosticWarn')
    add_pattern_hl(lnum, text, '[Bb]uild%s+FAILED', 'DiagnosticError')
    add_pattern_hl(lnum, text, '[Bb]uild%s+succeeded', 'DiagnosticInfo')
    add_pattern_hl(lnum, text, '^exit code:%s*%d+', 'DiagnosticInfo')
  end
end

local function dotnet_parse_build_output(lines, cwd)
  cwd = cwd or vim.loop.cwd()
  local diags_by_buf = {}
  local has_error = false

  for _, raw_line in ipairs(lines) do
    local line = dotnet_strip_ansi(raw_line)

    -- Example: Program.cs(10,13): error CS1002: ; expected [MyProject]
    local file, lnum, col, level, code, msg = line:match '^(.+)%((%d+),(%d+)%)%s*:%s*(%a+)%s+([%w%d]+)%s*:%s*(.+)$'

    if file ~= nil then
      file = dotnet_normalize_path(file)

      local fullpath = vim.fn.fnamemodify(file, ':p')
      if not fullpath:match '^%a:[/\\]' and not fullpath:match '^/' then
        fullpath = dotnet_normalize_path(cwd .. '/' .. file)
      end

      local bufnr = vim.fn.bufadd(fullpath)

      local severity
      local lvl = level:lower()
      if lvl == 'error' then
        severity = vim.diagnostic.severity.ERROR
        has_error = true
      elseif lvl == 'warning' then
        severity = vim.diagnostic.severity.WARN
      else
        severity = vim.diagnostic.severity.INFO
      end

      local diag = {
        lnum = tonumber(lnum) - 1,
        col = tonumber(col) - 1,
        severity = severity,
        source = 'dotnet-build',
        code = code,
        message = msg,
      }

      if diags_by_buf[bufnr] == nil then
        diags_by_buf[bufnr] = {}
      end
      table.insert(diags_by_buf[bufnr], diag)
    end
  end

  vim.diagnostic.reset(dotnet_ns)

  for bufnr, diags in pairs(diags_by_buf) do
    vim.diagnostic.set(dotnet_ns, bufnr, diags, { underline = true, virtual_text = false })
  end

  return has_error
end

local function find_sln_dir()
  local start = vim.fn.expand '%:p:h'
  if start == nil or start == '' then
    start = vim.loop.cwd()
  end

  -- 1) Upward search from the current file dir (or cwd fallback)
  local matches = vim.fs.find(function(name)
    return name:match '%.sln$'
  end, { path = start, upward = true, limit = 1 })

  -- 2) If not found upward, search downward from cwd (recursive)
  if matches == nil or matches[1] == nil then
    local cwd = vim.loop.cwd()
    matches = vim.fs.find(function(name)
      return name:match '%.sln$'
    end, { path = cwd, upward = false, limit = math.huge })

    if matches ~= nil and #matches > 1 then
      -- choose the "closest" match (usually the most relevant)
      table.sort(matches, function(a, b)
        return #a < #b
      end)
    end
  end

  local first = matches[1]
  if first == nil or first == '' then
    return nil
  end

  local dir = vim.fs.dirname(first)
  if dir == nil or dir == '' then
    return nil
  end

  return dir
end

local function build_out_open_window()
  if build_out_is_valid_buf(build_out.bufnr) then
    local winid = build_out_buf_winid(build_out.bufnr)
    if winid ~= nil then
      build_out.winid = winid
      return
    end
  end

  vim.cmd('botright ' .. build_out.height .. 'split')
  vim.wo.winfixheight = true

  if not build_out_is_valid_buf(build_out.bufnr) then
    build_out.bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(build_out.bufnr, 'dotnet://build')
    vim.bo[build_out.bufnr].buftype = 'nofile'
    vim.bo[build_out.bufnr].bufhidden = 'hide'
    vim.bo[build_out.bufnr].swapfile = false
    vim.bo[build_out.bufnr].modifiable = true
    vim.bo[build_out.bufnr].filetype = 'dotnet-build'

    vim.keymap.set('n', 'q', function()
      build_out_close_window()
    end, { buffer = build_out.bufnr, nowait = true, silent = true })
  end

  vim.api.nvim_set_current_buf(build_out.bufnr)
  build_out.winid = vim.api.nvim_get_current_win()

  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn = 'no'
  vim.wo.wrap = false
  vim.wo.cursorline = true
end

local function build_out_clear()
  if not build_out_is_valid_buf(build_out.bufnr) then
    return
  end
  vim.api.nvim_buf_set_lines(build_out.bufnr, 0, -1, false, {})
  vim.api.nvim_buf_clear_namespace(build_out.bufnr, dotnet_ns, 0, -1)
end

local function build_out_append(lines_to_add)
  if lines_to_add == nil or #lines_to_add == 0 then
    return
  end

  build_out_open_window()

  if not build_out_is_valid_buf(build_out.bufnr) then
    return
  end

  local start_lnum = vim.api.nvim_buf_line_count(build_out.bufnr)
  vim.api.nvim_buf_set_lines(build_out.bufnr, -1, -1, false, lines_to_add)
  local end_lnum = vim.api.nvim_buf_line_count(build_out.bufnr)

  build_out_add_highlights(start_lnum, end_lnum)

  local winid = build_out_buf_winid(build_out.bufnr)
  if winid ~= nil and vim.api.nvim_win_is_valid(winid) then
    local last = vim.api.nvim_buf_line_count(build_out.bufnr)
    pcall(vim.api.nvim_win_set_cursor, winid, { last, 0 })
  end
end

function M.build()
  local sln_dir = find_sln_dir()
  if sln_dir ~= nil then
    vim.cmd('cd ' .. vim.fn.fnameescape(sln_dir))
  end

  local cwd = vim.loop.cwd()
  local lines = {}

  build_out_open_window()
  build_out_clear()
  build_out_append {
    'dotnet build',
    'cwd: ' .. cwd,
    string.rep('-', 60),
    '',
  }

  vim.notify('dotnet build (cwd=' .. cwd .. ')', vim.log.levels.INFO)

  local function on_data(_, data)
    if data == nil then
      return
    end

    local to_show = {}
    for _, raw in ipairs(data) do
      local line = dotnet_strip_ansi(raw)
      if line ~= nil and line ~= '' then
        table.insert(lines, line)
        table.insert(to_show, line)
      end
    end

    if #to_show > 0 then
      vim.schedule(function()
        build_out_append(to_show)
      end)
    end
  end

  local job_id = vim.fn.jobstart({ 'dotnet', 'build' }, {
    cwd = cwd,
    stdout_buffered = false,
    stderr_buffered = false,
    on_stdout = on_data,
    on_stderr = on_data,
    on_exit = function(_, code)
      vim.schedule(function()
        build_out_append {
          '',
          string.rep('-', 60),
          'exit code: ' .. tostring(code),
        }
      end)

      local has_error = dotnet_parse_build_output(lines, cwd)

      if code ~= 0 or has_error then
        vim.notify('dotnet build failed with exit code ' .. code, vim.log.levels.ERROR)
        return
      end

      vim.notify('dotnet build succeeded', vim.log.levels.INFO)
      vim.schedule(function()
        build_out_close_window()
      end)
    end,
  })

  if job_id <= 0 then
    vim.notify('Failed to start `dotnet build` job', vim.log.levels.ERROR)
  end
end

function M.setup()
  vim.keymap.set('n', '<leader>mb', function()
    M.build()
  end, { desc = 'dotnet build (populate diagnostics)' })
end

return M
