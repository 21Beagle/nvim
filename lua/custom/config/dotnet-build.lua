----------------------------------------------------------------------
-- dotnet build -> diagnostics
----------------------------------------------------------------------

local M = {}

local dotnet_ns = vim.api.nvim_create_namespace 'dotnet_build'

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
  return line:gsub('\27%[[%d;]*m', '')
end

local function dotnet_parse_build_output(lines, cwd)
  cwd = cwd or vim.loop.cwd()
  local diags_by_buf = {}

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
end

local function find_sln_dir()
  local start = vim.fn.expand '%:p:h'
  if start == nil or start == '' then
    start = vim.loop.cwd()
  end

  local matches = vim.fs.find(function(name)
    return name:match '%.sln$'
  end, { path = start, upward = true })

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

function M.build()
  local sln_dir = find_sln_dir()
  if sln_dir ~= nil then
    vim.cmd('cd ' .. vim.fn.fnameescape(sln_dir))
  end

  local cwd = vim.loop.cwd()
  local lines = {}

  vim.notify('dotnet build (cwd=' .. cwd .. ')', vim.log.levels.INFO)

  local function on_data(_, data)
    if data == nil then
      return
    end
    for _, line in ipairs(data) do
      if line ~= nil and line ~= '' then
        table.insert(lines, line)
      end
    end
  end

  local job_id = vim.fn.jobstart({ 'dotnet', 'build' }, {
    cwd = cwd,
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = on_data,
    on_stderr = on_data,
    on_exit = function(_, code)
      if code ~= 0 then
        vim.notify('dotnet build failed with exit code ' .. code, vim.log.levels.ERROR)
      else
        vim.notify('dotnet build succeeded', vim.log.levels.INFO)
      end

      dotnet_parse_build_output(lines, cwd)
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


why is my leadermr keybinding not being set
