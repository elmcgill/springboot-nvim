local generate_class = require("springboot-nvim.generateclass")
local springboot_nvim_ui = require("springboot-nvim.ui.springboot_nvim_ui")
require("create_springboot_project")

local lspconfig = require("lspconfig")
local jdtls = require("jdtls")

local function incremental_compile()
	jdtls.compile("incremental")
end

local function is_plugin_installed(plugin)
	local status, _ = pcall(require, plugin)
	return status
end

local function get_spring_boot_project_root()
	local current_file = vim.fn.expand("%:p")
	if current_file == "" then
		print("No file is currently open.")
		return nil
	end

	local root_pattern = { "pom.xml", "build.gradle", "build.gradle.kts", ".git" }

	local root_dir = lspconfig.util.root_pattern(unpack(root_pattern))(current_file)
	if not root_dir then
		print("Project root not found.")
		return nil
	end

	return root_dir
end

local function get_run_command(args)
	local project_root = get_spring_boot_project_root()
	if not project_root then
		return "Unknown"
	end

	local maven_file = vim.fn.findfile("pom.xml", project_root)
	local gradle_file = vim.fn.findfile("build.gradle", project_root)
	local kts_gradle_file = vim.fn.findfile("build.gradle.kts", project_root)

	if maven_file ~= "" then
		return string.format(
			':call jobsend(b:terminal_job_id, "cd %s && mvn spring-boot:run %s \\n")',
			project_root,
			args or ""
		)
	elseif gradle_file or kts_gradle_file ~= "" then
		return string.format(
			':call jobsend(b:terminal_job_id, "cd %s && ./gradlew bootRun %s \\n")',
			project_root,
			args or ""
		)
	else
		print("No build file (pom.xml or build.gradle) found in the project root.")
		return "Unknown"
	end
end

local function boot_run(args)
	local project_root = get_spring_boot_project_root()

	if project_root then
		vim.cmd("split | terminal")
		vim.cmd("resize 15")
		vim.cmd("norm G")
		local cd_cmd = ':call jobsend(b:terminal_job_id, "cd ' .. project_root .. '\\n")'
		vim.cmd(cd_cmd)
		local run_cmd = get_run_command(args or "")
		vim.cmd(run_cmd)
		vim.cmd("wincmd k")
	else
		print("Not in a Spring Boot project")
	end
end

local function contains_package_info(file_path)
	local file = io.open(file_path, "r")
	if not file then
		return false
	end

	local has_package_info = false

	local line
	repeat
		line = file:read("*l")
		if line and string.match(line, "^package") then
			has_package_info = true
			break
		end
	until not line

	file:close()
	return has_package_info
end

local function get_java_package(file_path)
	local java_file_path = file_path:match("src/(.-)%.java")
	if java_file_path then
		local package_path = java_file_path:gsub("/", ".")

		local t = {}
		for str in string.gmatch(package_path, "([^.]+)") do
			table.insert(t, str)
		end

		local package = ""

		for i = 3, table.getn(t) - 1 do
			package = package .. "." .. t[i]
		end

		return string.sub(package, 2, -1)
	else
		return nil
	end
end

local function check_and_add_package()
	local file_path = vim.fn.expand("%:p")
	if not contains_package_info(file_path) then
		local package_location = get_java_package(file_path)
		local package_text = "package " .. package_location .. ";"
		local buf = vim.api.nvim_get_current_buf()
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { package_text, "", "" })
		vim.api.nvim_win_set_cursor(0, { 3, 0 })
	end
end

local function fill_package_details()
	check_and_add_package()
end

-- key mapping

-- auto commands
local function setup()
	vim.api.nvim_exec(
		[[
    augroup JavaAutoCommands
        autocmd!
        autocmd BufWritePost *.java lua require('springboot-nvim').incremental_compile()
    augroup END
]],
		false
	)

	vim.api.nvim_exec(
		[[
    augroup JavaPackageDetails
    autocmd!
    autocmd BufReadPost *.java lua require('springboot-nvim').fill_package_details()
    augroup END
]],
		false
	)

	vim.api.nvim_exec(
		[[
  augroup ClosePluginBuffers
    autocmd!
    autocmd FileType springbootnvim autocmd QuitPre * lua require('springboot-nvim').close_ui()
  augroup END
]],
		false
	)
end

return {
	setup = setup,
	boot_run = boot_run,
	incremental_compile = incremental_compile,
	fill_package_details = fill_package_details,
	foo = foo,
	create_ui = generate_class.create_ui,
	close_ui = springboot_nvim_ui.close_ui,
	generate_class = springboot_nvim_ui.create_generate_class_ui,
	generate_record = springboot_nvim_ui.create_generate_record_ui,
	generate_interface = springboot_nvim_ui.create_generate_interface_ui,
	generate_enum = springboot_nvim_ui.create_generate_enum_ui,
}
