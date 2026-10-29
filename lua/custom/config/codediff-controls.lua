local M = {}

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = 'CodeDiff' })
end

-- Saving this scratch buffer commits only the index. Closing it cancels.
local function commit(root, tabpage)
  local staged = vim.system({ 'git', 'diff', '--cached', '--quiet' }, { cwd = root }):wait()
  if staged.code == 0 then
    notify 'Stage some changes before committing.'
    return
  elseif staged.code ~= 1 then
    notify(staged.stderr, vim.log.levels.ERROR)
    return
  end

  local buf = vim.api.nvim_create_buf(true, true)
  vim.cmd 'botright 12split'
  vim.api.nvim_win_set_buf(0, buf)
  vim.api.nvim_buf_set_name(buf, 'codediff-commit://' .. buf)
  vim.bo[buf].buftype = 'acwrite'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = 'gitcommit'
  local summary = vim.system({ 'git', 'diff', '--cached', '--stat' }, { cwd = root, text = true }):wait()
  local lines = { '', '# Write a commit message above. :w commits staged changes; :q! cancels.', '#' }
  for line in (summary.stdout or ''):gmatch '[^\r\n]+' do
    lines[#lines + 1] = '# ' .. line
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modified = false
  vim.api.nvim_win_set_cursor(0, { 1, 0 })

  local busy = false
  vim.api.nvim_create_autocmd('BufWriteCmd', {
    buffer = buf,
    callback = function()
      if busy then
        notify 'Commit already running.'
        return
      end
      local message = {}
      for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
        if not line:match '^#' then
          message[#message + 1] = line
        end
      end
      if vim.trim(table.concat(message, '\n')) == '' then
        notify('Enter a commit message first.', vim.log.levels.WARN)
        return
      end

      local message_file = vim.fn.tempname()
      vim.fn.writefile(message, message_file)
      busy = true
      vim.bo[buf].modifiable = false
      vim.system({ 'git', 'commit', '--cleanup=strip', '--file', message_file }, { cwd = root, text = true }, function(result)
        vim.schedule(function()
          vim.fn.delete(message_file)
          busy = false
          if vim.api.nvim_buf_is_valid(buf) then
            vim.bo[buf].modifiable = true
          end
          if result.code ~= 0 then
            local details = vim.trim((result.stdout or '') .. '\n' .. (result.stderr or ''))
            notify(details ~= '' and details or ('Git commit failed (exit ' .. result.code .. '). Check your commit hooks.'), vim.log.levels.ERROR)
            return
          end
          notify(vim.trim(result.stdout or 'Commit created.'))
          if vim.api.nvim_buf_is_valid(buf) then
            vim.bo[buf].modified = false
            vim.api.nvim_buf_delete(buf, { force = true })
          end
          if vim.api.nvim_tabpage_is_valid(tabpage) and require('codediff.ui.lifecycle').get_session(tabpage) then
            require('codediff.ui.refresh').request(tabpage, { full = true })
          end
        end)
      end)
    end,
  })
  vim.keymap.set('n', '<C-s>', '<Cmd>write<CR>', { buffer = buf, desc = 'Commit staged changes' })
  vim.keymap.set('n', '<leader>cgc', '<Cmd>write<CR>', { buffer = buf, desc = 'Commit staged changes' })
end

local function attach(tabpage)
  local lifecycle = require 'codediff.ui.lifecycle'
  local explorer = lifecycle.get_panel_view(tabpage)
  if lifecycle.get_panel_name(tabpage) ~= 'explorer' or not explorer or not explorer.data.git_root then
    return
  end
  -- Revision comparisons and directory diffs must never mutate the index.
  if explorer.data.base_revision or explorer.data.target_revision then
    return
  end

  local function stage(want_staged)
    local data
    if vim.api.nvim_get_current_buf() == explorer.bufnr then
      local node = explorer.tree:get_node()
      data = node and node.data
    else
      data = { path = explorer.data.current_file_path, group = explorer.data.current_file_group }
    end
    if not data or not data.path or data.type == 'group' or data.type == 'directory' then
      notify 'Select a file first.'
      return
    end
    local expected = want_staged and 'unstaged' or 'staged'
    if data.group ~= expected and not (want_staged and data.group == 'conflicts') then
      notify(want_staged and 'Select a file under Changes to stage it.' or 'Select a file under Staged Changes to unstage it.')
      return
    end
    require('codediff.ui.explorer.actions').toggle_stage_file(explorer.data.git_root, data.path, data.group)
  end

  lifecycle.begin_keymap_scope(tabpage, 'custom-commit-controls')
  for _, binding in ipairs {
    {
      { '+', '<leader>cg+' },
      function()
        stage(true)
      end,
      'Stage selected file',
    },
    {
      { '-', '<leader>cg-' },
      function()
        stage(false)
      end,
      'Unstage selected file',
    },
    {
      { 'cc', '<leader>cgc' },
      function()
        commit(explorer.data.git_root, tabpage)
      end,
      'Commit staged changes (edit message)',
    },
  } do
    lifecycle.set_tab_keymap(tabpage, 'n', binding[1], binding[2], { desc = binding[3] })
  end
  lifecycle.end_keymap_scope(tabpage, 'custom-commit-controls')

  local ok, wk = pcall(require, 'which-key')
  if ok then
    for _, buf in ipairs { explorer.bufnr, lifecycle.get_buffers(tabpage) } do
      if buf and vim.api.nvim_buf_is_valid(buf) and not vim.b[buf].codediff_which_key then
        wk.add { { '<leader>cg', group = 'CodeDiff Git', buffer = buf } }
        vim.b[buf].codediff_which_key = true
      end
    end
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup('CustomCodeDiffControls', { clear = true })
  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = { 'CodeDiffOpen', 'CodeDiffFileSelect' },
    callback = function(event)
      local tabpage = event.data.tabpage
      vim.schedule(function()
        if vim.api.nvim_tabpage_is_valid(tabpage) then
          attach(tabpage)
        end
      end)
    end,
  })
  -- New files replace the diff buffers; use the session registry so these
  -- mappings are restored on entry and removed again when leaving the diff.
  vim.api.nvim_create_autocmd('BufEnter', {
    group = group,
    callback = function()
      local tabpage = vim.api.nvim_get_current_tabpage()
      vim.schedule(function()
        if vim.api.nvim_tabpage_is_valid(tabpage) and vim.api.nvim_get_current_tabpage() == tabpage then
          attach(tabpage)
        end
      end)
    end,
  })
end

return M
