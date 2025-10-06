local config = require("hlterm").get_config()

local function source_lines(lines)
    local f = config.tmp_dir .. "/lines.js"
    vim.fn.writefile(lines, f)
    -- Need to delete the cache for this tmp file if it exists, otherwise the
    -- file won't be loaded again.
    local clear_cache_command = "delete require.cache[require.resolve('" .. f .. "')]; "
    local source_file_command = "require('" .. f .. "');"
    require("hlterm").send_cmd("javascript", clear_cache_command .. source_file_command)
end

require("hlterm").set_ft_opts("javascript", {
    nl = "\n",
    app = "node",
    quit_cmd = ".exit",
    source_fun = source_lines,
    send_empty = false,
    syntax = {
        match = {
            { "Input", "^>.*" },
            { "Input", "^\\.\\.\\..*" },
        },
        keyword = {},
    },
})

vim.api.nvim_buf_set_keymap(
    0,
    "n",
    config.mappings.start,
    "<Cmd>lua require('hlterm').start_app('javascript')<CR>",
    {}
)
