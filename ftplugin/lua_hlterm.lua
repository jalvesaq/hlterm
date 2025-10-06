local config = require("hlterm").get_config()

local function source_lines(lines)
    local f = config.tmp_dir .. "/lines.lua"
    vim.fn.writefile(lines, f)
    require("hlterm").send_cmd("lua", 'dofile("' .. f .. '")')
end

require("hlterm").set_ft_opts("lua", {
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

vim.api.nvim_buf_set_keymap(
    0,
    "n",
    config.mappings.start,
    "<Cmd>lua require('hlterm').start_app('lua')<CR>",
    {}
)
