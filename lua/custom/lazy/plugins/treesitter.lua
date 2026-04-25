return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    lazy = false,
    config = function()
      local ts = require 'nvim-treesitter'

      local parsers = {
        'bash',
        'c',
        'c_sharp',
        'diff',
        'html',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'query',
        'vim',
        'vimdoc',
      }

      vim.treesitter.language.register('bash', { 'bash', 'sh' })
      vim.treesitter.language.register('c_sharp', { 'cs', 'csharp' })

      local installed = {}
      for _, parser in ipairs(ts.get_installed 'parsers') do
        installed[parser] = true
      end

      local missing = {}
      for _, parser in ipairs(parsers) do
        if not installed[parser] then
          table.insert(missing, parser)
        end
      end

      if #missing > 0 then
        ts.install(missing)
      end

      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('treesitter-start', { clear = true }),
        pattern = {
          'bash',
          'c',
          'cs',
          'csharp',
          'diff',
          'help',
          'html',
          'lua',
          'markdown',
          'query',
          'sh',
          'vim',
          'vimdoc',
        },
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)

          local ok = pcall(require, 'nvim-treesitter')
          if ok then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end

          vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
          vim.wo.foldmethod = 'expr'
          vim.wo.foldlevel = 99
        end,
      })
    end,
  },
}
