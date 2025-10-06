local config = require("hlterm").get_config()

local function source_lines(lines)
    require("hlterm").send_cmd("sage", "%cpaste -q")
    vim.cmd.sleep("100m ") -- Wait for IPython to read stdin
    table.insert(lines, "--")
    require("hlterm").send_cmd("sage", vim.fn.join(lines, "\n"))
end

require("hlterm").set_ft_opts("sage", {
    nl = "\n",
    app = "sage",
    quit_cmd = "exit",
    source_fun = source_lines,
    send_empty = true,
    syntax = { match = { { "Input", "\\m^sage:.*" } }, keyword = {} },
})

vim.api.nvim_buf_set_keymap(
    0,
    "n",
    config.mappings.start,
    "<Cmd>lua require('hlterm').start_app('sage')<CR>",
    {}
)
