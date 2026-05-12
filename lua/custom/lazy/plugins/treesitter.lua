return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    lazy = false,
    config = function()
      vim.treesitter.language.register('bash', { 'sh' })
      vim.treesitter.language.register('c_sharp', { 'cs', 'csharp' })

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
          'razor',
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
