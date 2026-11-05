local M = {}

function M.dirs()
  local dirs, seen = {}, {}
  local function add(dir)
    if not dir then
      return
    end
    dir = vim.fs.normalize(vim.uv.fs_realpath(dir) or dir):gsub('/+$', '')
    local key = vim.fn.has 'win32' == 1 and dir:lower() or dir
    if not seen[key] and vim.fn.isdirectory(dir) == 1 then
      seen[key] = true
      dirs[#dirs + 1] = dir
    end
  end

  -- Keep recent projects first on the dashboard.
  for file in Snacks.dashboard.oldfiles() do
    add(Snacks.git.get_root(file))
  end

  local persisted = require 'persisted'
  for _, session in ipairs(persisted.list()) do
    local info = persisted.session_info(session)
    if not info.name then
      add(info.dir)
    end
  end

  -- Scan each time so newly cloned projects appear without restarting Neovim.
  local root = 'C:/Git/source/repos'
  local scan = vim.uv.fs_scandir(root)
  local discovered = {}
  if scan then
    while true do
      local name = vim.uv.fs_scandir_next(scan)
      if not name then
        break
      end
      if name:sub(1, 1) ~= '.' then
        discovered[#discovered + 1] = root .. '/' .. name
      end
    end
  end
  table.sort(discovered, function(a, b)
    return a:lower() < b:lower()
  end)
  for _, dir in ipairs(discovered) do
    add(dir)
  end
  return dirs
end

function M.items()
  return vim.tbl_map(function(dir)
    return { file = dir, text = dir, dir = true }
  end, M.dirs())
end

return M
