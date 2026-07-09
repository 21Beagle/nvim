return {
  "rpollard00/endofline-club.nvim",
  event = "LspAttach",
  config = function()
    require("endofline-club").setup()
  end,
}
