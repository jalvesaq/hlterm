local config = require("hlterm.config").real_setup()
vim.api.nvim_buf_set_keymap(
    0,
    "n",
    config.mappings.start,
    "<Cmd>lua require('hlterm.run').start_app('julia')<CR>",
    {}
)

local ftopt = require("hlterm.config").get_ft_opts()
if vim.tbl_contains(vim.tbl_keys(ftopt), "julia") then return end

local function source_lines(lines)
    local f = config.tmp_dir .. "/lines.jl"
    vim.fn.writefile(lines, f)
    require("hlterm.run").send_cmd("julia", 'include("' .. f .. '")')
end

require("hlterm.config").set_ft_opts("julia", {
    nl = "\n",
    app = "julia",
    quit_cmd = "exit()",
    source_fun = source_lines,
    send_empty = false,
    syntax = { match = {}, keyword = {} },
})
