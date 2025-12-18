return {
  {
    'seblyng/roslyn.nvim',
    ft = { 'cs', 'csproj', 'sln', 'razor', 'cshtml' },
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
