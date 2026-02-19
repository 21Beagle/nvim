return { -- Collection of various small independent plugins/modules
  'echasnovski/mini.nvim',
  config = function()
    -- Better Around/Inside textobjects
    --
    -- Examples:
    --  - va)  - [V]isually select [A]round [)]paren
    --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
    --  - ci'  - [C]hange [I]nside [']quote
    require('mini.ai').setup { n_lines = 500 }

    -- Add/delete/replace surroundings (brackets, quotes, etc.)
    --
    -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
    -- - sd'   - [S]urround [D]elete [']quotes
    -- - sr)'  - [S]urround [R]eplace [)] [']
    require('mini.surround').setup {
      mappings = {
        add = 'sa',
        delete = 'sd',
        replace = 'sr',
        find = 'sf',
        find_left = 'sF',
        highlight = 'sh',
        update_n_lines = 'sn',
      },
    }

    local statusline = require 'mini.statusline'
    statusline.setup { use_icons = vim.g.have_nerd_font }

    -- keep your location override if you want
    statusline.section_location = function()
      return '%2l:%-2v'
    end

    local function cmdline_preview()
      local t = vim.fn.getcmdtype()
      if t == '' then
        return ''
      end

      local line = vim.fn.getcmdline()
      if line == '' then
        return t
      end

      -- Make it readable + not huge
      line = line:gsub('\n', '⏎')
      local max = 60
      if #line > max then
        line = '…' .. line:sub(#line - max + 1)
      end

      return ('%s%s'):format(t, line) -- e.g. :w, /foo, ?bar
    end

    -- Store last recorded macro (register + text) so we can display it
    vim.g._last_macro_reg = vim.g._last_macro_reg or ''
    vim.g._last_macro_txt = vim.g._last_macro_txt or ''

    -- Save original fileinfo section (mini version dependent)
    local orig_fileinfo = statusline.section_fileinfo

    local function pretty_macro(reg)
      if reg == nil or reg == '' then
        return ''
      end
      local txt = vim.fn.getreg(reg)

      -- Make it single-line + more readable
      txt = txt:gsub('\n', '⏎')

      -- Translate keycodes (like <Esc>) if available
      if vim.fn.exists '*keytrans' == 1 then
        txt = vim.fn.keytrans(txt)
      end

      -- Truncate so it doesn't eat the whole statusline
      local max = 40
      if #txt > max then
        txt = txt:sub(1, max) .. '…'
      end

      return ('@%s:%s'):format(reg, txt)
    end

    -- Show recording status OR last recorded macro
    statusline.section_fileinfo = function(args)
      local rec = vim.fn.reg_recording()
      local left = ''

      if rec ~= '' then
        left = ('Recording @%s '):format(rec)
      elseif vim.g._last_macro_reg ~= '' then
        left = (pretty_macro(vim.g._last_macro_reg) .. ' ')
      end

      local cmd = cmdline_preview()
      if cmd ~= '' then
        left = cmd .. '  ' .. left
      end

      return left .. orig_fileinfo(args)
    end

    -- Refresh statusline and capture macro on stop
    vim.api.nvim_create_autocmd('RecordingEnter', {
      callback = function()
        vim.cmd 'redrawstatus'
      end,
    })

    vim.api.nvim_create_autocmd('RecordingLeave', {
      callback = function()
        -- This returns the register used for the recording that just ended
        local reg = vim.fn.reg_recorded()
        if reg ~= nil and reg ~= '' then
          vim.g._last_macro_reg = reg
          vim.g._last_macro_txt = vim.fn.getreg(reg)
        end
        vim.cmd 'redrawstatus'
      end,
    })

    -- ... and there is more!
    --  Check out: https://github.com/echasnovski/mini.nvim
  end,
}
