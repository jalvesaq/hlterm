local config = require("hlterm.config").real_setup()
vim.api.nvim_buf_set_keymap(
    0,
    "n",
    config.mappings.start,
    "<Cmd>lua require('hlterm.run').start_app('kdb')<CR>",
    {}
)

local ftopt = require("hlterm.config").get_ft_opts()
if vim.tbl_contains(vim.tbl_keys(ftopt), "kdb") then return end

local function source_lines(lines)
    local f = config.tmp_dir .. "/lines.q"
    vim.fn.writefile(lines, f)
    require("hlterm.run").send_cmd("kdb", "\\l" .. f)
end

require("hlterm.config").set_ft_opts("kdb", {
    nl = "\n",
    -- `app` should not be an expression like 'rlwrap q' to do this create a
    -- script, add it to your PATH and set b:hltermapp accordingly
    app = "q",
    quit_cmd = "\\\\",
    source_fun = source_lines,
    send_empty = true,
    syntax = { match = {}, keyword = {} },
})
