local Job = require("plenary.job")
local popup = require("plenary.popup")

local M = {}

local is_request_start = function(line)
    return not (line == nil or line == '') and (line:sub(1, #'GET') == 'GET' or line:sub(1, #'POST') == 'POST')
end
local search_backward = function(linenr)
    local start_line_nr = linenr
    local line = vim.api.nvim_buf_get_lines(0, start_line_nr - 1, linenr, false)[1]
    while start_line_nr > 1 and not is_request_start(line) do
        start_line_nr = start_line_nr - 1
        line = vim.api.nvim_buf_get_lines(0, start_line_nr - 1, start_line_nr, false)[1]
    end
    return start_line_nr
end

local search_forward = function(linenr)
    local end_line_nr = linenr
    local line = vim.api.nvim_buf_get_lines(0, end_line_nr - 1, end_line_nr, false)[1]
    while end_line_nr < vim.api.nvim_buf_line_count(0) and not is_request_start(line) do
        end_line_nr = end_line_nr + 1
        line = vim.api.nvim_buf_get_lines(0, end_line_nr - 1, end_line_nr, false)[1]
    end
    return end_line_nr
end


local create_tmp_file = function(content)
    local tmp_file = os.tmpname() .. '.http'
    local f = io.open(tmp_file, "w")
    if f ~= nil then
        f:write(content)
        f:write("\n")
        f:close()
        return tmp_file
    end
    return nil
end

Ropogos_win_id = nil
Ropogos_buffnr = nil

local function closeWindow()
    vim.api.nvim_win_close(Harpoon_win_id, true)
    Ropogos_win_id = nil
    Ropogos_buffnr = nil
end

local function create_window()
    local width = 60
    local height = 30
    local borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }
    local bufnr = vim.api.nvim_create_buf(false, false)
    local win_id, win = popup.create(bufnr, {
        title = "Ropogos",
        highlight = "RopogosWindow",
        minwidth = width,
        minheight = height,
        borderchars = borderchars,
    })
    vim.api.nvim_win_set_option(
        win.border.win_id,
        "winhl",
        "Normal:RopogosBorder"
    )
    return { win_id = win_id, bufnr = bufnr }
end

local function callback_job(filename)
    local stdout_results = {}
    local job = Job:new {
        command = "ijhttp",
        args = { filename, "-v", "../http-client.env.json", "-e", "dev", "-L", "verbose" },
        on_stdout = function(_, line)
            table.insert(stdout_results, line)
        end,
        on_stderr = function(_, line)
            table.insert(stdout_results, line)
        end,
    }
    job:sync()

    print(vim.inspect.inspect(stdout_results))
    print(#stdout_results)
    print(Ropogos_buffnr)

    local win_info = create_window()
    Ropogos_win_id = win_info.win_id
    Ropogos_buffnr = win_info.bufnr
    vim.api.nvim_buf_set_name(Ropogos_buffnr, "ropogos-menu")
    vim.api.nvim_buf_set_lines(Ropogos_buffnr, 0, #stdout_results, false, stdout_results)
    vim.api.nvim_buf_set_option(Ropogos_buffnr, "bufhidden", "delete")
    vim.api.nvim_buf_set_option(Ropogos_buffnr, "buftype", "acwrite")
    vim.api.nvim_buf_set_keymap(
        Ropogos_buffnr,
        "n",
        "q",
        "<Cmd>bw!<CR>",
        { silent = true }
    )
end

local config_path = vim.fn.stdpath("config")
local data_path = vim.fn.stdpath("data")
print(string.format("%s", config_path))
print(string.format("%s", data_path))


local find = function()
    local linenr = vim.api.nvim_win_get_cursor(0)[1]

    local start_line_nr = search_backward(linenr)
    local start_line = vim.api.nvim_buf_get_lines(0, linenr - 1, linenr, false)[1]
    -- true if at the beginning of the file there are comments/empty lines only.
    -- then we have to search forward to find the beginning 1st request
    if start_line_nr == 1 and not is_request_start(start_line) then
        start_line_nr = search_forward(start_line_nr + 1)
    end

    local end_line_nr = search_forward(start_line_nr + 1) - 1

    -- print(string.format("Current line [%d]", linenr))
    -- print(string.format("Start line [%d]", start_line_nr))
    -- print(string.format("End line [%d]", end_line_nr))


    local lines = vim.api.nvim_buf_get_lines(0, start_line_nr - 1, end_line_nr, false)

    return lines
end

function M.run()
    local lines = find()

    local content = ''

    for i = 1, #lines, 1 do
        content = content .. string.format("%s\n", lines[i])
    end
    local tmp = create_tmp_file(content)

    print(tmp)
    callback_job(tmp)
end

return M
