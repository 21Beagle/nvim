return {
	{
		"mason-org/mason.nvim",
		opts = function(_, opts)
			opts.registries = {
				"github:mason-org/mason-registry",
				"github:Crashdummyy/mason-registry",
			}
		end,
	},

	{
		"seblyng/roslyn.nvim",
		ft = "cs",
		opts = function()
			local util = require("lspconfig.util")
			return {
				filewatching = "roslyn",
				config = {
					root_dir = function(fname)
						return util.root_pattern("*.sln")(fname)
							or util.root_pattern("*.csproj")(fname)
							or util.root_pattern(".git")(fname)
					end,
				},
			}
		end,
	},
}
