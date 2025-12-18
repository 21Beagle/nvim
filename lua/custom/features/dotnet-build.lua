return {
  {
    'dotnet-build-diags',
    dir = vim.fn.stdpath 'config',
    event = 'VeryLazy',
    keys = { {
      '<leader>mb',
      function()
        require('custom.config.dotnet-build').build()
      end,
      desc = 'dotnet build (populate diagnostics)',
    } },
    config = function()
      require('custom.dotnet-build').setup()
    end,
  },
}
