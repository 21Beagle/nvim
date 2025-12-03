return {
	{
		"VidocqH/lsp-lens.nvim",
		event = "LspAttach",
		opts = {
			enable = true,
			include_declaration = false,
			defintion = false,
			git_authors = false,
			-- leave sections at their defaults; references are enabled by default
			-- and shown as "References: <count>"
		},
	},
}
