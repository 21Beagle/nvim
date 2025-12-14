return {
  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      opts = opts or {}
      opts.registries = {
        'github:mason-org/mason-registry',
        'github:Crashdummyy/mason-registry',
      }
      return opts
    end,
  },
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    opts = function(_, opts)
      opts = opts or {}
      opts.ensure_installed = opts.ensure_installed or {}
      table.insert(opts.ensure_installed, 'roslyn')
      return opts
    end,
  },
}
