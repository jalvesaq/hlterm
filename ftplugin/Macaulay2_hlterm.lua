local config = require("hlterm").get_config()

local function source_lines(lines)
    local f = config.tmp_dir .. "/lines.m2"
    vim.fn.writefile(lines, f)
    require("hlterm").send_cmd("Macaulay2", 'input "' .. f .. '"')
end

require("hlterm").set_ft_opts("Macaulay2", {
    nl = "\n",
    app = "M2",
    quit_cmd = "exit",
    source_fun = source_lines,
    send_empty = false,
    syntax = {
        match = {
            { "Input", "\\v^i+\\d+\\s+:.*%(\\n\\s.*)*" },
            { "Error", "\\v<error:.*" },
        },
        keyword = {},
    },
})

vim.api.nvim_buf_set_keymap(
    0,
    "n",
    config.mappings.start,
    "<Cmd>lua require('hlterm').start_app('Macaulay2')<CR>",
    {}
)
