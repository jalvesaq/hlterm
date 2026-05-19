local config = require("hlterm").real_setup()

local function source_lines(lines)
    local f = config.tmp_dir .. "/lines.scala"
    vim.fn.writefile(lines, f)
    require("hlterm.run").send_cmd("scala", ':load "' .. f .. '"')
end

require("hlterm.config").set_ft_opts("scala", {
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
    "<Cmd>lua require('hlterm.run').start_app('scala')<CR>",
    {}
)
