local M = {}

function M.setup(dap)
  if M.installed then
    return
  end
  M.installed = true

  local nio = require 'nio'
  local invalidated = nio.control.event()
  local function invalidate()
    local previous = invalidated
    invalidated = nio.control.event()
    previous.set()
  end

  -- Variable references and stack frames belong to one suspended state.
  local key = 'custom_dapui_requests'
  for _, event in ipairs { 'event_continued', 'event_stopped', 'event_terminated', 'event_exited' } do
    dap.listeners.before[event][key] = invalidate
  end
  dap.listeners.after.disconnect[key] = invalidate
  dap.listeners.on_session[key] = invalidate

  local guarded = setmetatable({}, { __mode = 'k' })
  function M.guard(client)
    if guarded[client] then
      return client
    end
    guarded[client] = true
    for _, command in ipairs { 'variables', 'stackTrace' } do
      local request = client.request[command]
      client.request[command] = function(args)
        local state = invalidated
        return nio.first {
          function()
            return request(args)
          end,
          function()
            state.wait()
            error('DAP UI request belongs to an earlier execution state: ' .. command)
          end,
          function()
            nio.sleep(5000)
            error('DAP UI request timed out: ' .. command)
          end,
        }
      end
    end
    return client
  end

  local create_client = require 'dapui.client'
  package.loaded['dapui.client'] = function(...)
    return M.guard(create_client(...))
  end
end

return M
