local config = require("hlterm.config").real_setup()

vim.api.nvim_buf_set_keymap(
    0,
    "n",
    config.mappings.start,
    "<Cmd>lua require('hlterm.run').start_app('quarto')<CR>",
    {}
)

local ftopt = require("hlterm.config").get_ft_opts()
if vim.tbl_contains(vim.tbl_keys(ftopt), "quarto") then return end

local function source_lines(lines)
    vim.notify("quarto source lines not implemented yet\n" .. lines)
end

require("hlterm.config").set_ft_opts("quarto", {
    source_fun = source_lines,
})
