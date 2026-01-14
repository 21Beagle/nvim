return {
  {
    'dotnet-debug',
    dir = vim.fn.stdpath 'config',
    event = 'VeryLazy',
    keys = {
      {
        '<leader>md',
        function()
          require('custom.config.dotnet-debug').debug_menu()
        end,
        desc = 'dotnet debug (pick project from .sln)',
      },
    },
    config = function()
      require('custom.config.dotnet-debug').setup {
        netcoredbg_path = (vim.fn.stdpath 'data' .. '/mason/packages/netcoredbg/netcoredbg/netcoredbg.exe'):gsub('\\', '/'),
        configuration = 'Debug',
        build_before_debug = true,
        prompt_for_args = true,
      }
    end,
  },
}
