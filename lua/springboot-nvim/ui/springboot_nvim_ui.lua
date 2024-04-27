local ui_utils = require"springboot-nvim.ui.ui_utils"
local utils = require"springboot-nvim.utils"

local api = vim.api
local components

local function close_ui()
    if(components ~= nil) then
        local bufs = components.bufs
        local wins = components.wins
        for _, win_id in pairs(wins) do
            if(api.nvim_win_is_valid(win_id)) then
                api.nvim_win_close(win_id, true)
            end
        end

        for _,buf_id in pairs(bufs) do
            if(api.nvim_buf_is_valid(buf_id)) then
                api.nvim_buf_delete(buf_id, { force = true })
            end
        end

        components = nil
    else
        return
    end
end

local function navigate_to_package()
    -- When k is pressed we want to navigate the user to package buf/window
    api.nvim_set_current_win(components.wins.package_win)
end

local function navigate_to_class()
    -- When j is pressed we want to navigate the user to class buf/window
    api.nvim_set_current_win(components.wins.class_win)
end

local function navigate_to_interface()
    -- When j is pressed we want to navigate the user to class buf/window
    api.nvim_set_current_win(components.wins.interface_win)
end

local function navigate_to_enum()
    -- When j is pressed we want to navigate the user to class buf/window
    api.nvim_set_current_win(components.wins.enum_win)
end

local function set_mappings(start_buf, bufs, type)
    --api.nvim_buf_set_keymap(buf, 'n', '<cr>', ':lua require("springboot-nvim.generateclass").generate_class()<cr>', {nowait=true, noremap=true, silent=true})
    for _,b in pairs(bufs) do
        api.nvim_buf_set_keymap(b, 'n', 'k', ':lua require("springboot-nvim.ui.springboot_nvim_ui").navigate_to_package()<cr>', {nowait=true, noremap=true, silent=true})
        if type == "class" then
            api.nvim_buf_set_keymap(b, 'n', 'j', ':lua require("springboot-nvim.ui.springboot_nvim_ui").navigate_to_class()<cr>', {nowait=true, noremap=true, silent=true})
            api.nvim_buf_set_keymap(b, 'n', '<cr>', ':lua require("springboot-nvim.utils").generate_java_file(' .. start_buf .. ',"' .. type .. '","' .. bufs.package_buf.. '","' .. bufs.class_buf .. '")<cr>', {nowait=true, noremap=true, silent=true}) 
        end
        if(type == "interface") then
            api.nvim_buf_set_keymap(b, 'n', 'j', ':lua require("springboot-nvim.ui.springboot_nvim_ui").navigate_to_interface()<cr>', {nowait=true, noremap=true, silent=true})
            api.nvim_buf_set_keymap(b, 'n', '<cr>', ':lua require("springboot-nvim.utils").generate_java_file(' .. start_buf .. ',"' .. type .. '","' .. bufs.package_buf.. '","' .. bufs.interface_buf .. '")<cr>', {nowait=true, noremap=true, silent=true})
        end
        if(type == "enum") then
            api.nvim_buf_set_keymap(b, 'n', 'j', ':lua require("springboot-nvim.ui.springboot_nvim_ui").navigate_to_enum()<cr>', {nowait=true, noremap=true, silent=true})
            api.nvim_buf_set_keymap(b, 'n', '<cr>', ':lua require("springboot-nvim.utils").generate_java_file(' .. start_buf .. ',"' .. type .. '","' .. bufs.package_buf.. '","' .. bufs.enum_buf .. '")<cr>', {nowait=true, noremap=true, silent=true})
        end
        api.nvim_buf_set_keymap(b, 'n', 'q', ':lua require("springboot-nvim.ui.springboot_nvim_ui").close_ui()<cr>', {nowait=true, noremap=true, silent=true})
        api.nvim_buf_set_keymap(b, 'i', '<cr>', '', {nowait=true, noremap=true, silent=true})
        api.nvim_buf_set_keymap(b, 'i', '<Tab>', '', {nowait=true, noremap=true, silent=true})
        api.nvim_buf_set_keymap(b, 'n',  '<c-k>', '', { nowait = true, noremap = true, silent = true })
        api.nvim_buf_set_keymap(b, 'n',  '<c-j>', '', { nowait = true, noremap = true, silent = true })
        api.nvim_buf_set_keymap(b, 'i',  '<c-k>', '', { nowait = true, noremap = true, silent = true })
        api.nvim_buf_set_keymap(b, 'i',  '<c-j>', '', { nowait = true, noremap = true, silent = true })

    end

    local other_chars = {
        'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'l', 'n', 'o', 'p', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
    }
    for _,b in ipairs(bufs) do
        for _,v in ipairs(other_chars) do
            api.nvim_buf_set_keymap(b, 'n', v, '', { nowait = true, noremap = true, silent = true })
            api.nvim_buf_set_keymap(b, 'n', v:upper(), '', { nowait = true, noremap = true, silent = true })
            api.nvim_buf_set_keymap(b, 'n',  '<c-'..v..'>', '', { nowait = true, noremap = true, silent = true })
        end
    end
