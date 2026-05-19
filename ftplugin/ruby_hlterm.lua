local config = require("hlterm").real_setup()

local function source_lines(lines)
    local f = config.tmp_dir .. "/lines.rb"
    vim.fn.writefile(lines, "load '" .. f .. "'")
    require("hlterm.run").send_cmd("ruby", f)
end

require("hlterm.config").set_ft_opts("ruby", {
    nl = "\n",
    app = "irb",
    quit_cmd = "quit",
    source_fun = source_lines,
    send_empty = false,
    syntax = {
        match = { { "Input", "^irb(.*" } },
        keyword = {},
    },
})

vim.api.nvim_buf_set_keymap(
    0,
    "n",
    config.mappings.start,
    "<Cmd>lua require('hlterm.run').start_app('ruby')<CR>",
    {}
)
