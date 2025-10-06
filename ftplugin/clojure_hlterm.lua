local config = require("hlterm").get_config()

local function source_lines(lines)
    local f = config.tmp_dir .. "/lines.clj"
    vim.fn.writefile(lines, f)
    require("hlterm").send_cmd("clojure", '(load-file "' .. f .. '")')
end

require("hlterm").set_ft_opts("clojure", {
    nl = "\n",
    app = "lein repl",
    quit_cmd = "(quit)",
    source_fun = source_lines,
    send_empty = false,
    syntax = { match = {}, keyword = {} },
})

vim.api.nvim_buf_set_keymap(
    0,
    "n",
    config.mappings.start,
    "<Cmd>lua require('hlterm').start_app('clojure')<CR>",
    {}
)
