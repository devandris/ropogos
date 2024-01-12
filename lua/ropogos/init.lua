local Dev = require("ropogos.dev")
local log = Dev.log

local config_path = vim.fn.stdpath("config")
local data_path = vim.fn.stdpath("data")

print(string.format("%s", config_path))
print(string.format("%s", data_path))

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

local linenr = vim.api.nvim_win_get_cursor(0)[1]

local start_line_nr = search_backward(linenr)
local start_line = vim.api.nvim_buf_get_lines(0, linenr - 1, linenr, false)[1]
-- true if at the beginning of the file there are comments/empty lines only.
-- then we have to search forward to find the beginning 1st request
if start_line_nr == 1 and not is_request_start(start_line) then
    start_line_nr = search_forward(start_line_nr + 1)
end

local end_line_nr = search_forward(start_line_nr + 1) - 1

print(string.format("Current line [%d]", linenr))
print(string.format("Start line [%d]", start_line_nr))
print(string.format("End line [%d]", end_line_nr))


local lines = vim.api.nvim_buf_get_lines(0, start_line_nr - 1, end_line_nr, false)
for i = 1, #lines do
    print(string.format("[%s]", lines[i]))
end
