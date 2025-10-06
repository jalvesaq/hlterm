local config = require("hlterm").get_config()

local function source_lines(lines)
    local f = config.tmp_dir .. "/lines.sh"
    vim.fn.writefile(lines, f)
    require("hlterm").send_cmd("sh", ". " .. f)
end

require("hlterm").set_ft_opts("sh", {
    nl = "\n",
    app = "sh",
    quit_cmd = "exit",
    source_fun = source_lines,
    send_empty = false,
    syntax = {
        match = {
            { "Input", "^\\$ .*" },
            { "Input", "^> .*" },
            { "Error", "^sh: .*" },
        },
        keyword = {},
    },
})

vim.api.nvim_buf_set_keymap(
    0,
    "n",
    config.mappings.start,
    "<Cmd>lua require('hlterm').start_app('sh')<CR>",
    {}
)
