return {
	-- UI for debugging
	"rcarriga/nvim-dap-ui",
	dependencies = {
		"mfussenegger/nvim-dap",
	},
	config = function()
		require("config.nvim-dap-ui")
	end,
}
