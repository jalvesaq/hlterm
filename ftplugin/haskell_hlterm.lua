local config = require("hlterm.config").real_setup()
vim.api.nvim_buf_set_keymap(
    0,
    "n",
    config.mappings.start,
    "<Cmd>lua require('hlterm.run').start_app('haskell')<CR>",
    {}
)

local ftopt = require("hlterm.config").get_ft_opts()
if vim.tbl_contains(vim.tbl_keys(ftopt), "haskell") then return end

local function source_lines(lines)
    local f = config.tmp_dir .. "/lines.hs"
    vim.fn.writefile(lines, f)
    require("hlterm.run").send_cmd("haskell", ":load " .. f)
end

require("hlterm.config").set_ft_opts("haskell", {
    nl = "\n",
    app = vim.fn.executable("stack") == 1 and "stack ghci" or "ghci",
    quit_cmd = ":quit",
    source_fun = source_lines,
    send_empty = false,
    syntax = {
        match = {
            { "Input", "^Prelude>.*" },
            { "Error", "^<interactive>:.*" },
        },
        keyword = {},
    },
})