end

local function create_generate_class_ui()

    local bufnr = vim.api.nvim_get_current_buf()

    if components ~= nil then
        print('You cannot open multiple generate modals at a time')
        return
    end

    local project_root = utils.get_spring_boot_project_root(vim.fn.fnamemodify(bufnr, ':p'))
    local main_class = utils.find_main_application_class_directory(project_root)
    local width = 60
    local height = 9

    local row = math.floor((vim.fn.winheight(0) - height) / 2)
    local col = math.floor((vim.fn.winwidth(0) - width) / 2)
    local popup_components = ui_utils.draw_popup(width, height, row, col, "Generate Class")
    local package_components = ui_utils.draw_labeled_input(46, 1, row+1, col+1, "Package: ", popup_components.popup_buf, ui_utils.package_text(main_class))
    local class_components = ui_utils.draw_labeled_input(46, 1, row+4, col+1, "Class: ", popup_components.popup_buf, "")
    components = {
        bufs = {
            popup_buf = popup_components.popup_buf,
            border_buf = popup_components.border_buf,
            package_buf = package_components.input_buf,
            class_buf = class_components.input_buf,
        },
        wins = {
            popup_win = popup_components.popup_win,
            border_win = popup_components.border_win,
            package_win = package_components.input_win,
            class_win = class_components.input_win
        }
    }
    set_mappings(bufnr, components.bufs, 'class')
    local edit_package = string.rep(' ', 8) .. "Edit Package: <k>"
    local edit_class = "Edit Class: <j>" .. string.rep(' ', 8)
    local confirm_class = string.rep(' ', 8) .. "Confirm Class: <cr>"
    local close_menu = "Close Menu: <q>" .. string.rep(' ', 8)
    api.nvim_buf_set_lines(popup_components.popup_buf, row+8, -1, false, {edit_package .. string.rep(' ', 60 - (string.len(edit_package) + string.len(edit_class))) .. edit_class})
    api.nvim_buf_set_lines(popup_components.popup_buf, row+9, -1, false, {confirm_class .. string.rep(' ', 60 - (string.len(confirm_class) + string.len(close_menu))) .. close_menu})
    api.nvim_set_current_win(components.wins.package_win)
    local first_line = vim.fn.getline(1,1)
    local first_line_length = string.len(first_line[1])
    api.nvim_feedkeys('a', 'n', true)
    api.nvim_win_set_cursor(components.wins.package_win, {1,first_line_length})

end

