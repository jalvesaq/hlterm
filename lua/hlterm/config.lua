---@class HlTermMaps
---@field start string? Key combination to start the interpreter
---@field send string? Key combination to send code and move to the next line
---@field send_and_stay string? Key combination to send code
---@field send_paragraph string? Key combination to send paragraph
---@field send_block string? Key combination to send marked block
---@field send_file string? Key combination to send file
---@field send_motion string? Key combination to send code coverd by motion
---@field quit string? Key combination to quit the interpreter

---@class HlTermColors
---@field Complex? vim.api.keyset.highlight
---@field Constant? vim.api.keyset.highlight
---@field Date? vim.api.keyset.highlight
---@field Error? vim.api.keyset.highlight
---@field False? vim.api.keyset.highlight
---@field Float? vim.api.keyset.highlight
---@field Index? vim.api.keyset.highlight
---@field Inf? vim.api.keyset.highlight
---@field Input? vim.api.keyset.highlight
---@field Integer? vim.api.keyset.highlight
---@field Negfloat? vim.api.keyset.highlight
---@field Negnum? vim.api.keyset.highlight
---@field Normal? vim.api.keyset.highlight
---@field Number? vim.api.keyset.highlight
---@field String? vim.api.keyset.highlight
---@field True? vim.api.keyset.highlight
---@field Warn? vim.api.keyset.highlight

---@class HlTermUserOpts
---@field vsplit? boolean Whether to split the window vertically
---@field esc_term? boolean Whether to map <Esc> in the terminal to go to Normal mode
---@field use_zellij? boolean Start the interpreter in a Zellij pane
---@field use_tmux? boolean Start the interpreter in a Tmux pane
---@field tmux_conf? string Path to custom Tmux configuration file
---@field external_term_cmd? string Command to run an external terminal
---@field term_height? integer Height of the terminal
---@field term_width? integer Width of the terminal
---@field tmp_dir? string Temporary directory
---@field auto_scroll? boolean Whether to keep the cursor at the end of the terminal window
---@field highlight? boolean Whether to highlight the output
---@field follow_colorscheme? boolean Whether to use your colorscheme to colorize the output
---@field mappings? HlTermMaps Table of custom maps
---@field output_colors? HlTermColors Table of custom colors
---@field app? table Table of custom apps by file type
---@field out_hl? table Table of wheather to highlight the output of specific file types
---@field actions? table Table of custom actions by file type

---@class HlTermFTOpt
---@field nl string
---@field app string
---@field quit_cmd string
---@field source_fun function
---@field send_empty boolean
---@field syntax table
---@field string_delimiter? string

---@type HlTermUserOpts
local config = {
    vsplit = false,
    esc_term = true,
    use_zellij = false,
    use_tmux = false,
    term_height = 15,
    term_width = 0,
    tmp_dir = "/tmp",
    auto_scroll = true,
    highlight = true,
    follow_colorscheme = false,
    mappings = {
        start = "<LocalLeader>s",
        send = "<Enter>",
        send_and_stay = "<LocalLeader><Enter>",
        send_paragraph = "<LocalLeader>p",
        send_block = "<LocalLeader>b",
        send_file = "<LocalLeader>f",
        send_motion = "<LocalLeader>m",
        quit = "<LocalLeader>q",
    },
    output_colors = {
        Complex = { fg = "#ffaf00" },
        Constant = { fg = "#00af5f" },
        Date = { fg = "#d7af5f" },
        Error = { fg = "#ffffff", bg = "#c00000" },
        False = { fg = "#ff5f5f" },
        Float = { fg = "#ffaf00" },
        Index = { fg = "#87afaf" },
        Inf = { fg = "#00afff" },
        Input = { fg = "#9e9e9e", italic = true },
        Integer = { fg = "#ffaf00" },
        NegFloat = { fg = "#ff875f" },
        NegNum = { fg = "#ff875f" },
        Normal = { fg = "#00d700" },
        Number = { fg = "#ffaf00" },
        String = { fg = "#5fffaf" },
        True = { fg = "#5fd787" },
        Warn = { fg = "#c00000", bold = true },
    },
    out_hl = {},
    app = {},
    actions = {},
}

local M = {}

---@type HlTermFTOpt[]
M.ftopt = {}

local did_setup = false

--- Overwrite default options with user options
---@return HlTermUserOpts
function M.real_setup()
    if did_setup then return config end
    did_setup = true

    local opts = require("hlterm").get_user_opts()
    if vim.fn.has("win32") == 1 and vim.fn.isdirectory(vim.env.TMP) then
        config.tmp_dir = vim.env.TMP
            .. "/hlterm_"
            .. tostring(vim.fn.rand(vim.fn.srand()))
            .. "_"
            .. vim.env.USER
    else
        config.tmp_dir = "/tmp/hlterm_"
            .. tostring(vim.fn.rand(vim.fn.srand()))
            .. "_"
            .. vim.env.USER
    end
    config = vim.tbl_deep_extend("force", config, opts or {})

    ---@type HlTermColors
    local outcolors = config.output_colors
    if config.follow_colorscheme then
        outcolors = {
            Complex = { link = "Number" },
            Constant = { link = "Constant" },
            Date = { link = "Number" },
            Error = { link = "ErrorMsg" },
            False = { link = "Boolean" },
            Float = { link = "Float" },
            Index = { link = "Special" },
            Inf = { link = "Number" },
            Input = { link = "Normal" },
            Integer = { link = "Number" },
            NegFloat = { link = "Float" },
            NegNum = { link = "Number" },
            Normal = { link = "Normal" },
            Number = { link = "Number" },
            String = { link = "String" },
            True = { link = "Boolean" },
            Warn = { link = "WarningMsg" },
        }
    end
    for k, v in pairs(outcolors) do
        vim.api.nvim_set_hl(0, "hlterm" .. k, v)
    end

    vim.cmd("autocmd VimLeave * lua require('hlterm').leave()")

    return config
end

--- Set file type specific options (called by ftplugin scripts)
---@param ft string File type
---@param opts HlTermFTOpt Options
function M.set_ft_opts(ft, opts)
    if ft == "quarto" then
        ft = require("hlterm.quarto").get_language()
        if ft == "none" then return end
    end

    if vim.tbl_contains(vim.tbl_keys(config.app), ft) then
        opts["app"] = config.app[ft]
    end
    M.ftopt[ft] = opts
end

---Get configuration table
---@return HlTermUserOpts
function M.get_config() return config end

return M
