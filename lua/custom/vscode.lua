local M = {}

M.enabled = vim.g.vscode ~= nil
local original_notify = vim.notify

local function vscode()
  local ok, api = pcall(require, 'vscode')
  if ok then
    return api
  end
  return nil
end

local function notify(message, level)
  local api = vscode()
  if api and api.notify then
    api.notify(message)
    return
  end

  vim.schedule(function()
    original_notify(message, level or vim.log.levels.INFO)
  end)
end

local function resolve_opts(opts)
  if type(opts) == 'function' then
    return opts()
  end

  if type(opts) ~= 'table' then
    return opts
  end

  local resolved = vim.tbl_extend('force', {}, opts)
  if type(resolved.args) == 'function' then
    resolved.args = resolved.args()
  end
  return resolved
end

local function action(command, opts)
  local api = vscode()
  if not api then
    notify('VS Code command unavailable: ' .. command, vim.log.levels.WARN)
    return
  end

  api.action(command, resolve_opts(opts) or {})
end

local function map(mode, lhs, command, desc, opts)
  vim.keymap.set(mode, lhs, function()
    action(command, opts)
  end, { noremap = true, silent = true, desc = desc })
end

local function repeat_action(command)
  return function()
    for _ = 1, vim.v.count1 do
      action(command)
    end
  end
end

