local function safe_request(url)
	local status, request = pcall(function()
		return vim.system({ "curl", "-s", url }, { text = true }):wait()
	end)

	if not status then
		vim.api.nvim_err_writeln("Error making request to " .. url .. ": " .. request)
		return nil
	end

	return request
end

local function safe_json_decode(data)
	local status, decoded = pcall(vim.fn.json_decode, data)

	if not status then
		vim.api.nvim_err_writeln("Error decoding JSON: " .. decoded)
		return nil
	end

	return decoded
end

local function contains(list, element)
	for _, value in pairs(list) do
		if value == element then
			return true
		end
	end
	return false
end

local function list_to_string(list, is_err)
	local result = ""

	for i, value in ipairs(list) do
		if is_err then
			result = result .. "'" .. tostring(value) .. "'"
		else
			result = result .. tostring(value)
		end
		if i < #list then
			if is_err then
				result = result .. " or "
			else
				result = result .. "/"
			end
		end
	end
	return result
end

local function handle_start_springboot_data(data)
	local spring_data = {}
	for _, value in pairs(data.values) do
		table.insert(spring_data, value.id)
	end
	return spring_data
end

local function get_build_type(data_available)
	local build_type_available = list_to_string(data_available, false)
	local options_err = list_to_string(data_available, true)
	local build_type = vim.fn.input("Enter build type (" .. build_type_available .. "): ", "maven")
	if not contains(data_available, build_type) then
		print("Invalid build type. Please enter " .. options_err .. ".")
		return ""
	end

	return build_type
end

local function get_language(data_available)
	local language_available = list_to_string(data_available, false)
	local options_err = list_to_string(data_available, true)

	local language = vim.fn.input("Enter Language (" .. language_available .. "): ", "java")
	if not contains(data_available, language) then
		print("Invalid language. Please enter " .. options_err .. ".")
		return ""
	end

	return language
end

local function get_java_version(data_available)
	local version_available = list_to_string(data_available, false)
	local options_err = list_to_string(data_available, true)

	local java_version = vim.fn.input("Enter Java Version (" .. version_available .. "): ", "21")
	if not contains(data_available, java_version) then
		print("Invalid Java version. Please enter a valid version " .. options_err .. ".")
		return ""
	end

	return java_version
end

local function get_boot_version(data_available)
	local version_available = list_to_string(data_available, false)
	local options_err = list_to_string(data_available, true)

	local boot_version = vim.fn.input("Enter Spring Boot Version (" .. version_available .. "): ", data_available[#data_available])
	if not contains(data_available, boot_version) then
		print("Invalid Spring Boot version. Please enter a valid version " .. options_err .. ".")
		return ""
	end

	return boot_version
end

local function get_packaging(data_available)
	local packaging_available = list_to_string(data_available, false)
	local options_err = list_to_string(data_available, true)

	local packaging = vim.fn.input("Enter Packaging(" .. packaging_available .. "): ", "jar")
	if packaging ~= "jar" and packaging ~= "war" then
		print("Invalid packaging. Please enter " .. options_err .. ".")
		return ""
	end
	return packaging
end

local function springboot_new_project()
	local request = safe_request("https://start.spring.io/metadata/client")

	if not request then
		vim.api.nvim_err_writeln("Failed to make a request to the URL.")
		return false
	end

	local springboot_data = safe_json_decode(request.stdout)

	if not springboot_data then
		vim.api.nvim_err_writeln("Failed to decode JSON from the request.")
		return false
	end
	local build_types = { "maven", "gradle" }
	local languages = handle_start_springboot_data(springboot_data.language)
	local java_versions = handle_start_springboot_data(springboot_data.javaVersion)
	local boot_versions = handle_start_springboot_data(springboot_data.bootVersion)
	local packagings = handle_start_springboot_data(springboot_data.packaging)
	local build_type = get_build_type(build_types)

	if build_type:len() == 0 then
		return
	end

	local language = get_language(languages)
	if language:len() == 0 then
		return
	end

	local java_version = get_java_version(java_versions)
	if java_version:len() == 0 then
		return
	end

	local boot_version = get_boot_version(boot_versions)
	if boot_version:len() == 0 then
		return
	end

	local packaging = get_packaging(packagings)
	if packaging:len() == 0 then
		return
	end

	local dependencies = vim.fn.input("Enter dependencies (comma separated): ", "devtools,web,data-jpa,h2,thymeleaf")
	local group_id = vim.fn.input("Enter Group ID: ", "com.example")
	local artifact_id = vim.fn.input("Enter Artifact ID: ", "myproject")
	local name = vim.fn.input("Enter project name: ", artifact_id)
	local package_name = vim.fn.input("Enter package name: ", group_id .. "." .. artifact_id)

	local command = string.format(
		"spring init --boot-version=%s --java-version=%s --build=%s --dependencies=%s --groupId=%s --artifactId=%s --name=%s --package-name=%s %s",
		boot_version,
		java_version,
		build_type,
		dependencies,
		group_id,
		artifact_id,
		name,
		package_name,
		name
	)

	local output = vim.fn.system(command)
	if vim.v.shell_error ~= 0 then
		print("Erro ao executar: " .. output)
	else
		print(output)
		vim.fn.chdir(name)
		local pathJava = vim.fn.system("fd -I java src/main/java")

		vim.cmd("e " .. pathJava)
		vim.cmd(":NvimTreeFindFileToggl<CR>")
	end

	print("Project created successfully!")
end

vim.api.nvim_create_user_command("SpringBootNewProject", springboot_new_project, {})
