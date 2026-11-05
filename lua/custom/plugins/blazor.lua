return {
  'seblyng/roslyn.nvim',
  -- easy-dotnet already provides Roslyn for C# and Razor; avoid a second server.
  enabled = false,
  opts = {
    filewatching = 'off',
  },
}
