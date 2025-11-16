return {
	{
		"mason-org/mason.nvim",
		opts = function(_, opts)
			-- Use BOTH the default registry and the roslyn one
			opts.registries = {
				"github:mason-org/mason-registry", -- default (stylua lives here)
				"github:Crashdummyy/mason-registry", -- extra roslyn registry
			}
		end,
	},
}
