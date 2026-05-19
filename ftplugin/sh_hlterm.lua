local config = require("hlterm.config").real_setup()
vim.api.nvim_buf_set_keymap(
    0,
    "n",
    config.mappings.start,
    "<Cmd>lua require('hlterm.run').start_app('sh')<CR>",
    {}
)

local ftopt = require("hlterm.config").get_ft_opts()
if vim.tbl_contains(vim.tbl_keys(ftopt), "sh") then return end

local function source_lines(lines)
    local f = config.tmp_dir .. "/lines.sh"
    vim.fn.writefile(lines, f)
    require("hlterm.run").send_cmd("sh", ". " .. f)
end

require("hlterm.config").set_ft_opts("sh", {
    nl = "\n",
    app = "sh",
    quit_cmd = "exit",
    source_fun = source_lines,
    send_empty = false,
    syntax = {
        match = {
            { "Input", "^\\$ .*" },
            { "Input", "^> .*" },
            { "Error", "^sh: .*" },
        },
        keyword = {},
    },
})
