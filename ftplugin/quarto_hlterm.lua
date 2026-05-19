local config = require("hlterm.config").real_setup()

vim.api.nvim_buf_set_keymap(
    0,
    "n",
    config.mappings.start,
    "<Cmd>lua require('hlterm.run').start_app('quarto')<CR>",
    {}
)
