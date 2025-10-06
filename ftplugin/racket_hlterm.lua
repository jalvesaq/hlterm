local config = require("hlterm").get_config()

local function source_lines(lines)
    local f = config.tmp_dir .. "/lines.rkt"
    vim.fn.writefile(lines, f)
    require("hlterm").send_cmd("racket", '(load "' .. f .. '")')
end

require("hlterm").set_ft_opts("racket", {
    nl = "\n",
    app = "racket",
    quit_cmd = "(exit)",
    source_fun = source_lines,
    send_empty = false,
    syntax = { match = {}, keyword = {} },
})

vim.api.nvim_buf_set_keymap(
    0,
    "n",
    config.mappings.start,
    "<Cmd>lua require('hlterm').start_app('racket')<CR>",
    {}
)
