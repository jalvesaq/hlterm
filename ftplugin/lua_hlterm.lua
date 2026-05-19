local config = require("hlterm.config").real_setup()
vim.api.nvim_buf_set_keymap(
    0,
    "n",
    config.mappings.start,
    "<Cmd>lua require('hlterm.run').start_app('lua')<CR>",
    {}
)

local ftopt = require("hlterm.config").get_ft_opts()
if vim.tbl_contains(vim.tbl_keys(ftopt), "lua") then return end

local function source_lines(lines)
    local f = config.tmp_dir .. "/lines.lua"
    vim.fn.writefile(lines, f)
    require("hlterm.run").send_cmd("lua", 'dofile("' .. f .. '")')
end

require("hlterm.config").set_ft_opts("lua", {
    nl = "\n",
    app = "lua",
    quit_cmd = "os.exit()",
    source_fun = source_lines,
    send_empty = false,
    syntax = {
        match = {
            { "Input", "^> .*" },
            { "Input", "^>> .*" },
            { "Error", "^stdin: .*" },
        },
        keyword = {
            { "True", "true" },
            { "False", "false" },
            { "Constant", "nil" },
        },
    },
})
