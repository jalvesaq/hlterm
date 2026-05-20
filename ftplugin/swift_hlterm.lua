local config = require("hlterm.config").real_setup()
vim.api.nvim_buf_set_keymap(
    0,
    "n",
    config.mappings.start,
    "<Cmd>lua require('hlterm.run').start_app('swift')<CR>",
    {}
)

local ftopt = require("hlterm.config").get_ft_opts()
if vim.tbl_contains(vim.tbl_keys(ftopt), "swift") then return end

local function source_lines(lines) require("hlterm.run").send_mlines("swift", lines) end

require("hlterm.config").set_ft_opts("swift", {
    nl = "\n",
    app = "swift",
    quit_cmd = ":quit",
    source_fun = source_lines,
    send_empty = true,
    syntax = { match = {}, keyword = {} },
})