local function create_generate_interface_ui()
    local bufnr = vim.api.nvim_get_current_buf()
    if components ~= nil then
        print('You cannot open multiple generate modals at a time')
        return
    end

    local project_root = utils.get_spring_boot_project_root(vim.fn.fnamemodify(bufnr, ':p'))
    local main_class = utils.find_main_application_class_directory(project_root)
    local width = 60
    local height = 9

    local row = math.floor((vim.fn.winheight(0) - height) / 2)
    local col = math.floor((vim.fn.winwidth(0) - width) / 2)
    local popup_components = ui_utils.draw_popup(width, height, row, col, "Generate Interface")
    local package_components = ui_utils.draw_labeled_input(46, 1, row+1, col+1, "Package: ", popup_components.popup_buf, ui_utils.package_text(main_class))
    local interface_components = ui_utils.draw_labeled_input(46, 1, row+4, col+1, "Interface: ", popup_components.popup_buf, "")
    components = {
        bufs = {
            popup_buf = popup_components.popup_buf,
            border_buf = popup_components.border_buf,
            package_buf = package_components.input_buf,
            interface_buf = interface_components.input_buf,
        },
        wins = {
            popup_win = popup_components.popup_win,
            border_win = popup_components.border_win,
            package_win = package_components.input_win,
            interface_win = interface_components.input_win
        }
    }
    set_mappings(bufnr, components.bufs, 'interface')
    local edit_package = string.rep(' ', 8) .. "Edit Package: <k>"
    local edit_class = "Edit Interface: <j>" .. string.rep(' ', 8)
    local confirm_class = string.rep(' ', 8) .. "Confirm Interface: <cr>"
    local close_menu = "Close Menu: <q>" .. string.rep(' ', 8)
    api.nvim_buf_set_lines(popup_components.popup_buf, row+8, -1, false, {edit_package .. string.rep(' ', 60 - (string.len(edit_package) + string.len(edit_class))) .. edit_class})
    api.nvim_buf_set_lines(popup_components.popup_buf, row+9, -1, false, {confirm_class .. string.rep(' ', 60 - (string.len(confirm_class) + string.len(close_menu))) .. close_menu})
    api.nvim_set_current_win(components.wins.package_win)
    local first_line = vim.fn.getline(1,1)
    local first_line_length = string.len(first_line[1])
    api.nvim_feedkeys('a', 'n', true)
    api.nvim_win_set_cursor(components.wins.package_win, {1,first_line_length})

end

local function create_generate_enum_ui()
    local bufnr = vim.api.nvim_get_current_buf()
    if components ~= nil then
        print('You cannot open multiple generate modals at a time')
        return
    end

    local project_root = utils.get_spring_boot_project_root(vim.fn.fnamemodify(bufnr, ':p'))
    local main_class = utils.find_main_application_class_directory(project_root)
    local width = 60
    local height = 9

    local row = math.floor((vim.fn.winheight(0) - height) / 2)
    local col = math.floor((vim.fn.winwidth(0) - width) / 2)
    local popup_components = ui_utils.draw_popup(width, height, row, col, "Generate Enum")
    local package_components = ui_utils.draw_labeled_input(46, 1, row+1, col+1, "Package: ", popup_components.popup_buf, ui_utils.package_text(main_class))
    local enum_components = ui_utils.draw_labeled_input(46, 1, row+4, col+1, "Enum: ", popup_components.popup_buf, "")
    components = {
        bufs = {
            popup_buf = popup_components.popup_buf,
            border_buf = popup_components.border_buf,
            package_buf = package_components.input_buf,
            enum_buf = enum_components.input_buf,
        },
        wins = {
            popup_win = popup_components.popup_win,
            border_win = popup_components.border_win,
            package_win = package_components.input_win,
            enum_win = enum_components.input_win
        }
    }
    set_mappings(bufnr, components.bufs, 'enum')
    local edit_package = string.rep(' ', 8) .. "Edit Package: <k>"
    local edit_class = "Edit Enum: <j>" .. string.rep(' ', 8)
    local confirm_class = string.rep(' ', 8) .. "Confirm Enum: <cr>"
    local close_menu = "Close Menu: <q>" .. string.rep(' ', 8)
    api.nvim_buf_set_lines(popup_components.popup_buf, row+8, -1, false, {edit_package .. string.rep(' ', 60 - (string.len(edit_package) + string.len(edit_class))) .. edit_class})
    api.nvim_buf_set_lines(popup_components.popup_buf, row+9, -1, false, {confirm_class .. string.rep(' ', 60 - (string.len(confirm_class) + string.len(close_menu))) .. close_menu})
    api.nvim_set_current_win(components.wins.package_win)
    local first_line = vim.fn.getline(1,1)
    local first_line_length = string.len(first_line[1])
    api.nvim_feedkeys('a', 'n', true)
    api.nvim_win_set_cursor(components.wins.package_win, {1,first_line_length})

end

return {
    create_generate_class_ui = create_generate_class_ui,
    create_generate_interface_ui = create_generate_interface_ui,
    create_generate_enum_ui = create_generate_enum_ui,
    close_ui = close_ui,
    navigate_to_package = navigate_to_package,
    navigate_to_class = navigate_to_class,
    navigate_to_interface = navigate_to_interface,
    navigate_to_enum = navigate_to_enum
}
