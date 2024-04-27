local lspconfig = require('lspconfig')

local class_boiler_plate = "package %s;\n\npublic class %s{\n\n}"
local interface_boiler_plate = "package %s;\n\npublic interface %s{\n\n}"
local enum_boiler_plate = "package %s;\n\npublic enum %s{\n\n}"

local function get_spring_boot_project_root(open_file)
    local root_pattern = {"pom.xml", "build.gradle", ".git" }

    return lspconfig.util.root_pattern(unpack(root_pattern))(open_file)
end

local function find_main_application_class_directory(root_path)
    local main_class_pattern = '@SpringBootApplication'
    local java_file_pattern = '*.java'

    -- Find the Java file with the specified pattern recursively in the project directory
    local search_cmd = 'find ' .. root_path .. ' -type f -name "' .. java_file_pattern .. '" -exec grep -l "' .. main_class_pattern .. '" {} +'
    local result = vim.fn.systemlist(search_cmd)

    if not vim.tbl_isempty(result) then
        local first_file_path = result[1] -- Assuming there's only one main application class
        local directory = vim.fn.fnamemodify(first_file_path, ':h')
        return directory
    else
        print('Main application class not found in the project directory.')
    end
end

local function java_path(full_path)
    local pattern = "(.-)/java"
    return full_path:match(pattern) .. "/java"
end

local function generate_java_file(buf, type, package_buf, class_buf)
    local package_input = vim.api.nvim_buf_get_lines(tonumber(package_buf), 0, -1, false)
    local package_text = table.concat(package_input)
    local class_input = vim.api.nvim_buf_get_lines(tonumber(class_buf), 0, -1, false)
    local class_text = table.concat(class_input)
    if(class_text ~= '') then
        local dir = java_path(vim.api.nvim_buf_get_name(buf))
        -- Make sure the directory for the new file ends in a /
        local package_path = package_text:gsub("%.", "/")
        if(package_path:sub(-1, -1) ~= '/' and package_path ~= '') then
            package_path = package_path .. "/"
        end

        -- Create a new package if one does not exist
        if(vim.fn.isdirectory(dir .. '/' .. package_path) ~= 1) then
            local command = 'mkdir -p ' .. dir .. '/' .. package_path
            os.execute(command)
        end

        -- Strip trailing . for package import statement
        local package_import = package_text
        if(package_text:sub(-1, -1) == '.') then
            package_import = string.sub(package_import, 1, -2)
        end
        
        -- Generate file content
        local java_file_content
        if(type == 'class') then
            java_file_content = string.format(class_boiler_plate, package_import, class_text)
        end
        if(type == 'interface') then
            java_file_content = string.format(interface_boiler_plate, package_import, class_text)
        end
        if(type == 'enum') then
            java_file_content = string.format(enum_boiler_plate, package_import, class_text)
        end
        local java_file = io.open(dir .. "/" .. package_path .. class_text .. ".java", "r")
        
        if(java_file) then
            print("Java file already exists")
            java_file:close()
            return
        else
            java_file = io.open(dir .. "/" .. package_path .. class_text .. ".java", "w")
            if(java_file) then
                java_file:write(java_file_content)
                java_file:close()
            else
                print('an issue occured generating java file')
            end
        end 
        vim.cmd('q!')
        vim.cmd('edit ' .. dir .. '/' .. package_path .. class_text .. '.java')
    else
        print("Please specify a class name to continue")
    end

end

return {
    get_spring_boot_project_root = get_spring_boot_project_root,
    find_main_application_class_directory = find_main_application_class_directory,
    generate_java_file = generate_java_file
}
