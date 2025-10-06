local config = require("hlterm").get_config()

local function source_lines(lines)
    local f = config.tmp_dir .. "/lines.scala"
    vim.fn.writefile(lines, f)
    require("hlterm").send_cmd("scala", ':load "' .. f .. '"')
end

require("hlterm").set_ft_opts("scala", {
    nl = "\n",
    app = "scala",
    quit_cmd = "sys.exit",
    source_fun = source_lines,
    send_empty = false,
    syntax = { match = {}, keyword = {} },
})

vim.api.nvim_buf_set_keymap(
    0,
    "n",
    config.mappings.start,
    "<Cmd>lua require('hlterm').start_app('scala')<CR>",
    {}
)
