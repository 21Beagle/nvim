return {
	"stevearc/conform.nvim",
	opts = function(_, opts)
		opts.formatters = opts.formatters or {}
		opts.formatters_by_ft = opts.formatters_by_ft or {}

		opts.formatters.csharpier = {
			-- use the csharpier CLI directly
			command = "csharpier",
			-- format the current file on disk
			args = { "format", "$FILENAME" },
			stdin = false,
		}

		-- use csharpier for C# files
		opts.formatters_by_ft.cs = { "csharpier" }
	end,
}
