local config = require("hlterm").get_config()

local function source_lines(lines)
    local f = config.tmp_dir .. "/lines.pl"
    vim.fn.writefile(lines, f)
    require("hlterm").send_cmd("prolog", "consult('" .. f .. "')")
end

require("hlterm").set_ft_opts("prolog", {
    nl = "\n",
    app = "swipl",
    quit_cmd = "halt.",
    source_fun = source_lines,
    send_empty = false,
    syntax = {
        match = {
            { "Input", "^?-.*" },
            { "Error", "^ERROR:.*" },
        },
        keyword = {},
    },
})

vim.api.nvim_buf_set_keymap(
    0,
    "n",
    config.mappings.start,
    "<Cmd>lua require('hlterm').start_app('prolog')<CR>",
    {}
)
