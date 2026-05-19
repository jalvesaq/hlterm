local config = require("hlterm.config").real_setup()

local function source_lines(lines)
    require("hlterm.run").send_cmd("sage", "%cpaste -q")
    vim.cmd.sleep("100m ") -- Wait for IPython to read stdin
    table.insert(lines, "--")
    require("hlterm.run").send_cmd("sage", vim.fn.join(lines, "\n"))
end

require("hlterm.config").set_ft_opts("sage", {
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
    "<Cmd>lua require('hlterm.run').start_app('sage')<CR>",
    {}
)
