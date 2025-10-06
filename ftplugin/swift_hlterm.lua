local config = require("hlterm").get_config()

local function source_lines(lines)
    table.insert(lines, "")
    require("hlterm").send_cmd("swift", vim.fn.join(lines, "\n"))
end

require("hlterm").set_ft_opts("swift", {
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
    "<Cmd>lua require('hlterm').start_app('swift')<CR>",
    {}
)
