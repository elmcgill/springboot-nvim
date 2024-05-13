local api = vim.api

local function center_text(str, width)
    --local width = api.nvim_win_get_width(0)
    local shift = math.floor(width/2) - math.floor(string.len(str) / 2)
    return string.rep(' ', shift) .. str
end

local function package_text(file_path)
    local src_index = string.find(file_path, "/src")
    local base_package_path = string.sub(file_path, src_index + 15)
    if(base_package_path) then
        local package_path = base_package_path:gsub("/", ".")
        return package_path .. '.'
    else
        return nil
    end
end

local function draw_border(width, height)
    local border_table = { "╭" .. string.rep("─", width) .. "╮"}
    local middle = "│" .. string.rep(" ", width) .. "│"
    for i=1, height do
        table.insert(border_table, middle)
    end
    table.insert(border_table, "╰" .. string.rep("─", width) .. "╯")

    return border_table
end

local function draw_popup(width, height, row, col, header)
    local popup_buf, border_buf
    local popup_win, border_win


    -- Setup the buffers
    border_buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_option(border_buf, 'filetype', 'springbootnvim')
    popup_buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_option(popup_buf, 'filetype', 'springbootnvim')

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

    border_win = api.nvim_open_win(border_buf, true, border_opts)
    
    api.nvim_buf_set_lines(popup_buf, 0, -1, false, {center_text(header, width)})
    popup_win = api.nvim_open_win(popup_buf, true, opts)

    return {
        popup_buf = popup_buf,
        popup_win = popup_win,
        border_buf = border_buf,
        border_win = border_win
    }
end

local function draw_labeled_input(width, height, row, col, label, popup_buf, value)
    -- Generate the lable text and input border
    local input_border = draw_border(width, height)
    local label_text = {}
    local label_len = string.len(label)
    table.insert(label_text, string.rep(" ", 12) .. input_border[1])
    table.insert(label_text, label .. string.rep(" ", (12 - string.len(label))) .. input_border[2])
    table.insert(label_text, string.rep(" ", 12) .. input_border[3])
    -- Set the main popup window to have the label text and border
    api.nvim_buf_set_lines(popup_buf, row, col, false, label_text)

    -- Create the input window and buffer
    local input_buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_option(input_buf, 'filetype', 'sprintbootnvim')

    local opts = {
        style = 'minimal',
        relative = 'editor',
        width = width,
        height = height,
        row = row + 1,
        col = col + 12,
        zindex = 102
    }

    api.nvim_buf_set_lines(input_buf, 0, -1, false, {value})

    local input_win = api.nvim_open_win(input_buf, true, opts)

    return {
        input_buf = input_buf,
        input_win = input_win
    }
end


return {
    draw_border = draw_border,
    draw_popup = draw_popup,
    draw_labeled_input = draw_labeled_input,
    center_text = center_text,
    package_text = package_text
}
