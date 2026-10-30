local M = {}

local function has_source(frame)
  if not frame or not frame.source or not frame.line or frame.line < 1 then
    return false
  end

  local source = frame.source
  -- Embedded or adapter-provided source does not need a file on disk.
  if (source.sourceReference or 0) > 0 then
    return true
  end
  if not source.path or source.path == '' then
    return false
  end

  local path = source.path
  if path:match '^file://' then
    path = vim.uri_to_fname(path)
  elseif path:match '^%a[%w+.-]*://' then
    return true
  end

  local bufnr = vim.fn.bufnr(path)
  if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 2, false)
    if #lines > 1 or (lines[1] or '') ~= '' then
      return true
    end
  end
  return vim.fn.filereadable(path) == 1
end

function M.setup(dap, debug_adapter)
  local states = setmetatable({}, { __mode = 'k' })
  local key = 'dotnet_source_stepping'
  local function is_dotnet(config)
    return config and (config.type == 'coreclr' or config.type == debug_adapter)
  end

  dap.listeners.on_config[key] = function(config)
    if is_dotnet(config) then
      config.justMyCode = true
      config.enableStepFiltering = true
      -- Capture stop reasons and adapter errors if an async pause loses source.
      dap.set_log_level 'DEBUG'
    end
    return config
  end

  dap.listeners.before.event_stopped[key] = function(session, stopped)
    if not is_dotnet(session.config) then
      return
    end
    states[session] = {
      stopped = stopped,
    }
  end

  dap.listeners.before.stackTrace[key] = function(session, err, response, request)
    local state = states[session]
    if not state or state.handled or err or not response or not request then
      return
    end
    local stopped = state.stopped
    if not stopped or request.threadId ~= stopped.threadId or (request.startFrame or 0) ~= 0 then
      return
    end
    state.handled = true
    local frames = response.stackFrames or {}
    local frame = frames[1]
    if has_source(frame) then
      return
    end

    local source_frame
    for _, candidate in ipairs(frames) do
      if has_source(candidate) then
        source_frame = candidate
        break
      end
    end

    -- Only recover ordinary stepping/pause interruptions. Breakpoints and
    -- exceptions must remain available for inspection, even without source.
    local recover = stopped.reason == 'step' or stopped.reason == 'pause'
    if
      session.closed
      or session.stopped_thread_id ~= stopped.threadId
      or dap.session() ~= session
    then
      return
    end

    if recover then
      -- Use DAP's normal stepping path: it clears the running state BEFORE
      -- sending the request. A synthetic continued event in the response
      -- callback can erase a newer stop and leave F5 unable to resume it.
      -- Run inside the before listener so event_stopped sees the thread is
      -- running and never tries to open the unavailable library source.
      session:_step(source_frame and 'stepOut' or 'continue')
      return
    end

    vim.schedule(function()
      if
        session.closed
        or states[session] ~= state
        or session.stopped_thread_id ~= stopped.threadId
        or dap.session() ~= session
      then
        return
      end
      if source_frame then
        session:_frame_set(source_frame)
        vim.notify('Dotnet: showing a caller with source; execution is paused in a frame without source.', vim.log.levels.INFO)
      else
        vim.notify(
          'Dotnet: paused without source (' .. tostring(stopped.reason) .. '). Set a breakpoint after the await and press F5, or inspect the call stack.',
          vim.log.levels.WARN
        )
      end
    end)
  end

  dap.listeners.before.event_continued[key] = function(session)
    if states[session] then
      states[session].stopped = nil
    end
  end
  local function clear(session)
    states[session] = nil
  end
  dap.listeners.before.event_terminated[key] = clear
  dap.listeners.before.event_exited[key] = clear
  dap.listeners.after.disconnect[key] = clear
end

return M
