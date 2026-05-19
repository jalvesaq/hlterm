local config = require("hlterm.config").real_setup()

local function source_lines(lines)
    table.insert(lines, "")
    require("hlterm.run").send_cmd("swift", vim.fn.join(lines, "\n"))
end

require("hlterm.config").set_ft_opts("swift", {
    nl = "\n",
    app = "swift",
    quit_cmd = ":quit",
    source_fun = source_lines,
    send_empty = true,
    syntax = { match = {}, keyword = {} },
})

vim.api.nvim_buf_set_keymap(
    0,
    "n",
    config.mappings.start,
    "<Cmd>lua require('hlterm.run').start_app('swift')<CR>",
    {}
)
