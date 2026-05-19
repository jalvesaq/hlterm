local config = require("hlterm.config").real_setup()
vim.api.nvim_buf_set_keymap(
    0,
    "n",
    config.mappings.start,
    "<Cmd>lua require('hlterm.run').start_app('go')<CR>",
    {}
)

local ftopt = require("hlterm.config").get_ft_opts()
if vim.tbl_contains(vim.tbl_keys(ftopt), "go") then return end

local function source_lines(lines)
    local f = config.tmp_dir .. "/lines.go"
    vim.fn.writefile(lines, f)
    require("hlterm.run").send_cmd("go", ". " .. f)
end

require("hlterm.config").set_ft_opts("go", {
    nl = "\n",
    app = "gomacro",
    quit_cmd = ":quit",
    source_fun = source_lines,
    send_empty = false,
    syntax = {
        match = {
            { "Input", "^gomacro>.*" },
            { "Input", "^\\.\\.\\..*" },
        },
        keyword = {},
    },
})
