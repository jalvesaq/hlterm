-- skip if filetype is sage.python
if vim.bo.filetype:find("sage") then return end

local config = require("hlterm").get_config()

local ipython = false
if config.app.python and config.app.python == "ipython" then ipython = true end

local function source_lines(lines)
    if ipython then
        require("hlterm").send_cmd("python", "%cpaste -q")
        vim.cmd.sleep("100m ") -- Wait for IPython to read stdin
        table.insert(lines, "--")
        require("hlterm").send_cmd("python", vim.fn.join(lines, "\n"))
    else
        -- Use bracketed paste
        local block = vim.fn.join(lines, "\n")
        require("hlterm").send_cmd("python", "\027[200~" .. block .. "\027[201~\n")
    end
end

require("hlterm").set_ft_opts("python", {
    nl = "\n",
    app = vim.fn.executable("python3") == 1 and "python3" or "python",
    quit_cmd = "quit()",
    source_fun = source_lines,
    send_empty = true,
    syntax = {
        match = {
            { "Input", "^>>>.*" },
            { "Input", "^\\.\\.\\..*" },
        },
        keyword = {
            { "Constant", "None" },
        },
    },
    string_delimiter = "'",
})

vim.api.nvim_buf_set_keymap(
    0,
    "n",
    config.mappings.start,
    "<Cmd>lua require('hlterm').start_app('python')<CR>",
    {}
)
