-- skip if filetype is sage.python
if vim.bo.filetype:find("sage") then return end

local config = require("hlterm.config").real_setup()
vim.api.nvim_buf_set_keymap(
    0,
    "n",
    config.mappings.start,
    "<Cmd>lua require('hlterm.run').start_app('python')<CR>",
    {}
)

local ftopt = require("hlterm.config").get_ft_opts()
if vim.tbl_contains(vim.tbl_keys(ftopt), "python") then return end

local ipython = false
if config.app.python and config.app.python == "ipython" then ipython = true end

local function source_lines(lines)
    if ipython then
        require("hlterm.run").send_cmd("python", "%cpaste -q")
        vim.cmd.sleep("100m ") -- Wait for IPython to read stdin
        table.insert(lines, "--")
        require("hlterm.run").send_cmd("python", vim.fn.join(lines, "\n"))
    else
        require("hlterm.run").send_mlines("python", lines)
    end
end

local py_exe = vim.fn.executable("python3") == 1 and "python3" or "python"

-- See: https://github.com/jalvesaq/hlterm/issues/114#issuecomment-4489377763
-- if py_exe == "python3" then
--     local o = vim.system({ "python3", "--version" }, { text = true }):wait()
--     if o.stdout > "Python 3.13.9\n" then
--         py_exe = "env PYTHON_BASIC_REPL=1 python3"
--     end
-- end

require("hlterm.config").set_ft_opts("python", {
    nl = "\n",
    app = py_exe,
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
