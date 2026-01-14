----------------------------------------------------------------------
-- dotnet debug -> pick runnable project from .sln -> nvim-dap (netcoredbg)
--
-- Keymap: <leader>md
----------------------------------------------------------------------

local M = {}

local function is_windows()
  return package.config:sub(1, 1) == '\\'
end

local function normalize_path(path)
  if is_windows() then
    return (path or ''):gsub('\\', '/')
  end
  return path
end

local function path_join(a, b)
  if a == nil or a == '' then
    return b
  end
  if b == nil or b == '' then
    return a
  end
  a = normalize_path(a)
  b = normalize_path(b)
  if a:sub(-1) == '/' then
    return a .. b
  end
  return a .. '/' .. b
end

local function file_exists(path)
  if path == nil or path == '' then
    return false
  end
  local stat = vim.loop.fs_stat(path)
  return stat ~= nil and stat.type == 'file'
end

local function read_file(path)
  local fd = vim.loop.fs_open(path, 'r', 438)
  if fd == nil then
    return nil
  end
  local stat = vim.loop.fs_fstat(fd)
  if stat == nil then
    vim.loop.fs_close(fd)
    return nil
  end
  local data = vim.loop.fs_read(fd, stat.size, 0)
  vim.loop.fs_close(fd)
  return data
end

local function trim(s)
  return (s or ''):gsub('^%s+', ''):gsub('%s+$', '')
end

local function find_sln_path()
  local start = vim.fn.expand '%:p:h'
  if start == nil or start == '' then
    start = vim.loop.cwd()
  end

  local matches = vim.fs.find(function(name)
    return name:match '%.sln$'
  end, { path = start, upward = true, limit = 1 })

  if matches == nil or matches[1] == nil then
    local cwd = vim.loop.cwd()
    matches = vim.fs.find(function(name)
      return name:match '%.sln$'
    end, { path = cwd, upward = false, limit = math.huge })

    if matches ~= nil and #matches > 1 then
      table.sort(matches, function(a, b)
        return #a < #b
      end)
    end
  end

  if matches == nil or matches[1] == nil or matches[1] == '' then
    return nil
  end

  return normalize_path(matches[1])
end

local function parse_sln_projects(sln_path)
  local text = read_file(sln_path)
  if text == nil then
    return {}
  end

  local sln_dir = normalize_path(vim.fs.dirname(sln_path))
  local projects = {}

  for line in text:gmatch '[^\r\n]+' do
    local name, relpath = line:match '^Project%("%b{}"%)%s*=%s*"(.-)"%s*,%s*"(.-)"%s*,%s*"%b{}"%s*$'
    if name ~= nil and relpath ~= nil then
      local rp = normalize_path(relpath)
      if rp:match '%.csproj$' or rp:match '%.fsproj$' or rp:match '%.vbproj$' then
        local full = rp
        if not full:match '^%a:[/\\]' and not full:match '^/' then
          full = path_join(sln_dir, rp)
        end
        projects[#projects + 1] = {
          name = name,
          csproj = full,
          project_dir = normalize_path(vim.fs.dirname(full)),
        }
      end
    end
  end

  return projects
end

local function xml_first(text, pattern)
  if text == nil then
    return nil
  end
  local v = text:match(pattern)
  if v == nil then
    return nil
  end
  return trim(v)
end

local function choose_tfm(tfms)
  if tfms == nil or #tfms == 0 then
    return nil
  end
  if is_windows() then
    for _, tfm in ipairs(tfms) do
      if tfm:find('windows', 1, true) ~= nil then
        return tfm
      end
    end
  end
  return tfms[1]
end

