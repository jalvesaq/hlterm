local config = require("hlterm").get_config()

local function source_lines(lines)
    require("hlterm").send_cmd("magma", vim.fn.join(lines, "\n"))
end

require("hlterm").set_ft_opts("magma", {
    nl = "\n",
    app = "magma",
    quit_cmd = "quit;",
    source_fun = source_lines,
    send_empty = true,
    syntax = { match = {}, keyword = {} },
})

vim.api.nvim_buf_set_keymap(
    0,
    "n",
    config.mappings.start,
    "<Cmd>lua require('hlterm').start_app('magma')<CR>",
    {}
)