function M.setup()
  if not M.enabled then
    return
  end

  vim.notify = notify

  vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlight' })
  vim.keymap.set('n', '<left>', '<nop>', { noremap = true, silent = true, desc = 'Disabled: use h' })
  vim.keymap.set('n', '<right>', '<nop>', { noremap = true, silent = true, desc = 'Disabled: use l' })
  vim.keymap.set('n', '<up>', '<nop>', { noremap = true, silent = true, desc = 'Disabled: use k' })
  vim.keymap.set('n', '<down>', '<nop>', { noremap = true, silent = true, desc = 'Disabled: use j' })

  vim.keymap.set('n', '<C-a>', 'ggVG', { noremap = true, silent = true, desc = 'Select all' })
  vim.keymap.set('n', '<C-y>', '<C-r>', { noremap = true, silent = true, desc = 'Redo' })
  vim.keymap.set('n', '<C-z>', 'u', { noremap = true, silent = true, desc = 'Undo' })
  vim.keymap.set('n', 'x', '"_x', { noremap = true, desc = 'Delete character without yanking' })
  vim.keymap.set('n', 'X', '"_X', { noremap = true, desc = 'Delete previous character without yanking' })
  vim.keymap.set('x', 'p', '"_dP', { noremap = true, silent = true, desc = 'Paste without replacing register' })
  vim.keymap.set('x', 'P', '"_dP', { noremap = true, silent = true, desc = 'Paste without replacing register' })

  map({ 'n', 'x' }, '<C-s>', 'workbench.action.files.save', 'Save file')
  map({ 'n', 't' }, '<C-t>', 'workbench.action.terminal.toggleTerminal', 'Toggle bottom terminal')
  map({ 'n', 'x' }, '<C-_>', 'editor.action.commentLine', 'Toggle comment')
  map('n', '<C-p>', 'csdevkit.debug.noDebugProjectLaunch', 'Dotnet run project')
  map('n', '<A-h>', 'workbench.action.navigateBack', 'Jump back')
  map('n', '<A-l>', 'workbench.action.navigateForward', 'Jump forward')
  map({ 'n', 'x' }, '<A-j>', 'editor.action.moveLinesDownAction', 'Move line/selection down')
  map({ 'n', 'x' }, '<A-k>', 'editor.action.moveLinesUpAction', 'Move line/selection up')
  map({ 'n', 'x' }, '<A-Down>', 'editor.action.moveLinesDownAction', 'Move line/selection down')
  map({ 'n', 'x' }, '<A-Up>', 'editor.action.moveLinesUpAction', 'Move line/selection up')
  map({ 'n', 'x', 'o' }, '<A-o>', 'editor.action.smartSelect.expand', 'Expand selection')
  map({ 'n', 'x', 'o' }, '<A-i>', 'editor.action.smartSelect.shrink', 'Shrink selection')

  vim.keymap.set('n', '<C-h>', repeat_action 'workbench.action.decreaseViewWidth', { noremap = true, silent = true, desc = 'Resize split left' })
  vim.keymap.set('n', '<C-l>', repeat_action 'workbench.action.increaseViewWidth', { noremap = true, silent = true, desc = 'Resize split right' })
  vim.keymap.set('n', '<C-j>', repeat_action 'workbench.action.decreaseViewHeight', { noremap = true, silent = true, desc = 'Resize split down' })
  vim.keymap.set('n', '<C-k>', repeat_action 'workbench.action.increaseViewHeight', { noremap = true, silent = true, desc = 'Resize split up' })

  map('n', '<leader>wh', 'workbench.action.focusLeftGroup', 'Move focus to the left editor group')
  map('n', '<leader>wl', 'workbench.action.focusRightGroup', 'Move focus to the right editor group')
  map('n', '<leader>wj', 'workbench.action.focusBelowGroup', 'Move focus to the lower editor group')
  map('n', '<leader>wk', 'workbench.action.focusAboveGroup', 'Move focus to the upper editor group')
  map('n', '<leader>wq', 'workbench.action.splitEditorRight', 'Split editor vertically')
  map('n', '<leader>we', 'workbench.action.splitEditorDown', 'Split editor horizontally')
  map('n', '<leader>wo', 'workbench.action.joinAllGroups', 'Close other editor groups')

  map('n', '<leader><leader>', 'workbench.action.quickOpen', 'Files in CWD by recency')
  map('n', '<leader>sh', 'workbench.action.showCommands', '[S]earch [H]elp')
  map('n', '<leader>sk', 'workbench.action.openGlobalKeybindings', '[S]earch [K]eymaps')
  map('n', '<leader>sf', 'workbench.action.quickOpen', '[S]earch [F]iles')
  map('n', '<leader>ss', 'workbench.action.gotoSymbol', '[S]earch [S]ymbols (document)')
  map('n', '<leader>sp', 'workbench.action.showCommands', '[S]earch [P]ickers')
  map('n', '<leader>sw', 'workbench.action.findInFiles', '[S]earch current [W]ord', { args = function() return { query = vim.fn.expand '<cword>' } end })
  map('n', '<leader>sg', 'workbench.action.findInFiles', '[S]earch by [G]rep')
  map('n', '<leader>sr', 'workbench.action.quickOpenPreviousRecentlyUsedEditorInGroup', '[S]earch [R]esume')
  map('n', '<leader>s.', 'workbench.action.quickOpenRecent', '[S]earch Recent Files')
  map('n', '<leader>sd', 'workbench.actions.view.problems', '[S]earch [D]iagnostics')
  map('n', '<leader>sb', 'workbench.action.showAllEditors', '[S]earch [B]uffers')
  map('n', '<leader>sB', 'actions.find', '[S]earch current [B]uffer')
  map('n', '<leader>s/', 'workbench.action.findInFiles', '[S]earch [/] in Open Files')
  map('n', '<leader>sn', 'workbench.action.openSettingsJson', '[S]earch [N]eovim files')
  map('n', '<leader>st', 'workbench.action.findInFiles', '[S]earch [T]odos', { args = { query = 'TODO|FIXME|HACK|NOTE|WARN', isRegex = true } })

  map('n', '<leader>e', 'workbench.files.action.focusFilesExplorer', 'Explorer')
  map('n', '[b', 'workbench.action.previousEditor', 'Previous buffer')
  map('n', ']b', 'workbench.action.nextEditor', 'Next buffer')
  map('n', '<leader>bd', 'workbench.action.closeActiveEditor', 'Delete buffer')
  map('n', '<leader>bo', 'workbench.action.closeOtherEditors', 'Close other buffers')

  map('n', '<leader>qo', 'workbench.actions.view.problems', '[Q]uickfix [O]pen')
  map('n', '<leader>qc', 'workbench.action.closePanel', '[Q]uickfix [C]lose')
  map('n', '<leader>qn', 'editor.action.marker.nextInFiles', '[Q]uickfix [N]ext item')
  map('n', '<leader>qp', 'editor.action.marker.prevInFiles', '[Q]uickfix [P]revious item')
  map('n', '<leader>ql', 'workbench.actions.view.problems', '[Q]uickfix [L]ocation list open')
  map('n', '<leader>qL', 'workbench.action.closePanel', '[Q]uickfix [L]ocation list close')
  map('n', ']q', 'editor.action.marker.nextInFiles', 'Next quickfix item')
  map('n', '[q', 'editor.action.marker.prevInFiles', 'Previous quickfix item')
  map('n', ']l', 'editor.action.marker.next', 'Next location-list item')
  map('n', '[l', 'editor.action.marker.prev', 'Previous location-list item')

  map('n', 'gd', 'editor.action.revealDefinition', 'Goto definition')
  map('n', 'gD', 'editor.action.goToDeclaration', 'Goto declaration')
  map('n', 'gr', 'editor.action.goToReferences', 'Goto references')
  map('n', 'gi', 'editor.action.goToImplementation', 'Goto implementation')
  map('n', 'go', 'workbench.action.gotoSymbol', 'Open document symbols')
  map('n', 'gw', 'workbench.action.showAllSymbols', 'Open workspace symbols')
  map('n', 'gt', 'editor.action.goToTypeDefinition', 'Goto type definition')
  map('n', 'K', 'editor.action.showHover', 'Hover documentation')
  map('n', '[d', 'editor.action.marker.prev', 'Previous diagnostic')
  map('n', ']d', 'editor.action.marker.next', 'Next diagnostic')
  map('n', '<leader>ca', 'editor.action.quickFix', '[C]ode [A]ction')
  map('x', '<leader>ca', 'editor.action.quickFix', '[C]ode [A]ction')
  map('n', '<leader>cr', 'editor.action.rename', '[C]ode [R]ename')
  map('n', '<leader>ce', 'editor.action.showHover', '[C]ode [E]xplain diagnostic')
  map('n', '<leader>cq', 'workbench.actions.view.problems', '[C]ode diagnostics to [Q]uickfix')
  map('n', '<leader>cf', 'editor.action.formatDocument', '[C]ode [F]ormat file')
  map('x', '<leader>cf', 'editor.action.formatSelection', '[C]ode [F]ormat selection')
  map('n', '<leader>cd', 'git.openChange', 'CodeDiff: open/focus/close')
  map('n', '<leader>ch', 'git.viewChanges', 'CodeDiff history: open/focus/close')

  map('n', ']c', 'workbench.action.editor.nextChange', 'Jump to next git change')
  map('n', '[c', 'workbench.action.editor.previousChange', 'Jump to previous git change')
  map({ 'n', 'x' }, '<leader>hs', 'git.stageSelectedRanges', 'Git stage hunk')
  map({ 'n', 'x' }, '<leader>hr', 'git.revertSelectedRanges', 'Git reset hunk')
  map('n', '<leader>hS', 'git.stageAll', 'Git stage buffer')
  map('n', '<leader>hu', 'git.unstage', 'Git undo stage hunk')
  map('n', '<leader>hR', 'git.clean', 'Git reset buffer')
  map('n', '<leader>hp', 'git.openChange', 'Git preview hunk')
  map('n', '<leader>hb', 'git.blame', 'Git blame line')
  map('n', '<leader>hd', 'git.openChange', 'Git diff against index')
  map('n', '<leader>hD', 'git.viewCommit', 'Git diff against last commit')
  map('n', '<leader>tb', 'git.blame', 'Toggle git show blame line')
  map('n', '<leader>tD', 'git.openChange', 'Toggle git show deleted')

  map('n', '<F5>', 'workbench.action.debug.start', 'Debug: Start/Continue')
  map('n', '<S-F5>', 'workbench.action.debug.stop', 'Debug: Stop')
  map('n', '<C-S-F5>', 'workbench.action.debug.restart', 'Debug: Restart')
  map('n', '<F9>', 'editor.debug.action.toggleBreakpoint', 'Debug: Toggle Breakpoint')
  map('n', '<S-F9>', 'editor.debug.action.conditionalBreakpoint', 'Debug: Conditional Breakpoint')
  map('n', '<C-F9>', 'editor.debug.action.addLogPoint', 'Debug: Logpoint')
  map('n', '<F10>', 'workbench.action.debug.stepOver', 'Debug: Step Over')
  map('n', '<F11>', 'workbench.action.debug.stepInto', 'Debug: Step Into')
  map('n', '<S-F11>', 'workbench.action.debug.stepOut', 'Debug: Step Out')
  map('n', '<C-F10>', 'editor.debug.action.runToCursor', 'Debug: Run to Cursor')
  map('n', '<F8>', 'workbench.action.debug.callStackDown', 'Debug: Down Stack')
  map('n', '<S-F8>', 'workbench.action.debug.callStackUp', 'Debug: Up Stack')
  map('n', '<F7>', 'workbench.view.debug', 'Debug: Toggle UI')
  map('n', '<leader>dc', 'workbench.action.debug.continue', 'Debug: Continue')
  map('n', '<leader>dq', 'workbench.action.debug.stop', 'Debug: Stop')
  map('n', '<leader>dr', 'workbench.action.debug.restart', 'Debug: Restart')
  map('n', '<leader>db', 'editor.debug.action.toggleBreakpoint', 'Debug: Toggle Breakpoint')
  map('n', '<leader>dB', 'editor.debug.action.conditionalBreakpoint', 'Debug: Conditional Breakpoint')
  map('n', '<leader>dl', 'editor.debug.action.addLogPoint', 'Debug: Logpoint')
  map('n', '<leader>dn', 'workbench.action.debug.stepOver', 'Debug: Step Over')
  map('n', '<leader>di', 'workbench.action.debug.stepInto', 'Debug: Step Into')
  map('n', '<leader>do', 'workbench.action.debug.stepOut', 'Debug: Step Out')
  map('n', '<leader>du', 'workbench.view.debug', 'Debug: Toggle UI')
  map('n', '<leader>de', 'editor.debug.action.selectionToRepl', 'Debug: Eval')
  map('n', '<leader>dh', 'editor.action.showHover', 'Debug: Eval Word')
  map('n', '<leader>dt', 'editor.debug.action.runToCursor', 'Debug: Run to Cursor')
  map('n', '<leader>dj', 'workbench.action.debug.callStackDown', 'Debug: Down Stack')
  map('n', '<leader>dk', 'workbench.action.debug.callStackUp', 'Debug: Up Stack')
  map('n', '<leader>dw', 'workbench.debug.action.focusWatchView', 'Debug: Watches')
  map('n', '<leader>ds', 'workbench.debug.action.focusVariablesView', 'Debug: Scopes')
  map('n', '<leader>dx', 'workbench.debug.action.focusCallStackView', 'Debug: Stacks')
  map('n', '<leader>dp', 'workbench.debug.action.focusBreakpointsView', 'Debug: Breakpoints')
  map('n', '<leader>df', 'workbench.debug.action.focusCallStackView', 'Debug: Frames')
  map('n', '<leader>dv', 'workbench.debug.action.focusVariablesView', 'Debug: Variables')

  map('n', '<leader>mc', 'csdevkit.cleanSolution', 'Dotnet clean solution')
  map('n', '<leader>mm', 'workbench.actions.view.problems', 'Dotnet workspace diagnostics')
  map('n', '<leader>mb', 'csdevkit.buildSolution', 'Dotnet build')
  map('n', '<leader>mB', 'csdevkit.buildSolution', 'Dotnet build with diagnostics')
  map('n', '<leader>md', 'csdevkit.debug.projectDebugLaunch', 'Dotnet debug')
  map('n', '<leader>ml', 'dotnet.restartServer', 'Dotnet restart LSP')
  map('n', '<leader>mL', 'dotnet.restore.all', 'Dotnet restore')
  map('n', '<leader>mR', 'csdevkit.debug.noDebugProjectLaunch', 'Dotnet run project')
  map('n', '<leader>ms', 'csdevkit.manageUserSecrets', 'Dotnet user secrets')
  map('n', '<leader>mt', 'workbench.view.testing', 'Dotnet test runner')
  map('n', '<leader>mr', 'dotnet.test.runTestsInContext', 'Dotnet run test from buffer')
  map('n', '<leader>ma', 'testing.runAll', 'Dotnet run all tests from buffer')
  map('n', '<leader>mp', 'testing.outputPeek.showResultOutput', 'Dotnet peek stack trace from buffer')
  map('n', '<leader>mT', 'testing.outputPeek.rerunFailed', 'Dotnet filter failed tests')
  map('n', '<leader>mf', 'editor.action.formatDocument', 'Dotnet format file')
  map('n', '<leader>mF', 'editor.action.formatDocument', 'Dotnet format solution')

  map('n', '<leader>nl', 'notifications.showList', 'Last message')
  map('n', '<leader>nh', 'notifications.showList', 'Message history')
  map('n', '<leader>nd', 'notifications.clearAll', 'Dismiss all')

  map('n', '<leader>uc', 'workbench.action.selectTheme', '[U]I [C]olorscheme picker')
  map('n', '<leader>un', 'workbench.action.selectTheme', '[U]I [N]ext colorscheme')
  map('n', '<leader>up', 'workbench.action.selectTheme', '[U]I [P]revious colorscheme')
  map('n', '<leader>R', 'workbench.action.reloadWindow', 'Restart VS Code window')
end

return M
