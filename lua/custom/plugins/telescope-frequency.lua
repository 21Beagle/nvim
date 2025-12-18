return { -- Sort files by frecency (frequency + recency)
  'nvim-telescope/telescope-frecency.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'kkharji/sqlite.lua',
  },
}
