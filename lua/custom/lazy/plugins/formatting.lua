return {
  {
    'stevearc/conform.nvim',
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>ff',
        function()
          require('conform').format {
            async = true,
            lsp_fallback = false,
          }
        end,
        mode = '',
        desc = '[F]ormat file (Conform)',
      },
      {
        '<leader>fd',
        function()
          local buf = vim.api.nvim_get_current_buf()
          local file = vim.api.nvim_buf_get_name(buf)

          if file == '' then
            vim.notify('No file for current buffer', vim.log.levels.ERROR)
            return
          end

          vim.cmd 'write'

          local start_dir = vim.fs.dirname(file)
          local sln = vim.fs.find(function(name)
            return name:match '%.sln$' ~= nil
          end, { upward = true, path = start_dir })[1]

          if not sln then
            vim.notify('No .sln found upward from: ' .. start_dir, vim.log.levels.ERROR)
            return
          end

          local root = vim.fs.dirname(sln)
          local rel = vim.fs.relpath(root, file)

          if not rel then
            vim.notify('Could not resolve file path relative to solution root', vim.log.levels.ERROR)
            return
          end

          rel = rel:gsub('\\', '/')

          vim.notify('dotnet format file: ' .. rel)

          vim.system({ 'dotnet', 'format', '--include', rel, '--verbosity', 'minimal' }, { cwd = root, text = true }, function(obj)
            vim.schedule(function()
              if obj.code ~= 0 then
                vim.notify(obj.stderr ~= '' and obj.stderr or 'dotnet format failed', vim.log.levels.ERROR)
                return
              end

              vim.notify 'dotnet format file complete'
              vim.cmd 'checktime'
            end)
          end)
        end,
        mode = '',
        desc = '[F]ormat file (dotnet format)',
      },
      {
        '<leader>fs',
        function()
          local buf = vim.api.nvim_get_current_buf()
          local file = vim.api.nvim_buf_get_name(buf)
          local start_dir = file ~= '' and vim.fs.dirname(file) or vim.fn.getcwd()

          local sln = vim.fs.find(function(name)
            return name:match '%.sln$' ~= nil
          end, { upward = true, path = start_dir })[1]

          if not sln then
            vim.notify('No .sln found upward from: ' .. start_dir, vim.log.levels.ERROR)
            return
          end

          local root = vim.fs.dirname(sln)

          vim.notify('dotnet format solution: ' .. root)

          vim.system({ 'dotnet', 'format', '--verbosity', 'minimal' }, { cwd = root, text = true }, function(obj)
            vim.schedule(function()
              if obj.code ~= 0 then
                vim.notify(obj.stderr ~= '' and obj.stderr or 'dotnet format failed', vim.log.levels.ERROR)
                return
              end

              vim.notify 'dotnet format solution complete'
              vim.cmd 'checktime'
            end)
          end)
        end,
        mode = '',
        desc = '[F]ormat solution (dotnet format)',
      },
    },
    opts = {
      notify_on_error = true,
      format_on_save = false,
      formatters_by_ft = {
        lua = { 'stylua' },
        cs = { 'csharpier' },
      },
    },
  },
}
