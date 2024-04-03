local api = vim.api
local buf, win
local start_buf

local windows
local bufs

local class_boiler_plate = "package %s;\n\npublic class %s{\n\n}"

local function generate_class()
    local file_path = vim.fn.fnamemodify(start_buf, ':p')
    local path_pattern = "(.-)/java"
    local root_path = file_path:match(path_pattern) .. "/java"
    -- Make sure there is content in the class buffer
    local class_lines = api.nvim_buf_get_lines(bufs[4], 0, -1, false)
    local class_content = table.concat(class_lines)
    local package_lines = api.nvim_buf_get_lines(bufs[3], 0, -1, false)
    local base_package_path = table.concat(package_lines)
    local package_path = base_package_path:gsub("%.", "/")
    if (package_path:sub(-1, -1) ~= '/' and package_path ~= '') then
        package_path = package_path .. "/"
    end

    if(class_content ~= '') then
        -- Check the specified package directory to make sure it exists
        if(vim.fn.isdirectory(root_path .. '/' .. package_path) == 1) then
            print("package directory exists")
        else
            -- Make the package directory if it does not exist
            local command = 'mkdir -p ' .. root_path .. '/' .. package_path
            os.execute(command)
        end
        -- Generate the new java file and inject boiler plate
        -- Need to strip and trailing periods from the package
        if(base_package_path:sub(-1, -1) == '.') then
            base_package_path = string.sub(base_package_path, 1, -2)
        end
        local java_file_content = string.format(class_boiler_plate, base_package_path, class_content)
        local java_file = io.open(root_path .. "/" .. package_path .. class_content .. ".java", "r")
        if(java_file) then
            print("Class already exists in package")
            java_file:close()
        else
            java_file = io.open(root_path .. "/" .. package_path .. class_content .. ".java", "w")
            java_file:write(java_file_content)
            java_file:close()
            close_generate_class()
            local path = root_path .. "/" .. package_path .. class_content .. ".java"
            vim.cmd('edit ' .. vim.fn.fnameescape(path))
        end
    else
        print("Please specify a class name to continue")
    end

end

local function create_package_ui(row, col, width, height, file_path)
    local package_buf = api.nvim_create_buf(false, true)
    --api.nvim_buf_set_option(package_buf, 'bufhidden', 'wipe')
    api.nvim_buf_set_option(package_buf, 'filetype', 'springbootnvim')
    
    local opts = {
        style = 'minimal',
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
        zindex = 102
    }
    local package = package_text(file_path)
    api.nvim_buf_set_lines(package_buf, 0, -1, false, {package})
    local package_win = api.nvim_open_win(package_buf, true, opts)
 
    table.insert(windows, package_win)
    table.insert(bufs, package_buf)
    return {
        buf = package_buf,
        win = package_win
    }

end

local function create_ui(bufnr)
    -- Get the file from where the generate class was called from
    start_buf = vim.fn.bufname(bufnr)
    local file_path = vim.fn.fnamemodify(start_buf, ':p')
    local project_root = get_spring_boot_project_root(file_path) 
    local main_class_dir =  find_main_application_class_directory(project_root)
    windows = {}
    bufs = {}
    -- Create buffer for popup
    buf = api.nvim_create_buf(false, true)
    table.insert(bufs, buf)
    api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    local border_buf = api.nvim_create_buf(false, true)
    table.insert(bufs, border_buf)
    --api.nvim_buf_set_option(border_buf, 'bufhidden', 'wipe')

    local width = 60
    local height = 8

    local row = math.floor((vim.fn.winheight(0) - height) / 2)
    local col = math.floor((vim.fn.winwidth(0) - width) / 2)

    local border_opts = {
        style = 'minimal',
        relative = 'editor',
        width = width + 2,
        height = height + 2,
        row = row - 1,
        col = col - 1,
        zindex = 99
    }

    local opts = {
        style = 'minimal',
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
        zindex = 100
    }

    local outline = draw_border(width, height)
    api.nvim_buf_set_lines(border_buf, 0, -1, false, outline)

    local border_win = api.nvim_open_win(border_buf, true, border_opts)
    table.insert(windows, border_win)
    win = api.nvim_open_win(buf, true, opts)
    table.insert(windows, win)
    --api.nvim_command('au BufWipeout <buffer> exe "silent bdelete! "' ..border_buf)
    
    --api.nvim_win_set_option(win, 'cursorline', true)
    
    api.nvim_buf_set_lines(buf, 0, -1, false, {center_text("Generate Class")})
    local package_section = draw_package_section()
    api.nvim_buf_set_lines(buf, 1, -1, false, package_section)
    local class_section = draw_class_section()
    api.nvim_buf_set_lines(buf, 5, -1, false, class_section)
    api.nvim_buf_set_lines(buf, 8, -1, false, {center_text('Confirm selections with <Enter>')})
    local package_area = create_package_ui(row + 2, col + 10, 48, 1, main_class_dir)
    local class_area = create_class_ui(row + 5, col + 10, 25, 1)
    api.nvim_set_current_win(package_area.win)
    local first_line = vim.fn.getline(1,1)
    local first_line_length = string.len(first_line[1])
    --api.nvim_feedkeys('a', 'n', true)
    api.nvim_win_set_cursor(package_area.win, {1,first_line_length})
    set_mappings()
end

return {
    create_ui = create_ui,
    close_generate_class = close_generate_class,
    navigate_to_class = navigate_to_class,
    navigate_to_package = navigate_to_package,
    generate_class = generate_class
}
