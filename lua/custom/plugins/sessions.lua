return {
  {
    'olimorris/persisted.nvim',
    lazy = false,
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
    },
    opts = {
      autostart = true,
      autoload = false,
      follow_cwd = true,

      -- Only save sessions for git repos (works with worktrees where .git is a file)
      should_save = function()
        local out = vim.fn.system { 'git', 'rev-parse', '--is-inside-work-tree' }
        if vim.v.shell_error ~= 0 then
          return false
        end
        out = (out or ''):gsub('%s+', '')
        return out == 'true'
      end,
    },
    config = function(_, opts)
      local function ensure_sessionoptions()
        local current = vim.o.sessionoptions or ''
        local have = {}
        for item in string.gmatch(current, '([^,]+)') do
          have[item] = true
        end

        -- Persisted expects sessionoptions to include curdir/globals for sane behavior. :contentReference[oaicite:2]{index=2}
        local desired = { 'buffers', 'curdir', 'folds', 'help', 'tabpages', 'winsize', 'globals' }
        local rebuilt = {}

        -- Keep existing first (stable), then append missing desired.
        for item in string.gmatch(current, '([^,]+)') do
          table.insert(rebuilt, item)
        end

        for _, item in ipairs(desired) do
          if not have[item] then
            table.insert(rebuilt, item)
          end
        end

        vim.o.sessionoptions = table.concat(rebuilt, ',')
      end

      local function get_git_root()
        local out = vim.fn.system { 'git', 'rev-parse', '--show-toplevel' }
        if vim.v.shell_error ~= 0 then
          return nil
        end
        out = (out or ''):gsub('%s+', '')
        if out == '' then
          return nil
        end
        return out
      end

      local function any_neo_tree_window_open()
        for _, winId in ipairs(vim.api.nvim_list_wins()) do
          local bufferId = vim.api.nvim_win_get_buf(winId)
          if vim.bo[bufferId].filetype == 'neo-tree' then
            return true
          end
        end
        return false
      end

      local function wipe_all_neo_tree_buffers()
        for _, bufferId in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(bufferId) and vim.bo[bufferId].filetype == 'neo-tree' then
            pcall(vim.api.nvim_buf_delete, bufferId, { force = true })
          end
        end
      end

      local function close_neo_tree()
        pcall(function()
          vim.cmd 'silent! Neotree close'
        end)
      end

      ensure_sessionoptions()

      require('persisted').setup(opts)
      require('telescope').load_extension 'persisted'

      local group = vim.api.nvim_create_augroup('PersistedNeoTree', { clear = true })

      -- BEFORE saving: close + wipe neo-tree so it never gets written into the session (prevents E95 on restore)
      vim.api.nvim_create_autocmd('User', {
        pattern = 'PersistedSavePre',
        group = group,
        callback = function()
          vim.g.persisted_neo_tree_open = any_neo_tree_window_open()
          close_neo_tree()
          wipe_all_neo_tree_buffers()
        end,
      })

      -- AFTER loading: force cwd to git root, and (optionally) reopen neo-tree rooted there
      vim.api.nvim_create_autocmd('User', {
        pattern = 'PersistedLoadPost',
        group = group,
        callback = function()
          vim.defer_fn(function()
            local root = get_git_root() or vim.fn.getcwd()
            if root and root ~= '' then
              pcall(vim.cmd, 'cd ' .. vim.fn.fnameescape(root))
            end

            if vim.g.persisted_neo_tree_open then
              -- Use a dir-rooted open so neo-tree matches the restored project root.
              pcall(vim.cmd, 'Neotree filesystem reveal left toggle dir=' .. vim.fn.fnameescape(root))
            end
          end, 50)
        end,
      })
    end,
  },
}
