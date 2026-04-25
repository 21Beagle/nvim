return {
  { -- Fuzzy Finder (files, lsp, etc)
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { -- If encountering errors, see telescope-fzf-native README for installation instructions
        'nvim-telescope/telescope-fzf-native.nvim',

        -- `build` is used to run some command when the plugin is installed/updated.
        -- This is only run then, not every time Neovim starts up.
        build = 'make',

        -- `cond` is a condition used to determine whether this plugin should be
        -- installed and loaded.
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },

      -- Useful for getting pretty icons, but requires a Nerd Font.
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()
      -- Telescope is a fuzzy finder that comes with a lot of different things that
      -- it can fuzzy find! It's more than just a "file finder", it can search
      -- many different aspects of Neovim, your workspace, LSP, and more!
      --
      -- The easiest way to use Telescope, is to start by doing something like:
      --  :Telescope help_tags
      --
      -- After running this command, a window will open up and you're able to
      -- type in the prompt window. You'll see a list of `help_tags` options and
      -- a corresponding preview of the help.
      --
      -- Two important keymaps to use while in Telescope are:
      --  - Insert mode: <c-/>
      --  - Normal mode: ?
      --
      -- This opens a window that shows you all of the keymaps for the current
      -- Telescope picker. This is really useful to discover what Telescope can
      -- do as well as how to actually do it!

      -- [[ Configure Telescope ]]
      -- See `:help telescope` and `:help telescope.setup()`
      require('telescope').setup {
        defaults = {
          layout_strategy = 'horizontal',
          layout_config = {
            prompt_position = 'top',
          },
          sorting_strategy = 'ascending',

          -- show only file basename (tail), not full path
          path_display = { 'tail' },
        },

        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },

          frecency = {
            default_workspace = 'CWD',
            show_unindexed = true,

            -- Hide Neo-tree "filesystem" / pseudo-buffers from frecency
            -- (frecency can index non-file buffers unless you ignore them)
            ignore_patterns = {
              'term://*',
              'neo%-tree filesystem*',
              'neo%-tree popup*',
              'neo%-tree*',
            },
          },
        },
      }

      -- Enable Telescope extensions if they are installed
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      -- See `:help telescope.builtin`
      local builtin = require 'telescope.builtin'
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>ss', builtin.lsp_document_symbols, { desc = '[S]earch [S]ymbols (document)' })
      vim.keymap.set('n', '<leader>sp', builtin.builtin, { desc = '[S]earch [P]ickers (Telescope)' })
      vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })

      vim.keymap.set('n', '<leader>sd', function()
        local actions = require 'telescope.actions'
        local action_state = require 'telescope.actions.state'
        local pickers = require 'telescope.pickers'
        local finders = require 'telescope.finders'
        local conf = require('telescope.config').values
        local previewers = require 'telescope.previewers'
        local entry_display = require 'telescope.pickers.entry_display'

        local layout = {
          width = 0.78,
          height = 0.48,
          preview_width = 0.55,
          message_height = 5,
          gap = 1,
        }

        local msg_win = nil
        local msg_buf = nil

        local function close_msg()
          if msg_win and vim.api.nvim_win_is_valid(msg_win) then
            pcall(vim.api.nvim_win_close, msg_win, true)
          end

          msg_win = nil
          msg_buf = nil
        end

        local function make_msg_window()
          local width = math.floor(vim.o.columns * layout.width) - 2
          local picker_height = math.floor(vim.o.lines * layout.height)
          local picker_row = math.floor((vim.o.lines - picker_height - layout.message_height - layout.gap) / 2)
          local row = picker_row + picker_height + layout.gap
          local col = math.floor((vim.o.columns - width - 2) / 2)

          msg_buf = vim.api.nvim_create_buf(false, true)
          vim.bo[msg_buf].buftype = 'nofile'
          vim.bo[msg_buf].bufhidden = 'wipe'
          vim.bo[msg_buf].swapfile = false
          vim.bo[msg_buf].filetype = 'markdown'

          msg_win = vim.api.nvim_open_win(msg_buf, false, {
            relative = 'editor',
            row = row,
            col = col,
            width = width,
            height = layout.message_height,
            style = 'minimal',
            border = 'rounded',
            title = 'Diagnostic Message',
            title_pos = 'center',
            zindex = 200,
            focusable = false,
          })

          vim.wo[msg_win].wrap = true
          vim.wo[msg_win].number = false
          vim.wo[msg_win].relativenumber = false
          vim.wo[msg_win].signcolumn = 'no'
        end

        local function set_msg(lines)
          if not msg_buf or not vim.api.nvim_buf_is_valid(msg_buf) then
            return
          end

          vim.bo[msg_buf].modifiable = true
          vim.api.nvim_buf_set_lines(msg_buf, 0, -1, false, lines)
          vim.bo[msg_buf].modifiable = false
        end

        local function severity_rank(severity)
          if severity == vim.diagnostic.severity.ERROR then
            return 1
          end

          if severity == vim.diagnostic.severity.WARN then
            return 2
          end

          if severity == vim.diagnostic.severity.INFO then
            return 3
          end

          return 4
        end

        local function severity_label(severity)
          if severity == vim.diagnostic.severity.ERROR then
            return 'ERROR'
          end

          if severity == vim.diagnostic.severity.WARN then
            return 'WARN'
          end

          if severity == vim.diagnostic.severity.INFO then
            return 'INFO'
          end

          return 'HINT'
        end

        local function severity_icon(label)
          return ({
            ERROR = '󰅚',
            WARN = '󰀪',
            INFO = '󰋽',
            HINT = '󰌶',
          })[label] or '󰌶'
        end

        local function severity_hl(label)
          return ({
            ERROR = 'DiagnosticError',
            WARN = 'DiagnosticWarn',
            INFO = 'DiagnosticInfo',
            HINT = 'DiagnosticHint',
          })[label] or 'DiagnosticHint'
        end

        local function entry_message(entry)
          if not entry then
            return nil
          end

          if type(entry.value) == 'table' and entry.value.message then
            return entry.value.message
          end

          if entry.message then
            return entry.message
          end

          if entry.text then
            return entry.text
          end

          if entry.ordinal then
            return entry.ordinal
          end

          if entry.display then
            return tostring(entry.display)
          end

          return nil
        end

        local function entry_source(entry)
          if not entry then
            return ''
          end

          if type(entry.value) == 'table' and entry.value.source then
            return entry.value.source
          end

          if entry.source then
            return entry.source
          end

          return ''
        end

        local function entry_code(entry)
          if not entry then
            return ''
          end

          if type(entry.value) == 'table' and entry.value.code then
            return tostring(entry.value.code)
          end

          if entry.code then
            return tostring(entry.code)
          end

          return ''
        end

        local function entry_position(entry)
          if not entry then
            return nil, nil, nil
          end

          local bufnr = entry.bufnr
          local lnum = entry.lnum
          local col = entry.col

          if type(entry.value) == 'table' then
            bufnr = bufnr or entry.value.bufnr
            lnum = lnum or entry.value.lnum
            col = col or entry.value.col
          end

          if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
            return nil, nil, nil
          end

          if not lnum then
            return bufnr, 1, 0
          end

          return bufnr, lnum, col or 0
        end

        local function code_block(bufnr, lnum)
          local path = vim.api.nvim_buf_get_name(bufnr)
          local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

          if #lines == 1 and lines[1] == '' and path ~= '' and vim.fn.filereadable(path) == 1 then
            lines = vim.fn.readfile(path)
          end

          local total = #lines

          if total == 0 then
            return { '' }, 1, 1
          end

          lnum = math.max(1, math.min(lnum, total))

          local start_line = lnum
          local end_line = lnum

          while start_line > 1 do
            local line = lines[start_line - 1] or ''

            if line:match '^%s*$' then
              break
            end

            start_line = start_line - 1
          end

          while end_line < total do
            local line = lines[end_line + 1] or ''

            if line:match '^%s*$' then
              break
            end

            end_line = end_line + 1
          end

          local block = {}

          for i = start_line, end_line do
            block[#block + 1] = lines[i] or ''
          end

          if #block == 0 then
            block = { lines[lnum] or '' }
            start_line = lnum
            end_line = lnum
          end

          return block, start_line, end_line, lines[lnum] or ''
        end

        local function update_msg()
          local entry = action_state.get_selected_entry()

          if not entry then
            set_msg { 'No diagnostic selected.' }
            return
          end

          local message = entry_message(entry)
          local source = entry_source(entry)
          local code = entry_code(entry)

          if not message or message == '' then
            set_msg { 'No diagnostic message found.' }
            return
          end

          local lines = {}

          if source ~= '' or code ~= '' then
            lines[#lines + 1] = table.concat(
              vim.tbl_filter(function(part)
                return part ~= ''
              end, { source, code }),
              '  '
            )
            lines[#lines + 1] = ''
          end

          for _, line in ipairs(vim.split(message, '\n', { plain = true })) do
            lines[#lines + 1] = line
          end

          set_msg(lines)
        end

        local function yank_diagnostic()
          local entry = action_state.get_selected_entry()

          if not entry then
            vim.notify('No diagnostic selected', vim.log.levels.WARN)
            return
          end

          local bufnr, lnum, col = entry_position(entry)
          local message = entry_message(entry) or ''
          local source = entry_source(entry)
          local code = entry_code(entry)

          if not bufnr then
            vim.notify('Could not resolve diagnostic buffer', vim.log.levels.WARN)
            return
          end

          local path = vim.api.nvim_buf_get_name(bufnr)
          local file = path ~= '' and vim.fn.fnamemodify(path, ':.') or '[No file]'
          local block, start_line, end_line = code_block(bufnr, lnum)
          local problem_line = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ''

          local out = {}

          out[#out + 1] = file .. ':' .. lnum .. ':' .. ((col or 0) + 1)

          if source ~= '' or code ~= '' then
            out[#out + 1] = table.concat(
              vim.tbl_filter(function(part)
                return part ~= ''
              end, { source, code }),
              '  '
            )
          end

          out[#out + 1] = 'lines ' .. start_line .. '-' .. end_line

          for i, line in ipairs(block) do
            local line_no = start_line + i - 1
            local marker = line_no == lnum and '>> ' or '   '
            out[#out + 1] = marker .. line_no .. ': ' .. line
          end

          out[#out + 1] = ''
          out[#out + 1] = message
          out[#out + 1] = ''
          out[#out + 1] = 'problem line'
          out[#out + 1] = '>> ' .. lnum .. ': ' .. problem_line
          out[#out + 1] = ''

          local text = table.concat(out, '\n')

          vim.fn.setreg('"', text)
          vim.fn.setreg('+', text)

          vim.notify('Yanked diagnostic block', vim.log.levels.INFO)
        end

        local diagnostics = vim.diagnostic.get(nil)

        table.sort(diagnostics, function(a, b)
          local ar = severity_rank(a.severity)
          local br = severity_rank(b.severity)

          if ar ~= br then
            return ar < br
          end

          local an = vim.api.nvim_buf_get_name(a.bufnr)
          local bn = vim.api.nvim_buf_get_name(b.bufnr)

          if an ~= bn then
            return an < bn
          end

          if a.lnum ~= b.lnum then
            return a.lnum < b.lnum
          end

          return a.col < b.col
        end)

        local displayer = entry_display.create {
          separator = ' ',
          items = {
            { width = 2 },
            { width = 16 },
            { remaining = true },
            { width = 9 },
            { width = 12 },
          },
        }

        pickers
          .new({}, {
            prompt_title = 'Diagnostics',
            finder = finders.new_table {
              results = diagnostics,
              entry_maker = function(diagnostic)
                local bufnr = diagnostic.bufnr
                local path = vim.api.nvim_buf_get_name(bufnr)
                local file = path ~= '' and vim.fn.fnamemodify(path, ':t') or '[No file]'
                local rel = path ~= '' and vim.fn.fnamemodify(path, ':.') or '[No file]'
                local lnum = diagnostic.lnum + 1
                local col = diagnostic.col + 1
                local label = severity_label(diagnostic.severity)
                local icon = severity_icon(label)
                local hl = severity_hl(label)
                local message = diagnostic.message or ''
                local source = diagnostic.source or ''
                local code = diagnostic.code and tostring(diagnostic.code) or ''
                local code_text = code ~= '' and code or source
                local location = string.format('%d:%d', lnum, col)

                if code_text == '' then
                  code_text = label
                end

                local function make_display(entry)
                  return displayer {
                    { entry.icon, entry.hl },
                    { entry.code_text, entry.hl },
                    { entry.file, 'TelescopeResultsIdentifier' },
                    { entry.location, 'TelescopeResultsNumber' },
                    { entry.label, entry.hl },
                  }
                end

                return {
                  value = diagnostic,
                  display = make_display,
                  ordinal = string.format('%d %s %s %s %d %d %s', severity_rank(diagnostic.severity), label, code_text, rel, lnum, col, message),
                  filename = path,
                  bufnr = bufnr,
                  lnum = lnum,
                  col = diagnostic.col,
                  text = message,
                  message = message,
                  source = source,
                  code = code,
                  code_text = code_text,
                  file = file,
                  location = location,
                  label = label,
                  icon = icon,
                  hl = hl,
                }
              end,
            },
            sorter = conf.generic_sorter {},
            previewer = previewers.vim_buffer_vimgrep.new {},
            layout_strategy = 'horizontal',
            layout_config = {
              prompt_position = 'top',
              width = layout.width,
              height = layout.height,
              preview_width = layout.preview_width,
            },
            sorting_strategy = 'ascending',
            attach_mappings = function(prompt_bufnr, map)
              vim.defer_fn(function()
                make_msg_window()
                update_msg()
              end, 50)

              vim.api.nvim_create_autocmd({ 'WinClosed', 'BufLeave', 'BufWipeout' }, {
                buffer = prompt_bufnr,
                once = true,
                callback = close_msg,
              })

              local move_next = function()
                actions.move_selection_next(prompt_bufnr)
                vim.defer_fn(update_msg, 20)
              end

              local move_prev = function()
                actions.move_selection_previous(prompt_bufnr)
                vim.defer_fn(update_msg, 20)
              end

              local close = function()
                close_msg()
                actions.close(prompt_bufnr)
              end

              local select_default = function()
                close_msg()
                actions.select_default(prompt_bufnr)
              end

              map('i', '<Down>', move_next)
              map('i', '<Up>', move_prev)
              map('i', '<C-n>', move_next)
              map('i', '<C-p>', move_prev)
              map('i', '<CR>', select_default)
              map('i', '<C-y>', yank_diagnostic)

              map('n', 'j', move_next)
              map('n', 'k', move_prev)
              map('n', '<Down>', move_next)
              map('n', '<Up>', move_prev)
              map('n', '<CR>', select_default)
              map('n', 'q', close)
              map('n', '<Esc>', close)
              map('n', 'y', yank_diagnostic)

              return true
            end,
          })
          :find()
      end, { desc = '[S]earch [D]iagnostics' })

      vim.keymap.set('n', '<leader><leader>', function()
        require('telescope').extensions.frecency.frecency {
          workspace = 'CWD',
          initial_mode = 'insert',
        }
      end, { desc = '[ ] Files in CWD by recency', silent = true })

      vim.keymap.set('n', '<leader>sb', builtin.buffers, { desc = '[S]earch [B]uffers' })

      -- Slightly advanced example of overriding default behavior and theme
      vim.keymap.set('n', '<leader>sB', function()
        builtin.current_buffer_fuzzy_find {
          prompt_title = 'Search Current Buffer',
          layout_strategy = 'horizontal',
          layout_config = {
            prompt_position = 'top',
          },
          sorting_strategy = 'ascending',
          previewer = true,
        }
      end, { desc = '[S]earch current [B]uffer' })
      -- It's also possible to pass additional configuration options.
      --  See `:help telescope.builtin.live_grep()` for information about particular keys
      vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end, { desc = '[S]earch [/] in Open Files' })

      -- Shortcut for searching your Neovim configuration files
      vim.keymap.set('n', '<leader>sn', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = '[S]earch [N]eovim files' })
    end,
  },
}
