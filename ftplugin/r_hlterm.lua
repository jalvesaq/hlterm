local config = require("hlterm.config").real_setup()
vim.api.nvim_buf_set_keymap(
    0,
    "n",
    config.mappings.start,
    "<Cmd>lua require('hlterm.run').start_app('r')<CR>",
    {}
)

local ftopt = require("hlterm.config").get_ft_opts()
if vim.tbl_contains(vim.tbl_keys(ftopt), "r") then return end

local function source_lines(lines)
    local f = config.tmp_dir .. "/lines.R"
    vim.fn.writefile(lines, f)
    require("hlterm.run").send_cmd(
        "r",
        "base::source('" .. f .. "', local = parent.frame(), print.eval = TRUE)"
    )
end

require("hlterm.config").set_ft_opts("r", {
    nl = "\n",
    app = "R",
    quit_cmd = 'quit(save = "no")',
    source_fun = source_lines,
    send_empty = false,
    syntax = {
        match = {
            { "Input", "^> .*" },
            { "Input", "^\\.\\.\\..*" },
            { "Index ", "^\\s*\\[\\d\\+\\]" },
            { "Inf", "-Inf" },
        },
        keyword = {
            { "True", "TRUE" },
            { "False", "FALSE" },
            { "Constant", "NA" },
            { "Constant", "NULL" },
            { "Inf", "Inf" },
        },
    },
})
