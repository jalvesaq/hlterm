local config = require("hlterm").get_config()

local function source_lines(lines)
    local f = config.tmp_dir .. "/lines.hs"
    vim.fn.writefile(lines, f)
    require("hlterm").send_cmd("haskell", ":load " .. f)
end

require("hlterm").set_ft_opts("haskell", {
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

vim.api.nvim_buf_set_keymap(
    0,
    "n",
    config.mappings.start,
    "<Cmd>lua require('hlterm').start_app('haskell')<CR>",
    {}
)
