return {
  {
    name = 'diag-float-3pane',
    dir = vim.fn.stdpath 'config',
    event = 'VeryLazy',
    config = function()
      pcall(vim.keymap.del, 'n', '<leader>sd')

      local ns = vim.api.nvim_create_namespace 'DiagFloat3Pane'

      local function clamp(v, lo, hi)
        if v < lo then
          return lo
        end
        if v > hi then
          return hi
        end
        return v
      end

      local function severity_icon(sev)
        if sev == vim.diagnostic.severity.ERROR then
          return '󰅚', 'DiagnosticError'
        end
        if sev == vim.diagnostic.severity.WARN then
          return '󰀪', 'DiagnosticWarn'
        end
        if sev == vim.diagnostic.severity.INFO then
          return '󰋽', 'DiagnosticInfo'
        end
        return '󰌶', 'DiagnosticHint'
      end

      local function norm_path(p)
        if package.config:sub(1, 1) == '\\' then
          return (p or ''):gsub('\\', '/')
        end
        return p or ''
      end

      local function rel_or_base(path)
        path = norm_path(path)
        local base = vim.fn.fnamemodify(path, ':t')
        if base == '' then
          return '[No file]'
        end
        return base
      end

      local function make_scratch(ft)
        local b = vim.api.nvim_create_buf(false, true)
        vim.bo[b].buftype = 'nofile'
        vim.bo[b].bufhidden = 'wipe'
        vim.bo[b].swapfile = false
        if ft then
          vim.bo[b].filetype = ft
        end
        return b
      end

      local function open_float(buf, o)
        local win_opts = {
          relative = 'editor',
          row = o.row,
          col = o.col,
          width = o.width,
          height = o.height,
          style = 'minimal',
          border = 'rounded',
          title = o.title,
          title_pos = 'center',
        }
        local win = vim.api.nvim_open_win(buf, false, win_opts)

        vim.wo[win].wrap = false
        vim.wo[win].signcolumn = 'no'
        vim.wo[win].cursorline = false
        vim.wo[win].number = false
        vim.wo[win].relativenumber = false
        vim.wo[win].foldcolumn = '0'
        vim.wo[win].spell = false

        vim.wo[win].winhighlight = 'Normal:NormalFloat,FloatBorder:FloatBorder,Title:FloatTitle,CursorLine:Visual,EndOfBuffer:NonText'
        vim.wo[win].winblend = 0

        return win
      end

      local function set_lines(buf, lines)
        vim.bo[buf].modifiable = true
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.bo[buf].modifiable = false
      end

      local function wrap_message(msg, max_width)
        msg = (msg or ''):gsub('\r', '')
        local out = {}
        for _, raw in ipairs(vim.split(msg, '\n', { plain = true })) do
          local line = raw
          while #line > max_width and max_width > 10 do
            out[#out + 1] = line:sub(1, max_width)
            line = line:sub(max_width + 1)
          end
          out[#out + 1] = line
        end
        return out
      end

      local function diag_items()
        local items = {}

        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_valid(buf) then
            local name = vim.api.nvim_buf_get_name(buf)
            if name ~= '' then
              for _, d in ipairs(vim.diagnostic.get(buf)) do
                items[#items + 1] = {
                  buf = buf,
                  path = name,
                  lnum = (d.lnum or 0),
                  col = (d.col or 0),
                  severity = d.severity or vim.diagnostic.severity.HINT,
                  message = d.message or '',
                  source = d.source or '',
                  code = d.code or '',
                }
              end
            end
          end
        end

        table.sort(items, function(a, b)
          if a.severity ~= b.severity then
            return a.severity < b.severity
          end
          if a.path ~= b.path then
            return a.path < b.path
          end
          if a.lnum ~= b.lnum then
            return a.lnum < b.lnum
          end
          return a.col < b.col
        end)

        return items
      end

      local function count_by_sev(items)
        local c = { e = 0, w = 0, i = 0, h = 0 }
        for _, it in ipairs(items) do
          if it.severity == vim.diagnostic.severity.ERROR then
            c.e = c.e + 1
          elseif it.severity == vim.diagnostic.severity.WARN then
            c.w = c.w + 1
          elseif it.severity == vim.diagnostic.severity.INFO then
            c.i = c.i + 1
          else
            c.h = c.h + 1
          end
        end
        return c
      end

      local function float_diag_ui()
        local items = diag_items()

        local editor_w = vim.o.columns
        local editor_h = vim.o.lines

        local pad = 3
        local gap = 2

        local w = clamp(editor_w - pad * 2, 100, 160)
        local h = clamp(editor_h - pad * 2, 26, 52)

        local row = pad
        local col = math.floor((editor_w - w) / 2)

        local msg_h = clamp(math.floor(h * 0.34), 9, 16)
        local top_h = h - msg_h - gap
        if top_h < 10 then
          top_h = 10
          msg_h = h - top_h - gap
        end

        local list_w = clamp(math.floor(w * 0.44), 44, 70)
        local code_w = w - list_w - gap
        if code_w < 40 then
          code_w = 40
          list_w = w - code_w - gap
        end

        local list_buf = make_scratch 'diaglist'
        local msg_buf = make_scratch 'markdown'
        local code_buf = make_scratch(nil)

        local list_win = open_float(list_buf, {
          row = row,
          col = col,
          width = list_w,
          height = top_h,
          title = 'Diagnostics',
        })

        local code_win = open_float(code_buf, {
          row = row,
          col = col + list_w + gap,
          width = code_w,
          height = top_h,
          title = 'Code',
        })

        local msg_win = open_float(msg_buf, {
          row = row + top_h + gap,
          col = col,
          width = w,
          height = msg_h,
          title = 'Message',
        })

        local counts = count_by_sev(items)
        pcall(vim.api.nvim_win_set_config, list_win, {
          title = string.format('Diagnostics  E:%d  W:%d  I:%d  H:%d', counts.e, counts.w, counts.i, counts.h),
          title_pos = 'center',
        })

        vim.wo[list_win].cursorline = true
        vim.wo[list_win].wrap = false

        vim.wo[code_win].number = true
        vim.wo[code_win].relativenumber = false
        vim.wo[code_win].cursorline = true

        vim.wo[msg_win].wrap = true

        local state = {
          items = items,
          index = 1,
          list_buf = list_buf,
          msg_buf = msg_buf,
          code_win = code_win,
          list_win = list_win,
          msg_win = msg_win,
          list_w = list_w,
          top_h = top_h,
          w = w,
          closed = false,
        }

        local function close_all()
          if state.closed then
            return
          end
          state.closed = true
          for _, winid in ipairs { list_win, code_win, msg_win } do
            if winid and vim.api.nvim_win_is_valid(winid) then
              pcall(vim.api.nvim_win_close, winid, true)
            end
          end
        end

        local function render_list()
          vim.api.nvim_buf_clear_namespace(state.list_buf, ns, 0, -1)

          local lines = {}
          local maxw = state.list_w

          local pos_w = 10
          local code_w2 = 12
          local file_w = clamp(maxw - 2 - 1 - pos_w - 1 - code_w2, 18, 80)

          local function trunc(s, ww)
            s = s or ''
            if #s <= ww then
              return s .. string.rep(' ', ww - #s)
            end
            if ww <= 1 then
              return s:sub(1, ww)
            end
            return s:sub(1, ww - 1) .. '…'
          end

          for _, it in ipairs(state.items) do
            local base = rel_or_base(it.path)
            local lnum = (it.lnum or 0) + 1
            local coln = (it.col or 0) + 1
            local icon = severity_icon(it.severity)
            local code = it.code and tostring(it.code) or ''

            local file_txt = trunc(base, file_w)
            local pos_txt = trunc(string.format('%d:%d', lnum, coln), pos_w)
            local code_txt = trunc(code, code_w2)

            lines[#lines + 1] = string.format('%s %s %s %s', icon, file_txt, pos_txt, code_txt)
          end

          if #lines == 0 then
            lines = { 'No diagnostics found.' }
          end

          set_lines(state.list_buf, lines)

          for i, it in ipairs(state.items) do
            local icon, sev_hl = severity_icon(it.severity)
            local code = it.code and tostring(it.code) or ''

            local icon_bytes = #icon
            local icon_end = icon_bytes + 1 -- include following space
            pcall(vim.api.nvim_buf_add_highlight, state.list_buf, ns, sev_hl, i - 1, 0, icon_end)

            local code_start = icon_end + file_w + 1 + pos_w + 1
            local code_end = code_start + code_w2

            if code ~= '' then
              pcall(vim.api.nvim_buf_add_highlight, state.list_buf, ns, sev_hl, i - 1, code_start, code_end)
            end
          end

          state.index = clamp(state.index, 1, math.max(1, #state.items))
          pcall(vim.api.nvim_win_set_cursor, state.list_win, { state.index, 0 })
        end

        local function show_code(it)
          if not it or not it.buf or not vim.api.nvim_buf_is_valid(it.buf) then
            return
          end

          vim.api.nvim_win_set_buf(state.code_win, it.buf)

          local lnum = (it.lnum or 0) + 1
          local coln = (it.col or 0)
          pcall(vim.api.nvim_win_set_cursor, state.code_win, { lnum, math.max(coln, 0) })

          vim.api.nvim_win_call(state.code_win, function()
            vim.cmd 'normal! zz'
          end)
        end

        local function show_message(it)
          if not it then
            set_lines(state.msg_buf, { '' })
            return
          end

          local base = rel_or_base(it.path)
          local lnum = (it.lnum or 0) + 1
          local coln = (it.col or 0) + 1

          local icon, hl = severity_icon(it.severity)
          local code = it.code and tostring(it.code) or ''
          local source = it.source and tostring(it.source) or ''

          local title = string.format('%s %s:%d:%d', icon, base, lnum, coln)
          if code ~= '' and source ~= '' then
            title = string.format('%s   %s • %s', title, source, code)
          elseif code ~= '' then
            title = string.format('%s   %s', title, code)
          elseif source ~= '' then
            title = string.format('%s   %s', title, source)
          end

          local wrap_w = state.w - 12
          local body = wrap_message(it.message or '', wrap_w)

          local lines = { '', '  ' .. title, '' }
          for _, l in ipairs(body) do
            lines[#lines + 1] = '  ' .. l
          end
          lines[#lines + 1] = ''

          set_lines(state.msg_buf, lines)

          vim.api.nvim_buf_clear_namespace(state.msg_buf, ns, 0, 3)
          pcall(vim.api.nvim_buf_add_highlight, state.msg_buf, ns, hl, 1, 2, -1)
        end

        local function apply_selection()
          if #state.items == 0 then
            return
          end
          state.index = clamp(state.index, 1, #state.items)
          local it = state.items[state.index]
          show_message(it)
          show_code(it)
          render_list()
        end

        local function move(delta)
          if #state.items == 0 then
            return
          end
          state.index = clamp(state.index + delta, 1, #state.items)
          apply_selection()
        end

        render_list()
        apply_selection()

        local function buf_map(lhs, rhs_fn, desc)
          vim.keymap.set('n', lhs, rhs_fn, { buffer = state.list_buf, noremap = true, silent = true, desc = desc })
        end

        buf_map('q', close_all, 'Close')
        buf_map('<Esc>', close_all, 'Close')
        buf_map('j', function()
          move(1)
        end, 'Down')
        buf_map('k', function()
          move(-1)
        end, 'Up')
        buf_map('<Down>', function()
          move(1)
        end, 'Down')
        buf_map('<Up>', function()
          move(-1)
        end, 'Up')
        buf_map('<C-d>', function()
          move(math.floor(state.top_h * 0.5))
        end, 'Page down')
        buf_map('<C-u>', function()
          move(-math.floor(state.top_h * 0.5))
        end, 'Page up')
        buf_map('gg', function()
          state.index = 1
          apply_selection()
        end, 'Top')
        buf_map('G', function()
          state.index = math.max(1, #state.items)
          apply_selection()
        end, 'Bottom')

        buf_map('<CR>', function()
          if #state.items == 0 then
            close_all()
            return
          end
          local it = state.items[state.index]
          close_all()
          if it and it.buf and vim.api.nvim_buf_is_valid(it.buf) then
            vim.api.nvim_set_current_buf(it.buf)
            pcall(vim.api.nvim_win_set_cursor, 0, { (it.lnum or 0) + 1, math.max(it.col or 0, 0) })
            vim.cmd 'normal! zz'
          end
        end, 'Open')

        vim.api.nvim_set_current_win(state.list_win)
      end

      vim.keymap.set('n', '<leader>sd', function()
        float_diag_ui()
      end, { desc = 'Diagnostics (floating 3-pane)' })
    end,
  },
}
