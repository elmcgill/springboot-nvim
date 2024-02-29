local lspconfig = require("lspconfig")

local function get_spring_boot_project_root()
    local current_file = vim.fn.expand("%:p")
    local root_pattern = {"pom.xml", "build.gradle", ".git" }

    return lspconfig.util.root_pattern(table.unpack(root_pattern))(current_file)
end

local function boot_run()
    local project_root = get_spring_boot_project_root()

    if project_root then
        print("Spring Boot project root: ", project_root)
    else
        print("Not in a Spring Boot project")
    end
end

return {
    boot_run = boot_run
}
