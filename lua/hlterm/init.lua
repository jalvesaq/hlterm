local plugin_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h")

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

---@type HlTermFTOpt[]
local ftopt = {}

local jobs = {}
local term_buf = {}
local app_pane = {}

local M = {}

--- HlTerm warning
---@param msg string Text to be displayed as a warning
local function cwarn(msg) vim.notify(msg, vim.log.levels.WARN, { title = "hlterm.nvim" }) end

-- Register that the job no longer exists
local function on_exit(job_id, _, _)
    for _, ftype in pairs(vim.tbl_keys(jobs)) do
        if job_id == jobs[ftype] then
            jobs[ftype] = 0
            if term_buf[ftype] then vim.api.nvim_buf_delete(term_buf[ftype], {}) end
        end
    end
end

---@param opts? HlTermUserOpts
function M.setup(opts)
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
end

--- Get language of current Quart block of code
--- @return string
local function quartolng()
    local chunkline = vim.fn.search("^[ \t]*```[ ]*{", "bncW")
    local docline = vim.fn.search("^[ \t]*```$", "bncW")
    if chunkline <= docline then return "none" end
    local cline = vim.fn.getline(chunkline)
    cline = cline:gsub(".*{", "")
    local lng = cline:gsub("%W.*", "")
    local scrpt = plugin_root .. "/ftplugin/" .. lng .. "_hlterm.vim"
    if vim.fn.filereadable(scrpt) == 1 then
        vim.cmd.source(scrpt)
        return lng
    else
        cwarn('vimhlterm does not support file of type "' .. lng .. '"')
        return "none"
    end
end

---Skip empty lines
---@param ft string The file type
local function down(ft)
    local i = vim.fn.line(".")
    local lastline = vim.api.nvim_buf_line_count(0)
    if i < lastline then
        i = i + 1
        vim.fn.cursor(i, 1)
    end

    if ftopt[ft].send_empty then return end

    local curline = vim.fn.getline(i):gsub("^%s*", "")
    while i < lastline and vim.fn.strlen(curline) == 0 do
        i = i + 1
        vim.fn.cursor(i, 1)
        curline = vim.fn.getline(i):gsub("^%s*", "")
    end
end

--- Run the interpreter in an external terminal with Tmux Session Management
local function start_exterm(ft)
    local tsname = "hlterm" .. ft

    -- Determine or create the tmux config file
    local tconf
    if config.tmux_conf then
        tconf = vim.fn.expand(config.tmux_conf)
    else
        tconf = config.tmp_dir .. "/tmux.conf"
        local cnflines = {
            "set-option -g prefix C-a",
            "unbind-key C-b",
            "bind-key C-a send-prefix",
            "set-window-option -g mode-keys vi",
            "set -g status off",
            'set -g default-terminal "screen-256color"',
            [[set -g terminal-overrides 'xterm*:smcup@:rmcup@']],
        }
        if config.external_term_cmd:match("rxvt") then
            table.insert(cnflines, "set terminal-overrides 'rxvt*:smcup@:rmcup@'")
        end
        vim.fn.writefile(cnflines, tconf)
    end

    -- 4. Execute the command to start the external terminal
    local cmd = string.format(
        config.external_term_cmd,
        'tmux -2 -f "'
            .. tconf
            .. '" -L HlTerm new-session -s '
            .. tsname
            .. " "
            .. ftopt[ft].app
    )
    jobs[ft] = vim.fn.jobstart(cmd, { on_exit = on_exit })
end