local function parse_csproj_info(csproj_path)
  local text = read_file(csproj_path)
  if text == nil then
    return nil
  end

  local output_type = xml_first(text, '<OutputType>%s*(.-)%s*</OutputType>')
  local assembly_name = xml_first(text, '<AssemblyName>%s*(.-)%s*</AssemblyName>')
  local tfm_single = xml_first(text, '<TargetFramework>%s*(.-)%s*</TargetFramework>')
  local tfm_multi = xml_first(text, '<TargetFrameworks>%s*(.-)%s*</TargetFrameworks>')

  local tfms = {}
  if tfm_multi ~= nil and tfm_multi ~= '' then
    for t in tfm_multi:gmatch '([^;]+)' do
      tfms[#tfms + 1] = trim(t)
    end
  elseif tfm_single ~= nil and tfm_single ~= '' then
    tfms[#tfms + 1] = trim(tfm_single)
  end

  if assembly_name == nil or assembly_name == '' then
    assembly_name = vim.fn.fnamemodify(csproj_path, ':t:r')
  end

  local sdk = xml_first(text, '<Project%s+Sdk="%s*(.-)%s*"%s*>')
  if sdk == nil then
    sdk = xml_first(text, "<Project%s+Sdk='%s*(.-)%s*'%s*>")
  end

  local use_winforms = (xml_first(text, '<UseWindowsForms>%s*(.-)%s*</UseWindowsForms>') or ''):lower() == 'true'
  local use_wpf = (xml_first(text, '<UseWPF>%s*(.-)%s*</UseWPF>') or ''):lower() == 'true'
  local has_functions = (xml_first(text, '<AzureFunctionsVersion>%s*(.-)%s*</AzureFunctionsVersion>') or '') ~= ''

  local runnable = false

  if output_type ~= nil and output_type ~= '' then
    local ot = output_type:lower()
    if ot == 'exe' or ot == 'winexe' then
      runnable = true
    end
  end

  if not runnable then
    local sdk_l = (sdk or ''):lower()
    if sdk_l:find('microsoft.net.sdk.web', 1, true) ~= nil then
      runnable = true
    elseif sdk_l:find('microsoft.net.sdk.windowsdesktop', 1, true) ~= nil then
      runnable = true
    elseif use_winforms or use_wpf then
      runnable = true
    elseif has_functions then
      runnable = true
    end
  end

  return {
    output_type = output_type,
    assembly_name = assembly_name,
    tfms = tfms,
    runnable = runnable,
    sdk = sdk,
    use_winforms = use_winforms,
    use_wpf = use_wpf,
  }
end

local function compute_dll_path(project_dir, configuration, tfm, assembly_name)
  local bin_dir = path_join(project_dir, 'bin')
  bin_dir = path_join(bin_dir, configuration)
  bin_dir = path_join(bin_dir, tfm)
  return path_join(bin_dir, assembly_name .. '.dll')
end

-- Better resolver with full trace of what was tried
local function resolve_netcoredbg(explicit_path)
  local tried = {}

  local function add(p)
    if p ~= nil and p ~= '' then
      tried[#tried + 1] = normalize_path(p)
    end
  end

  local function is_abs(p)
    if p == nil or p == '' then
      return false
    end
    if p:match '^%a:[/\\]' ~= nil then
      return true
    end
    if p:sub(1, 1) == '/' then
      return true
    end
    return false
  end

  if explicit_path ~= nil and explicit_path ~= '' then
    local p = normalize_path(explicit_path)
    add(p)
    if is_abs(p) then
      if file_exists(p) then
        return p, tried
      end
    else
      if vim.fn.executable(p) == 1 then
        return p, tried
      end
    end
  end

  -- Mason locations (both layouts)
  local mason_root = normalize_path(vim.fn.stdpath 'data' .. '/mason/packages/netcoredbg')
  add(mason_root .. '/netcoredbg.exe')
  add(mason_root .. '/netcoredbg/netcoredbg.exe')

  if file_exists(mason_root .. '/netcoredbg.exe') then
    return mason_root .. '/netcoredbg.exe', tried
  end
  if file_exists(mason_root .. '/netcoredbg/netcoredbg.exe') then
    return mason_root .. '/netcoredbg/netcoredbg.exe', tried
  end

  -- PATH fallbacks
  if is_windows() then
    add 'netcoredbg.exe'
    if vim.fn.executable 'netcoredbg.exe' == 1 then
      return 'netcoredbg.exe', tried
    end
  end

  add 'netcoredbg'
  if vim.fn.executable 'netcoredbg' == 1 then
    return 'netcoredbg', tried
  end

  return nil, tried
end

local function ensure_dap_adapter(netcoredbg_path)
  local ok, dap = pcall(require, 'dap')
  if not ok or dap == nil then
    vim.notify("nvim-dap is not installed (require('dap') failed)", vim.log.levels.ERROR)
    return false
  end

  local cmd, tried = resolve_netcoredbg(netcoredbg_path)
  if cmd == nil or cmd == '' then
    vim.notify('netcoredbg not found. Tried:\n- ' .. table.concat(tried, '\n- '), vim.log.levels.ERROR)
    return false
  end

  dap.adapters.coreclr = {
    type = 'executable',
    command = cmd,
    args = { '--interpreter=vscode' },
    detached = not is_windows(),
  }

  vim.notify('coreclr adapter: ' .. cmd, vim.log.levels.INFO)
  return true
end

local function dotnet_build_project(csproj_path, cwd, configuration, on_done)
  local args = { 'dotnet', 'build', csproj_path, '-c', configuration }
  local output = {}

  local job_id = vim.fn.jobstart(args, {
    cwd = cwd,
    stdout_buffered = false,
    stderr_buffered = false,
    on_stdout = function(_, data)
      if data == nil then
        return
      end
      for _, line in ipairs(data) do
        line = trim((line or ''):gsub('\r', ''))
        if line ~= '' then
          output[#output + 1] = line
        end
      end
    end,
    on_stderr = function(_, data)
      if data == nil then
        return
      end
      for _, line in ipairs(data) do
        line = trim((line or ''):gsub('\r', ''))
        if line ~= '' then
          output[#output + 1] = line
        end
      end
    end,
    on_exit = function(_, code)
      vim.schedule(function()
        on_done(code, output)
      end)
    end,
  })

  if job_id <= 0 then
    vim.notify('Failed to start `dotnet build` job', vim.log.levels.ERROR)
    on_done(1, {})
  end
end

local defaults = {
  netcoredbg_path = nil,
  configuration = 'Debug',
  build_before_debug = true,
  prompt_for_args = true,
}

M._opts = vim.deepcopy(defaults)

local function gather_runnable_projects(sln_path)
  local items = {}
  local projects = parse_sln_projects(sln_path)

  for _, p in ipairs(projects) do
    local info = parse_csproj_info(p.csproj)
    if info ~= nil and info.runnable then
      local tfm = choose_tfm(info.tfms)
      if tfm ~= nil then
        items[#items + 1] = {
          label = p.name .. '  [' .. tfm .. ']',
          name = p.name,
          csproj = p.csproj,
          project_dir = p.project_dir,
          tfm = tfm,
          assembly_name = info.assembly_name,
        }
      end
    end
  end

  table.sort(items, function(a, b)
    return a.label < b.label
  end)

  return items
end

local function start_debug(item, args_list)
  local ok, dap = pcall(require, 'dap')
  if not ok or dap == nil then
    vim.notify("nvim-dap is not installed (require('dap') failed)", vim.log.levels.ERROR)
    return
  end

  local configuration = M._opts.configuration
  local dll = compute_dll_path(item.project_dir, configuration, item.tfm, item.assembly_name)

  if not file_exists(dll) then
    vim.notify('Build output not found: ' .. dll, vim.log.levels.ERROR)
    return
  end

  dap.run {
    type = 'coreclr',
    name = 'dotnet: ' .. item.name,
    request = 'launch',
    program = dll,
    cwd = item.project_dir,
    args = args_list or {},
    justMyCode = false,
    stopAtEntry = false,
    console = 'integratedTerminal',
  }
end

local function prompt_args_then_start(item)
  if not M._opts.prompt_for_args then
    start_debug(item, {})
    return
  end

  vim.ui.input({ prompt = 'Args (space-separated, empty for none): ' }, function(input)
    local args_list = {}
    input = trim(input or '')
    if input ~= '' then
      for a in input:gmatch '%S+' do
        args_list[#args_list + 1] = a
      end
    end
    start_debug(item, args_list)
  end)
end

local function debug_selected(item)
  if item == nil then
    return
  end

  if not ensure_dap_adapter(M._opts.netcoredbg_path) then
    return
  end

  local configuration = M._opts.configuration

  local function after_build(code, build_output)
    if code ~= 0 then
      vim.notify('dotnet build failed (exit code ' .. tostring(code) .. ')', vim.log.levels.ERROR)
      if build_output ~= nil and #build_output > 0 then
        vim.notify(table.concat(build_output, '\n'), vim.log.levels.ERROR)
      end
      return
    end
    prompt_args_then_start(item)
  end

  if M._opts.build_before_debug then
    vim.notify('dotnet build ' .. item.name .. ' (' .. configuration .. ')', vim.log.levels.INFO)
    dotnet_build_project(item.csproj, item.project_dir, configuration, after_build)
    return
  end

  prompt_args_then_start(item)
end

function M.debug_menu()
  local sln_path = find_sln_path()
  if sln_path == nil then
    vim.notify('No .sln found (searches upward from current file, then downward from cwd)', vim.log.levels.ERROR)
    return
  end

  local sln_dir = normalize_path(vim.fs.dirname(sln_path))
  if sln_dir ~= nil and sln_dir ~= '' then
    vim.cmd('cd ' .. vim.fn.fnameescape(sln_dir))
  end

  local items = gather_runnable_projects(sln_path)
  if items == nil or #items == 0 then
    vim.notify('No runnable projects detected (check .sln parsing / TargetFramework / OutputType)', vim.log.levels.WARN)
    return
  end

  vim.ui.select(items, {
    prompt = 'Select project to debug:',
    format_item = function(it)
      return it.label
    end,
  }, function(choice)
    debug_selected(choice)
  end)
end

function M.build()
  M.debug_menu()
end

function M.setup(opts)
  M._opts = vim.tbl_deep_extend('force', vim.deepcopy(defaults), opts or {})

  vim.keymap.set('n', '<leader>md', function()
    M.debug_menu()
  end, { desc = 'dotnet debug (pick project from .sln)' })
end

return M
