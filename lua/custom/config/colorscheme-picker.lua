local M = {}

local state = {
  schemes = nil,
  index = 1,
  last_applied = nil,
}

local function extract_name(path, ext)
  local pattern = '[\\/]colors[\\/](.+)%.' .. ext .. '$'
  return path:match(pattern)
end

local function list_colorschemes()
  local results = {}

  for _, p in ipairs(vim.api.nvim_get_runtime_file('colors/*.vim', true)) do
    local name = extract_name(p, 'vim')
    if name and name ~= '' then
      results[name] = true
    end
  end

  for _, p in ipairs(vim.api.nvim_get_runtime_file('colors/*.lua', true)) do
    local name = extract_name(p, 'lua')
    if name and name ~= '' then
      results[name] = true
    end
  end

  local out = {}
  for k in pairs(results) do
    out[#out + 1] = k
  end

  table.sort(out)
  return out
end

local function ensure_cache()
  if state.schemes then
    return
  end
  state.schemes = list_colorschemes()
  state.index = 1
end

local function notify(msg)
  vim.notify(msg, vim.log.levels.INFO, { title = 'Colorscheme' })
end

local function try_apply(name, silent)
  local ok = pcall(vim.cmd.colorscheme, name)
  if ok then
    state.last_applied = name
    if not silent then
      notify(name)
    end
    return true
  end
  return false
end

local function step(delta)
  ensure_cache()

  if #state.schemes == 0 then
    notify 'No colorschemes found in runtimepath'
    return
  end

  local start = state.index
  for _ = 1, #state.schemes do
    state.index = ((state.index - 1 + delta) % #state.schemes) + 1
    local name = state.schemes[state.index]
    if try_apply(name) then
      return
    end
  end

  state.index = start
  notify 'Could not apply any colorscheme (all failed)'
end

function M.next()
  step(1)
end

function M.prev()
  step(-1)
end

function M.refresh()
  state.schemes = nil
  ensure_cache()
  notify('Refreshed (' .. tostring(#state.schemes) .. ' found)')
end

function M.pick()
  ensure_cache()

  if #state.schemes == 0 then
    notify 'No colorschemes found in runtimepath'
    return
  end

  local ok = pcall(require, 'telescope')
  if not ok then
    notify 'Telescope not found: install nvim-telescope/telescope.nvim'
    return
  end

  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local conf = require('telescope.config').values
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'

  local original = vim.g.colors_name
  local committed = false

  local preview_timer = vim.uv.new_timer()
  local last_preview = nil

  local function stop_timer()
    if preview_timer then
      preview_timer:stop()
    end
  end

  local function update_index_for(name)
    for i, v in ipairs(state.schemes) do
      if v == name then
        state.index = i
        break
      end
    end
  end

  local function restore_original()
    stop_timer()
    if committed then
      return
    end
    if original and original ~= '' then
      try_apply(original, true)
    end
  end

  local function schedule_preview(name)
    if not name or name == '' then
      return
    end
    if name == last_preview then
      return
    end

    last_preview = name

    stop_timer()
    preview_timer:start(60, 0, function()
      vim.schedule(function()
        try_apply(name, true)
        update_index_for(name)
      end)
    end)
  end

  local function preview_current_selection()
    local entry = action_state.get_selected_entry()
    if not entry then
      return
    end

    local name = entry[1] or entry.value
    schedule_preview(name)
  end

  pickers
    .new({}, {
      prompt_title = 'Colorschemes',
      finder = finders.new_table { results = state.schemes },
      sorter = conf.generic_sorter {},
      attach_mappings = function(bufnr, _)
        local group = vim.api.nvim_create_augroup('colorscheme_picker_restore_' .. tostring(bufnr), { clear = true })

        vim.api.nvim_create_autocmd('BufLeave', {
          group = group,
          buffer = bufnr,
          once = true,
          callback = function()
            restore_original()
          end,
        })

        actions.move_selection_next:enhance {
          post = function()
            preview_current_selection()
          end,
        }

        actions.move_selection_previous:enhance {
          post = function()
            preview_current_selection()
          end,
        }

        actions.select_default:replace(function()
          committed = true
          stop_timer()

          local entry = action_state.get_selected_entry()
          if entry then
            local name = entry[1] or entry.value
            if name then
              try_apply(name, false)
              update_index_for(name)
            end
          end

          actions.close(bufnr)
        end)

        actions.close:enhance {
          post = function()
            restore_original()
          end,
        }

        vim.keymap.set('i', '<C-p>', function()
          preview_current_selection()
        end, { buffer = bufnr })

        vim.keymap.set('n', 'p', function()
          preview_current_selection()
        end, { buffer = bufnr })

        return true
      end,
    })
    :find()
end

return M
