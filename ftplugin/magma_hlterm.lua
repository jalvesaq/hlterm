local config = require("hlterm.config").real_setup()
vim.api.nvim_buf_set_keymap(
    0,
    "n",
    config.mappings.start,
    "<Cmd>lua require('hlterm.run').start_app('magma')<CR>",
    {}
)

local ftopt = require("hlterm.config").get_ft_opts()
if vim.tbl_contains(vim.tbl_keys(ftopt), "magma") then return end

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
