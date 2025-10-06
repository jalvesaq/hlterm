local config = require("hlterm").get_config()

local function source_lines(lines)
    local f = config.tmp_dir .. "/lines.go"
    vim.fn.writefile(lines, f)
    require("hlterm").send_cmd("go", ". " .. f)
end

require("hlterm").set_ft_opts("go", {
    nl = "\n",
    app = "gomacro",
    quit_cmd = ":quit",
    source_fun = source_lines,
    send_empty = false,
    syntax = {
        match = {
            { "Input", "^gomacro>.*" },
            { "Input", "^\\.\\.\\..*" },
        },
        keyword = {},
    },
})

vim.api.nvim_buf_set_keymap(
    0,
    "n",
    config.mappings.start,
    "<Cmd>lua require('hlterm').start_app('go')<CR>",
    {}
)
