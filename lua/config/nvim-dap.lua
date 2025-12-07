local dap = require("dap")

dap.set_log_level("TRACE")

-- :DapLog command
vim.api.nvim_create_user_command("DapLog", function()
	local path = vim.fn.stdpath("cache") .. "/dap.log"
	vim.cmd("edit " .. path)
end, {})

----------------------------------------------------------------------
-- PATH HELPERS
----------------------------------------------------------------------

local path_sep = package.config:sub(1, 1)

local function join_paths(...)
	local parts = { ... }
	return table.concat(parts, path_sep)
end

local is_windows = vim.loop.os_uname().version:match("Windows") ~= nil

local function norm_path(p)
	if not is_windows then
		return p
	end
	-- Use backslashes for the debugger / PDBs
	return (p:gsub("/", "\\"))
end

----------------------------------------------------------------------
-- NETCOREDBG ADAPTER (WINDOWS)
----------------------------------------------------------------------

local mason_path = join_paths(vim.fn.stdpath("data"), "mason", "packages", "netcoredbg", "netcoredbg", "netcoredbg.exe")

dap.adapters.coreclr = {
	type = "executable",
	command = mason_path,
	args = { "--interpreter=vscode" },
}

----------------------------------------------------------------------
-- FIND SOLUTION FILE (.sln)
----------------------------------------------------------------------

local function find_solution()
	local cwd = vim.loop.cwd()

	local sln = vim.fs.find(function(name)
		return name:lower():match("%.sln$")
	end, {
		path = cwd,
		upward = true,
		limit = 1,
	})

	return sln[1]
end

----------------------------------------------------------------------
-- PARSE .SLN PROJECTS
----------------------------------------------------------------------

local function parse_sln_projects(sln_path)
	local sln_dir = vim.fn.fnamemodify(sln_path, ":h")
	local projects = {}

	for line in io.lines(sln_path) do
		local name, rel = line:match('Project%("%S+"%)%s*=%s*"([^"]+)",%s*"([^"]+)"')
		if name and rel then
			table.insert(projects, {
				name = name,
				rel = rel,
				csproj = join_paths(sln_dir, rel),
			})
		end
	end

	return projects
end

----------------------------------------------------------------------
-- PARSE .CSPROJ FOR OUTPUT TYPE / TFM / NAME
----------------------------------------------------------------------

local function parse_csproj(csproj_path)
	local xml = table.concat(vim.fn.readfile(csproj_path), "\n")

	local output = xml:match("<OutputType>%s*(.-)%s*</OutputType>")
	local tfm = xml:match("<TargetFramework>%s*(.-)%s*</TargetFramework>")
	local assembly = xml:match("<AssemblyName>%s*(.-)%s*</AssemblyName>")
	local title = xml:match("<AssemblyTitle>%s*(.-)%s*</AssemblyTitle>")

	return {
		output = output,
		tfm = tfm,
		assembly = assembly,
		title = title,
	}
end

----------------------------------------------------------------------
-- FIND RUNNABLE PROJECTS (DLL-BASED LAUNCH)
----------------------------------------------------------------------

local function find_runnable_projects()
	local sln_path = find_solution()
	if not sln_path then
		vim.notify("No .sln solution found.", vim.log.levels.ERROR)
		return {}
	end

	local projects = parse_sln_projects(sln_path)
	local runnable = {}

	for _, p in ipairs(projects) do
		if vim.loop.fs_stat(p.csproj) then
			local info = parse_csproj(p.csproj)

			-- Only projects that produce runnable outputs
			if info.output == "Exe" or info.output == "WinExe" then
				local project_dir = vim.fn.fnamemodify(p.csproj, ":h")
				local dll_name = info.assembly or p.name
				local tfm = info.tfm or "net8.0"

				local output_dir = join_paths(project_dir, "bin", "Debug", tfm)
				local dll_path = join_paths(output_dir, dll_name .. ".dll")

				table.insert(runnable, {
					name = dll_name,
					title = info.title or dll_name,
					tfm = tfm,
					output_dir = output_dir,
					dll = dll_path,
				})
			end
		end
	end

	return runnable
end

----------------------------------------------------------------------
-- PICK PROJECT
----------------------------------------------------------------------

local function pick_runnable_project(callback)
	local projects = find_runnable_projects()

	if #projects == 1 then
		vim.notify("No runnable (Exe/WinExe) projects found.", vim.log.levels.ERROR)
		return
	end

	if #projects == 2 then
		callback(projects[2].dll)
		return
	end

	vim.ui.select(projects, {
		prompt = "Select project to debug:",
		format_item = function(p)
			return string.format("%s (%s)", p.title, p.tfm)
		end,
	}, function(choice)
		if not choice then
			return
		end
		callback(choice.dll)
	end)
end

----------------------------------------------------------------------
-- START DEBUGGING USING DLL
----------------------------------------------------------------------

local function start_debug()
	pick_runnable_project(function(dll)
		if not vim.loop.fs_stat(dll) then
			vim.notify("DLL not found:\n" .. dll, vim.log.levels.ERROR)
			return
		end

		local program = norm_path(dll)
		local cwd = norm_path(vim.fn.fnamemodify(dll, ":h"))

		local config = {
			type = "coreclr",
			request = "launch",
			name = "Run",
			program = program,
			cwd = cwd,
			stopAtEntry = false,
			console = "internalConsole",
			justMyCode = false,
			requireExactSource = false,
		}

		-- Force this session to be treated as C# so symbols / filetype logic behave
		dap.run(config, { filetype = "cs" })
	end)
end

----------------------------------------------------------------------
-- KEYMAPS
----------------------------------------------------------------------

vim.keymap.set("n", "<F6>", start_debug, { noremap = true, silent = true })
vim.keymap.set("n", "<F11>", dap.step_over)
vim.keymap.set("n", "<F12>", dap.step_into)
vim.keymap.set("n", "<S-F12>", dap.step_out)
vim.keymap.set("n", "<F10>", dap.toggle_breakpoint)
