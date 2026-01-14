----------------------------------------------------------------------
-- dotnet debug -> pick runnable project from .sln -> nvim-dap (netcoredbg)
--
-- Keymap suggestion:
--   vim.keymap.set("n", "<leader>md", function() require("dotnet_debug").debug_sln() end)
----------------------------------------------------------------------

local M = {}

local function is_windows()
  return package.config:sub(1, 1) == '\\'
end

local function normalize_path(path)
  if path == nil then
    return nil
  end
  if is_windows() then
    return (path or ''):gsub('/', '\\')
  end
  return (path or ''):gsub('\\', '/')
end

local function path_sep()
  if is_windows() then
    return '\\'
  end
  return '/'
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

  local sep = path_sep()
  if a:sub(-1) == sep then
    return a .. b
  end
  return a .. sep .. b
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
        if not full:match '^%a:[/\\]' and not full:match '^[\\/]' then
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

local function is_coreclr_tfm(tfm)
  if tfm == nil then
    return false
  end
  local t = trim(tfm):lower()
  if t:match '^netcoreapp%d+%.%d+' ~= nil then
    return true
  end
  local major = t:match '^net(%d+)%.[%d]+'
  if major ~= nil then
    local n = tonumber(major)
    if n ~= nil and n >= 5 then
      return true
    end
  end
  return false
end

local function choose_coreclr_tfm(tfms)
  if tfms == nil or #tfms == 0 then
    return nil
  end

  local candidates = {}
  for _, tfm in ipairs(tfms) do
    if is_coreclr_tfm(tfm) then
      candidates[#candidates + 1] = tfm
    end
  end

  if #candidates == 0 then
    return nil
  end

  if is_windows() then
    for _, tfm in ipairs(candidates) do
      if tfm:lower():find('windows', 1, true) ~= nil then
        return tfm
      end
    end
  end

  return candidates[1]
end

local function parse_csproj_info(csproj_path)
  local text = read_file(csproj_path)
  if text == nil then
    return nil
  end

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

  return {
    assembly_name = assembly_name,
    tfms = tfms,
  }
end

local function compute_dll_path(project_dir, configuration, tfm, assembly_name)
  return path_join(path_join(path_join(project_dir, 'bin'), configuration), path_join(tfm, assembly_name .. '.dll'))
end

local defaults = {
  netcoredbg_path = nil,
  configuration = 'Debug',
  prompt_for_args = true,
  dap_log = true,
}

M._opts = vim.deepcopy(defaults)

local function ensure_dap_adapter()
  local ok, dap = pcall(require, 'dap')
  if not ok then
    vim.notify('nvim-dap not found', vim.log.levels.ERROR)
    return false
  end

  if M._opts.dap_log then
    dap.set_log_level 'TRACE'
  end

  dap.adapters.coreclr = {
    type = 'executable',
    command = M._opts.netcoredbg_path or 'netcoredbg',
    args = { '--interpreter=vscode' },
    detached = not is_windows(),
  }

  return true
end

local function start_debug(item, args_list)
  local ok, dap = pcall(require, 'dap')
  if not ok then
    return
  end

  -- Critical on Windows: prevent shellslash rewriting paths passed to tools.
  if is_windows() then
    vim.cmd 'set noshellslash'
  end

  local dll = compute_dll_path(item.project_dir, M._opts.configuration, item.tfm, item.assembly_name)

  dap.run {
    type = 'coreclr',
    name = 'dotnet: ' .. item.name,
    request = 'launch',
    program = dll,
    cwd = item.project_dir,
    args = args_list or {},
    justMyCode = false,
    stopAtEntry = false,

    -- Force this. Your log shows integratedTerminal, which tends to drag in extra thread/UI behaviour.
    console = 'internalConsole',
  }
end

function M.setup(opts)
  M._opts = vim.tbl_deep_extend('force', vim.deepcopy(defaults), opts or {})
  ensure_dap_adapter()
end

function M.debug_sln()
  if not ensure_dap_adapter() then
    return
  end

  local sln_path = find_sln_path()
  if sln_path == nil then
    vim.notify('No .sln found (searched upward from current file and then cwd).', vim.log.levels.ERROR)
    return
  end

  local projects = parse_sln_projects(sln_path)
  if projects == nil or #projects == 0 then
    vim.notify('No runnable projects found in solution: ' .. sln_path, vim.log.levels.ERROR)
    return
  end

  local items = {}
  for _, p in ipairs(projects) do
    local info = parse_csproj_info(p.csproj)
    if info ~= nil then
      local tfm = choose_coreclr_tfm(info.tfms)
      if tfm ~= nil then
        items[#items + 1] = {
          name = p.name,
          csproj = p.csproj,
          project_dir = p.project_dir,
          assembly_name = info.assembly_name,
          tfm = tfm,
        }
      end
    end
  end

  if #items == 0 then
    vim.notify('No CoreCLR-capable TFMs found in projects from: ' .. sln_path, vim.log.levels.ERROR)
    return
  end

  vim.ui.select(items, {
    prompt = 'Pick project to debug',
    format_item = function(it)
      return it.name .. '  [' .. it.tfm .. ']'
    end,
  }, function(choice)
    if choice == nil then
      return
    end

    local args_list = {}
    if M._opts.prompt_for_args then
      vim.ui.input({ prompt = 'Args (space-separated, blank for none): ' }, function(input)
        local s = trim(input or '')
        if s ~= '' then
          for a in s:gmatch '%S+' do
            args_list[#args_list + 1] = a
          end
        end
        start_debug(choice, args_list)
      end)
      return
    end

    start_debug(choice, args_list)
  end)
end

return M
