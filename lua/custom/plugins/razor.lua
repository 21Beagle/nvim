return {
  -- The Tree-sitter Razor grammar misparses mixed markup and @code blocks.
  'jlcrochet/vim-razor',
  lazy = false,
  config = function()
    local function semantic_colours()
      -- Roslyn uses extra token names that Neovim does not link by default.
      local links = {
        field = '@variable.member',
        extensionMethod = '@function.method',
        controlKeyword = '@keyword.conditional',
        stringEscapeCharacter = '@string.escape',
      }
      for token, target in pairs(links) do
        vim.api.nvim_set_hl(0, '@lsp.type.' .. token .. '.razor', { link = target, default = true })
      end
    end
    vim.api.nvim_create_autocmd('ColorScheme', {
      group = vim.api.nvim_create_augroup('razor-semantic-colours', { clear = true }),
      callback = semantic_colours,
    })
    semantic_colours()
  end,
}
