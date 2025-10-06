local config = require("hlterm").get_config()

vim.api.nvim_buf_set_keymap(
    0,
    "n",
    config.mappings.start,
    "<Cmd>lua require('hlterm').start_app('quarto')<CR>",
    {}
)
