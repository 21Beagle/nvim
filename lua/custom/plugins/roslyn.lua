return {
  {
    'seblyng/roslyn.nvim',
    ft = { 'cs', 'csproj', 'sln', 'razor', 'cshtml' },
    lazy = false,

    config = function()
      local rzls_path = vim.fn.expand 'C:\\Users\\JackBeagle\\AppData\\Local\\nvim-data\\mason\\packages\\roslyn\\libexec\\.razorExtension'

      local cmd = {
        'roslyn',
        '--stdio',
        '--logLevel=Warning',
        '--extensionLogDirectory=' .. vim.fs.dirname(vim.lsp.get_log_path()),
        '--razorSourceGenerator=' .. vim.fs.joinpath(rzls_path, 'Microsoft.CodeAnalysis.Razor.Compiler.dll'),
        '--razorDesignTimePath=' .. vim.fs.joinpath(rzls_path, 'Targets', 'Microsoft.NET.Sdk.Razor.DesignTime.targets'),
        '--extension=' .. vim.fs.joinpath(rzls_path, 'Microsoft.VisualStudioCode.RazorExtension.dll'),
      }

      vim.lsp.config('roslyn', {
        cmd = cmd,

        -- This is the big one: stop spamming the server on every keystroke.
        flags = {
          debounce_text_changes = 250,
        },

        on_attach = function(client, bufnr)
          vim.diagnostic.config({
            update_in_insert = true,
          }, bufnr)
        end,
      })
    end,
    opts = {
      filewatching = 'auto',
    },
    keys = {
      {
        '<leader>mr',
        '<cmd>Roslyn restart<CR>',
        desc = '[R]oslyn restart',
      },
    },
  },
}
