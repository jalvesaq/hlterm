local config = require("hlterm").real_setup()

local function source_lines(lines)
    require("hlterm.run").send_cmd("magma", vim.fn.join(lines, "\n"))
end

require("hlterm.config").set_ft_opts("magma", {
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
    "<Cmd>lua require('hlterm.run').start_app('magma')<CR>",
    {}
)
