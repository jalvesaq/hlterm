local config = require("hlterm").get_config()

local function source_lines(lines)
    local f = config.tmp_dir .. "/lines.m"
    vim.fn.writefile(lines, f)
    if config.app.matlab and config.app.matlab:find("^matlab") then
        require("hlterm").send_cmd("matlab", 'run("' .. f .. '"); clear lines.m;')
    else
        require("hlterm").send_cmd("matlab", 'source("' .. f .. '");')
    end
end

require("hlterm").set_ft_opts("matlab", {
    nl = "\n",
    app = "octave",
    quit_cmd = "exit",
    source_fun = source_lines,
    send_empty = false,
    syntax = {
        match = {
            { "Input", "^octave:.*" },
            { "Error", "^error:.*" },
        },
        keyword = {},
    },
})

vim.api.nvim_buf_set_keymap(
    0,
    "n",
    config.mappings.start,
    "<Cmd>lua require('hlterm').start_app('matlab')<CR>",
    {}
)
