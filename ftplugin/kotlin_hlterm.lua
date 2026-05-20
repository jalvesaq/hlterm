local config = require("hlterm.config").real_setup()
vim.api.nvim_buf_set_keymap(
    0,
    "n",
    config.mappings.start,
    "<Cmd>lua require('hlterm.run').start_app('kotlin')<CR>",
    {}
)

local ftopt = require("hlterm.config").get_ft_opts()
if vim.tbl_contains(vim.tbl_keys(ftopt), "kotlin") then return end

local function source_lines(lines) require("hlterm.run").send_mlines("kotlin", lines) end

require("hlterm.config").set_ft_opts("kotlin", {
    nl = "\n",
    app = "kotlin-jvm",
    quit_cmd = ":quit",
    source_fun = source_lines,
    send_empty = true,
    syntax = {
        match = {
            { "Input", "^>>>.*" },
            { "Input", "^\\.\\.\\..*" },
        },
        keyword = {},
    },
})
