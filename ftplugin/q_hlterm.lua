local config = require("hlterm.config").real_setup()

local function source_lines(lines)
    local f = config.tmp_dir .. "/lines.q"
    vim.fn.writefile(lines, f)
    require("hlterm.run").send_cmd("kdb", "\\l " .. f)
end

require("hlterm.config").set_ft_opts("kdb", {
    nl = "\n",
    app = "q",
    quit_cmd = "\\\\",
    source_fun = source_lines,
    send_empty = true,
    syntax = {
        match = {
            { "Input", "^> .*" },
            { "Error", "^Error.*" },
        },
        keyword = {
            { "True", "TRUE" },
            { "False", "FALSE" },
        },
    },
})

vim.api.nvim_buf_set_keymap(
    0,
    "n",
    config.mappings.start,
    "<Cmd>lua require('hlterm.run').start_app('kdb')<CR>",
    {}
)