local function start_zellij(ft)
    if vim.env.ZELLIJ == nil or vim.env.ZELLIJ == "" then
        cwarn("Cannot start interpreter because not inside a Zellij session.")
        return
    end

    -- Create a wrapper script to preserve environment
    local pid = vim.fn.getpid()
    local wrapper_script = config.tmp_dir .. "/env_wrapper_" .. pid .. ".sh"
    local env_dump = {}

    -- Dump current environment variables to the wrapper script (Lua uses os.getenv and pairs(_G.vim.env))
    for key, val in pairs(vim.env) do
        -- Escape single quotes in the value: ' -> '\''
        local escaped_val = val:gsub("'", [[\'\\'\']])
        table.insert(env_dump, string.format("export %s='%s'", key, escaped_val))
    end

    -- Run Zellij with the wrapper script
    table.insert(env_dump, "exec " .. ftopt[ft].app)
    vim.fn.writefile(env_dump, wrapper_script)
    vim.fn.system("chmod +x " .. wrapper_script) -- Set executable permission

    local zcmd = "zellij action new-pane "
    if config.vsplit then
        zcmd = zcmd .. "-d right "
    else
        zcmd = zcmd .. "-d down "
    end
    zcmd = zcmd .. " -- " .. wrapper_script

    -- Create new pane
    vim.fn.system(zcmd)
    if vim.v.shell_error ~= 0 then
        cwarn("Failed to create Zellij pane.")
        vim.fn.delete(wrapper_script)
        return
    end
    vim.fn.delete(wrapper_script)

    -- 4. Refocus nvim after creating the new pane
    local focus_nvim = "zellij action focus-previous-pane"
    vim.fn.system(focus_nvim)
    if vim.v.shell_error ~= 0 then
        cwarn("ERROR: Focus command failed with error: " .. vim.v.shell_error)
        return
    end
end

---Start the REPL in a Tmux pane
---@param ft string The file type
local function start_tmux(ft)
    if not vim.env.TMUX then
        cwarn("Cannot start interpreter because not inside a Tmux session.")
        return
    end

    local tcmd = 'tmux split-window -d -t $TMUX_PANE -P -F "#{pane_id}" '
    if config.vsplit then
        if config.term_width == -1 then
            tcmd = tcmd .. "-h"
        else
            tcmd = tcmd .. "-h -l " .. config.term_width
        end
    else
        tcmd = tcmd .. "-l " .. config.term_height
    end
    tcmd = tcmd .. " " .. ftopt[ft].app

    -- Get the pane ID
    local paneid = vim.fn.system(tcmd)
    if vim.v.shell_error ~= 0 then
        cwarn(paneid)
        return
    end
    app_pane[ft] = paneid
end

---Apply syntax highilighting to the terminal
---@param ft string The file type
local function hl_term(ft)
    if not config.highlight then return end
    if config.out_hl[ft] == false then return end

    if ftopt[ft].string_delimiter then
        vim.b.hlterm_string_delimiter = ftopt[ft].string_delimiter
    end
    vim.cmd.runtime("syntax/hlterm.vim")
    for _, v in pairs(ftopt[ft].syntax.match) do
        vim.cmd.syntax("match hlterm" .. v[1] .. ' "' .. v[2] .. '"')
    end
    for _, v in pairs(ftopt[ft].syntax.keyword) do
        vim.cmd.syntax("keyword hlterm" .. v[1] .. " " .. v[2])
    end
end

---Run the interpreter in a Neovim terminal buffer
---@param ft string The file type
local function start_nvim(ft)
    if vim.tbl_contains(jobs, ft) then return end

    local edbuf = vim.api.nvim_get_current_buf()
    vim.o.switchbuf = "useopen"
    if config.vsplit then
        local ww = vim.api.nvim_win_get_width(0)
        if config.term_width == 0 then
            config.term_width = ww > 160 and 80 or math.floor(ww / 2)
        end
        if config.term_width > 16 and config.term_width < (ww - 16) then
            vim.cmd("belowright " .. config.term_width .. "vnew")
        else
            vim.cmd("belowright vnew")
        end
    else
        local wh = vim.api.nvim_win_get_width(0)
        if config.term_height > 6 and config.term_height < (wh - 6) then
            vim.cmd("belowright " .. config.term_height .. "new")
        else
            vim.cmd("belowright new")
        end
    end
    jobs[ft] = vim.fn.jobstart(ftopt[ft].app, { on_exit = on_exit, term = true })
    term_buf[ft] = vim.api.nvim_get_current_buf()
    if config.esc_term then vim.cmd("tnoremap <buffer> <Esc> <C-\\><C-n>") end
    hl_term(ft)
    vim.cmd.normal("G")
    vim.cmd.sbuffer(edbuf)
    vim.cmd("stopinsert")
end

---Create maps
---@param ft string File type
local function create_maps(ft)
    if ft == "quarto" then
        ft = quartolng()
        if ft == "none" then return end
    end

    vim.api.nvim_buf_set_keymap(
        0,
        "n",
        config.mappings.send,
        "<Cmd>lua require('hlterm').send_line('" .. ft .. "', true)<CR>",
        { noremap = true, silent = true, desc = "hlterm: send line" }
    )
    vim.api.nvim_buf_set_keymap(
        0,
        "n",
        config.mappings.send_and_stay,
        "<Cmd>lua require('hlterm').send_line('" .. ft .. "', false)<CR>",
        { noremap = true, silent = true, desc = "hlterm: send and stay" }
    )
    vim.api.nvim_buf_set_keymap(
        0,
        "n",
        config.mappings.send_motion,
        "<Cmd>set opfunc=v:lua.require'hlterm'.send_motion<CR>g@",
        { noremap = true, silent = true, desc = "hlterm: send motion" }
    )
    vim.api.nvim_buf_set_keymap(
        0,
        "v",
        config.mappings.send,
        "<Cmd>lua require('hlterm').send_selection('" .. ft .. "')<CR>",
        { noremap = true, silent = true, desc = "hlterm: send selection" }
    )
    if ftopt[ft].source_fun then
        vim.api.nvim_buf_set_keymap(
            0,
            "n",
            config.mappings.send_paragraph,
            "<Cmd>lua require('hlterm').send_paragraph('" .. ft .. "')<CR>",
            { noremap = true, silent = true, desc = "hlterm: send paragraph" }
        )
        vim.api.nvim_buf_set_keymap(
            0,
            "n",
            config.mappings.send_block,
            "<Cmd>lua require('hlterm').send_mblock('" .. ft .. "')<CR>",
            { noremap = true, silent = true, desc = "hlterm: " }
        )
        if ft ~= "quarto" then
            vim.api.nvim_buf_set_keymap(
                0,
                "n",
                config.mappings.send_file,
                "<Cmd>lua require('hlterm').send_file('" .. ft .. "')<CR>",
                { noremap = true, silent = true, desc = "hlterm: " }
            )
        end
    end
    if ftopt[ft].quit_cmd then
        vim.api.nvim_buf_set_keymap(
            0,
            "n",
            config.mappings.quit,
            "<Cmd>lua require('hlterm').send_cmd('"
                .. ft
                .. "', '"
                .. ftopt[ft].quit_cmd
                .. "')<CR>",
            { noremap = true, silent = true, desc = "hlterm: " }
        )
    end

    local actions = config.actions[ft]
    if actions then
        for _, v in pairs(actions) do
            vim.api.nvim_buf_set_keymap(
                0,
                "n",
                v[1],
                "<Cmd>lua require('hlterm').action('" .. ft .. "', '" .. v[2] .. "')<CR>",
                { noremap = true, silent = true, desc = "hlterm: custom action" }
            )
        end
    end
end

---Common procedure to start the interpreter
---@param ft string File type
function M.start_app(ft)
    if ft == "quarto" then
        ft = quartolng()
        if ft == "none" then return end
    end

    if not ftopt[ft] then
        cwarn(
            'There is no application defined to be executed for file of type "'
                .. ft
                .. '"'
        )
        return
    end

    create_maps(ft)

    if vim.fn.isdirectory(config.tmp_dir) == 0 then vim.fn.mkdir(config.tmp_dir) end

    if config.external_term_cmd then
        start_exterm(ft)
    elseif config.use_tmux then
        start_tmux(ft)
    elseif config.use_zellij then
        start_zellij(ft)
    else
        start_nvim(ft)
    end
end

--- Send command to Python interpreter
---@param ft string The file type
---@param move boolean Whether to go to the next line
local function py_send_line(ft, move)
    local line = vim.api.nvim_get_current_line()
    -- Check if the cursor is in the beginning of a block
    local bb = line:match("^%s*class .*:$")
        or line:match("^%s*def .*:$")
        or line:match("^%s*while .*:$")
    local isif = line:match("^%s*if .*:$")
    local begin_l = vim.fn.line(".")
    local last_l = vim.api.nvim_buf_line_count(0)
    local end_l = begin_l < last_l and begin_l + 1 or begin_l

    if bb or isif then
        local indent = vim.fn.indent(begin_l)
        while end_l < last_l do
            if isif and vim.fn.indent(end_l) == indent then
                line = vim.fn.getline(end_l)
                if line:match("^%s*else:$") then end_l = end_l + 1 end
            end
            if vim.fn.indent(end_l) == indent then break end
            end_l = end_l + 1
        end
        local lines = vim.api.nvim_buf_get_lines(0, begin_l - 1, end_l - 1, true)
        ftopt[ft].source_fun(lines)
    else
        M.send_cmd(ft, line)
    end
    if move then vim.api.nvim_win_set_cursor(0, { end_l, 0 }) end
end

---Send text to Neovim built-in terminal
---@param ft string File type
---@param txt string Text to be sent
local function send_cmd_nvim(ft, txt)
    if not jobs[ft] then
        cwarn('Is "' .. ftopt[ft].app .. '" running?')
        return
    end

    if config.auto_scroll and term_buf[ft] then
        local isnormal = vim.fn.mode() == "n"
        local buf = vim.api.nvim_get_current_buf()
        vim.cmd.sbuffer(tostring(term_buf[ft]))
        vim.cmd.normal("G")
        vim.cmd.sbuffer(tostring(buf))
        if isnormal then vim.cmd("stopinsert") end
    end
    vim.fn.chansend(jobs[ft], txt .. ftopt[ft].nl)
end

---Send text to a Tmux pane in an external terminal emulator
---@param ft string File type
---@param txt string Text to be sent
local function send_cmd_exterm(ft, txt)
    if not jobs[ft] then
        cwarn('Is "' .. ftopt[ft].app .. '" running?')
        return
    end

    local scmd = "tmux -L HlTerm set-buffer '" .. txt .. "\13'"
    vim.fn.system(scmd)
    scmd = "tmux -L HlTerm paste-buffer -t hlterm" .. ft .. ".0"
    vim.fn.system(scmd)
    if vim.v.shell_error ~= 0 then
        cwarn('Failed to send command. Is "' .. ftopt[ft].app .. '" running?')
    end
end

---Send text to a Tmux pane
---@param ft string File type
---@param txt string Text to be sent
local function send_cmd_tmux(ft, txt)
    vim.notify("send_cmd_tmux [" .. app_pane[ft] .. "]: " .. ft .. " " .. txt)

    local scmd = "tmux set-buffer '" .. txt .. "\13'"
    vim.fn.system(scmd)
    scmd = "tmux paste-buffer -t " .. app_pane[ft]
    vim.fn.system(scmd)
    if vim.v.shell_error ~= 0 then
        cwarn('Failed to send command. Is "' .. ftopt[ft].app .. '" running?')
        app_pane[ft] = nil
    end
end

---Send text to a Zellij pane
---@param ft string File type
---@param txt string Text to be sent
local function send_cmd_zellij(ft, txt)
    vim.notify(
        "send_cmd_zellij [" .. vim.inspect(app_pane[ft]) .. "]: " .. ft .. " " .. txt
    )

    -- For Zellij, we need to focus the next pane and write the command
    local focus_cmd = "zellij action focus-next-pane"
    vim.fn.system(focus_cmd)
    if vim.v.shell_error then
        cwarn("ERROR: Focus command failed with error: " .. vim.v.shell_error)
        return
    end

    -- Write characters to the focused pane
    local write_cmd = "zellij action write-chars '" .. txt .. "'"
    vim.fn.system(write_cmd)
    if vim.v.shell_error then
        cwarn("ERROR: Write command failed with error: " .. vim.v.shell_error)
        return
    end

    -- Send the enter key separately
    local enter_cmd = "zellij action write-chars '\n'"
    vim.fn.system(enter_cmd)

    -- Return focus to vim pane
    local return_focus_cmd = "zellij action focus-previous-pane"
    vim.fn.system(return_focus_cmd)
    if vim.v.shell_error then
        cwarn("ERROR: Return focus command failed with error: " .. vim.v.shell_error)
        return
    end
end

---Send a single line to the interpreter
---@param ft string File type
---@param txt string Code to send to the interpreter
function M.send_cmd(ft, txt)
    if ft == "quarto" then
        ft = quartolng()
        if ft == "none" then return end
    end
    if config.external_term_cmd then
        send_cmd_exterm(ft, txt)
    elseif config.use_tmux then
        send_cmd_tmux(ft, txt)
    elseif config.use_zellij then
        send_cmd_zellij(ft, txt)
    else
        send_cmd_nvim(ft, txt)
    end
end

-- Send current line to the interpreter
---@param ft string File type
---@param move boolean Whether to go to the next line
function M.send_line(ft, move)
    if ft == "quarto" then
        ft = quartolng()
        if ft == "none" then return end
    end

    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    if ft == "python" or ft == "sage" then
        py_send_line(ft, move)
    else
        local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, true)[1]
        if #line > 0 or ftopt[ft].send_empty then M.send_cmd(ft, line) end
        if move then down(ft) end
    end
end

---Get the current visual selection and returns it as a table
---@return table | nil
local function selection_to_string()
    -- Leave visual mode
    local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
    vim.api.nvim_feedkeys(esc, "x", false)

    local start_pos = vim.api.nvim_buf_get_mark(0, "<")
    local end_pos = vim.api.nvim_buf_get_mark(0, ">")
    if not start_pos or not end_pos then return end
    local lines = vim.api.nvim_buf_get_lines(0, start_pos[1] - 1, end_pos[1], true)

    local vmode = vim.fn.visualmode()
    if vmode == "\022" then
        -- "\022" is <C-V>
        local cj = start_pos[2] + 1
        local ck = end_pos[2] + 1
        if cj > ck then
            local tmp = cj
            cj = ck
            ck = tmp
        end
        for k, _ in pairs(lines) do
            lines[k] = string.sub(lines[k], cj, ck)
        end
    elseif vmode == "v" then
        if start_pos[1] == end_pos[1] then
            lines[1] = string.sub(lines[1], start_pos[2] + 1, end_pos[2] + 1)
        else
            lines[1] = string.sub(lines[1], start_pos[2] + 1, -1)
            local llen = #lines
            lines[llen] = string.sub(lines[llen], 1, end_pos[2] + 1)
        end
    end
    return lines
end

--- Send selected texto to the interpreter
---@param ft string File type
function M.send_selection(ft)
    if ft == "quarto" then
        ft = quartolng()
        if ft == "none" then return end
    end

    local lines = selection_to_string()
    if not lines then return end

    if #lines > 1 and ftopt[ft].source_fun then
        ftopt[ft].source_fun(lines)
    else
        for _, v in pairs(lines) do
            M.send_cmd(ft, v)
        end
    end
end

---Send a paragraph to the interpreter
---@param ft string File type
function M.send_paragraph(ft)
    if ft == "quarto" then
        ft = quartolng()
        if ft == "none" then return end
    end

    local i = vim.fn.line(".")
    local max = vim.api.nvim_buf_line_count(0)
    local j = i
    while j < max do
        j = j + 1
        local line = vim.fn.getline(j)
        if line:find("^%s*$") then
            j = j - 1
            break
        end
    end
    if j > max then j = max end
    local lines = vim.fn.getline(i, j)
    ftopt[ft].source_fun(lines)
    if j < max then
        vim.fn.cursor(j, 1)
    else
        vim.fn.cursor(max, 1)
    end
end

---Send text covered by motion
function M.send_motion()
    local ft = vim.bo.filetype
    if ft == "quarto" then
        ft = quartolng()
        if ft == "none" then return end
    end

    local startPos = vim.api.nvim_buf_get_mark(0, "[")
    local endPos = vim.api.nvim_buf_get_mark(0, "]")
    if not startPos or not endPos then return end

    local startLine, endLine = startPos[1], endPos[1]

    -- Check if the marks are valid
    if
        startLine <= 0
        or startLine > endLine
        or endLine > vim.api.nvim_buf_line_count(0)
    then
        cwarn("Invalid motion range")
        return
    end

    -- Adjust endLine to include the line under the ']` mark
    endLine = endLine < vim.api.nvim_buf_line_count(0) and endLine or endLine - 1

    -- Fetch the lines from the buffer
    local lines = vim.api.nvim_buf_get_lines(0, startLine - 1, endLine, false)

    -- Send the fetched lines to be sourced by R
    if lines and #lines > 0 then
        ftopt[ft].source_fun(lines)
    else
        cwarn("No lines to send")
    end
end

---Send a marked block of lines to the interpreter
---@param ft string File type
function M.send_mblock(ft)
    if ft == "quarto" then
        ft = quartolng()
        if ft == "none" then return end
    end

    local all_marks = "abcdefghijklmnopqrstuvwxyz"
    local curline = vim.fn.line(".")
    local lineA = 1
    local lineB = vim.api.nvim_buf_line_count(0)
    local maxmarks = vim.fn.strlen(all_marks)
    local n = 0
    while n < maxmarks do
        local c = vim.fn.strpart(all_marks, n, 1)
        local lnum = vim.fn.line("'" .. c)
        if lnum ~= 0 then
            if lnum <= curline and lnum > lineA then
                lineA = lnum
            elseif lnum > curline and lnum < lineB then
                lineB = lnum
            end
        end
        n = n + 1
    end
    if lineA == 1 and lineB == vim.api.nvim_buf_line_count(0) then
        cwarn("The file has no mark!")
        return
    end
    if lineB < vim.api.nvim_buf_line_count(0) then lineB = lineB - 1 end
    local lines = vim.fn.getline(lineA, lineB)
    ftopt[ft].source_fun(lines)
end

---Send all lines to the interpreter
---@param ft string File type
function M.send_file(ft)
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
    if not lines then return end
    ftopt[ft].source_fun(lines)
end

---Send a custom command to the interpreter
---@param ft string File type
---@param fmt string The format of the command
function M.action(ft, fmt)
    if ft == "quarto" then
        ft = quartolng()
        if ft == "none" then return end
    end

    local cmd
    if fmt:find("%%s") then
        cmd = string.format(fmt, vim.fn.expand("<cword>"))
    else
        cmd = fmt
    end
    M.send_cmd(ft, cmd)
end

---Delete temporary files and directory
function M.leave()
    local flist = vim.split(vim.fn.glob(config.tmp_dir .. "/lines.*"), "\n")
    for _, fname in pairs(flist) do
        if fname ~= "" then vim.fn.delete(fname) end
    end
    if vim.fn.executable("rmdir") == 1 then
        vim.fn.system("rmdir '" .. config.tmp_dir .. "'")
    end
end

--- Set file type specific options (called by ftplugin scripts)
---@param ft string File type
---@param opts HlTermFTOpt Options
function M.set_ft_opts(ft, opts)
    if ft == "quarto" then
        ft = quartolng()
        if ft == "none" then return end
    end

    if vim.tbl_contains(vim.tbl_keys(config.app), ft) then
        opts["app"] = config.app[ft]
    end
    ftopt[ft] = opts
end

---Get configuration table
---@return HlTermUserOpts
function M.get_config() return config end

return M
