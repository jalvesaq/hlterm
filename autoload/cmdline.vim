"  This program is free software; you can redistribute it and/or modify
"  it under the terms of the GNU General Public License as published by
"  the Free Software Foundation; either version 2 of the License, or
"  (at your option) any later version.
"
"  This program is distributed in the hope that it will be useful,
"  but WITHOUT ANY WARRANTY; without even the implied warranty of
"  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
"  GNU General Public License for more details.
"
"  A copy of the GNU General Public License is available at
"  http://www.r-project.org/Licenses/

"==========================================================================
" Author: Jakson Alves de Aquino <jalvesaq@gmail.com>
"==========================================================================

let s:plugin_home = expand("<sfile>:h:h")

function cmdline#Init()
    " Set options
    let g:cmdline_vsplit = get(g:, 'cmdline_vsplit', 0)
    let g:cmdline_term_width = get(g:, 'cmdline_term_width', 40)
    let g:cmdline_term_height = get(g:, 'cmdline_term_height', 15)
    if has("win32") && isdirectory($TMP)
        let g:cmdline_tmp_dir = get(g:, 'cmdline_tmp_dir', $TMP . '/cmdline_' . localtime() . '_' . $USER)
    else
        let g:cmdline_tmp_dir = get(g:, 'cmdline_tmp_dir', '/tmp/cmdline_' . localtime() . '_' . $USER)
    endif
    let g:cmdline_outhl = get(g:, 'cmdline_outhl', 1)
    let g:cmdline_actions = get(g:, 'cmdline_actions', {})

    " Internal variables
    let g:cmdline_job = {}
    let g:cmdline_termbuf = {}
    let g:cmdline_tmuxsname = {}
    let s:cmdline_app_pane = ''

    " Zellij specific variables and configuration option
    let g:cmdline_zellij_pane = 0
    let g:cmdline_use_zellij = get(g:, 'cmdline_use_zellij', 0)

    autocmd VimLeave * call cmdline#Leave()

    " Default mappings
    if !exists("g:cmdline_map_start")
        let g:cmdline_map_start = "<LocalLeader>s"
    endif
    if !exists("g:cmdline_map_send")
        let g:cmdline_map_send = "<Space>"
    endif
    if !exists("g:cmdline_map_send_and_stay")
        let g:cmdline_map_send_and_stay = "<LocalLeader><Space>"
    endif
    if !exists("g:cmdline_map_send_motion")
        let g:cmdline_map_send_motion = "<LocalLeader>m"
    endif
    if !exists("g:cmdline_map_source_fun")
        let g:cmdline_map_source_fun = "<LocalLeader>f"
    endif
    if !exists("g:cmdline_map_send_paragraph")
        let g:cmdline_map_send_paragraph = "<LocalLeader>p"
    endif
    if !exists("g:cmdline_map_send_block")
        let g:cmdline_map_send_block = "<LocalLeader>b"
    endif
    if !exists("g:cmdline_map_quit")
        let g:cmdline_map_quit = "<LocalLeader>q"
    endif
endfunction

function! cmdline#QuartoLng()
    if &filetype != 'quarto'
        return &filetype
    endif

    let chunkline = search("^[ \t]*```[ ]*{", "bncW")
    let docline = search("^[ \t]*```$", "bncW")
    if chunkline <= docline
        return 'none'
    endif
    let lng = substitute(substitute(getline(chunkline), '.*{', '', ''), '\W.*', '', '')
    let scrpt = s:plugin_home . '/ftplugin/' . lng . '_cmdline.vim'
    if filereadable(scrpt)
        exe 'source ' . scrpt
        return lng
    else
        echomsg 'vimcmdline does not support file of type "' . lng . '"'
        return 'none'
    endif
endfunction

" Skip empty lines
function cmdline#Down()
    let i = line(".") + 1
    call cursor(i, 1)
    if b:cmdline_send_empty
        return
    endif
    let curline = substitute(getline("."), '^\s*', "", "")
    let fc = curline[0]
    let lastLine = line("$")
    while i < lastLine && strlen(curline) == 0
        let i = i + 1
        call cursor(i, 1)
        let curline = substitute(getline("."), '^\s*', "", "")
        let fc = curline[0]
    endwhile
endfunction

function cmdline#Start_ExTerm(app)
    " Check if the REPL application is already running
    if has_key(g:cmdline_tmuxsname, b:cmdline_filetype) && g:cmdline_tmuxsname[b:cmdline_filetype] != ""
        let tout = system("tmux -L VimCmdLine has-session -t " . g:cmdline_tmuxsname[b:cmdline_filetype])
        if tout =~ "VimCmdLine" || tout =~ g:cmdline_tmuxsname[b:cmdline_filetype]
            unlet g:cmdline_tmuxsname[b:cmdline_filetype]
        else
            echohl WarningMsg
            echo 'Tmux session with "' . b:cmdline_app . '" is already running.'
            echohl Normal
            return
        endif
    endif

    let g:cmdline_tmuxsname[b:cmdline_filetype] = "vcl" . localtime()

    if exists('g:cmdline_tmux_conf')
        let tconf = expand(g:cmdline_tmux_conf)
    else
        let tconf = g:cmdline_tmp_dir . "/tmux.conf"
        let cnflines = ['set-option -g prefix C-a',
                    \ 'unbind-key C-b',
                    \ 'bind-key C-a send-prefix',
                    \ 'set-window-option -g mode-keys vi',
                    \ 'set -g status off',
                    \ 'set -g default-terminal "screen-256color"',
                    \ "set -g terminal-overrides 'xterm*:smcup@:rmcup@'" ]
        if g:cmdline_external_term_cmd =~ "rxvt" || g:cmdline_external_term_cmd =~ "urxvt"
            let cnflines = cnflines + [
                        \ "set terminal-overrides 'rxvt*:smcup@:rmcup@'" ]
        endif
        call writefile(cnflines, tconf)
    endif

    let cmd = printf(g:cmdline_external_term_cmd,
                \ 'tmux -2 -f "' . tconf . '" -L VimCmdLine new-session -s ' .
                \ g:cmdline_tmuxsname[b:cmdline_filetype] . ' ' . a:app)
    call system(cmd)
endfunction

function cmdline#Start_Zellij(app)
    " Check if Zellij is running
    if $ZELLIJ == ""
        echohl WarningMsg
        echomsg "Cannot start interpreter because not inside a Zellij session."
        echohl Normal
        return
    endif

    " Create a wrapper script to preserve environment
    let wrapper_script = g:cmdline_tmp_dir . '/env_wrapper_' . getpid() . '.sh'
    let env_dump = []

    " Dump current environment variables to the wrapper script
    for [key, val] in items(environ())
        let escaped_val = substitute(val, "'", "'\\\\''", "g")
        call add(env_dump, "export " . key . "='" . escaped_val . "'")
    endfor

    " Run Zellij with the wrapper script
    call add(env_dump, "exec " . a:app)
    call writefile(env_dump, wrapper_script)
    call system('chmod +x ' . wrapper_script)

    let zcmd = "zellij action new-pane "
    if g:cmdline_vsplit
        let zcmd .= "-d right "
    else
        let zcmd .= "-d down "
    endif
    let zcmd .= " -- " . wrapper_script

    " Create new pane
    call system(zcmd)
    if v:shell_error
        echohl ErrorMsg
        echomsg "Failed to create Zellij pane."
        echohl Normal
        call delete(wrapper_script)
        return
    endif

    " Refocus Vim after creating the new pane
    let focus_vim = "zellij action focus-previous-pane"
    call system(focus_vim)
    if v:shell_error
        echohl ErrorMsg
        echomsg "ERROR: Focus command failed with error: " . v:shell_error
        echohl Normal
        return
    endif

    " Store that we created a pane
    let g:cmdline_zellij_pane = 1
endfunction

" Run the interpreter in a Tmux panel
function cmdline#Start_Tmux(app)
    " Check if Tmux is running
    if $TMUX == ""
        echohl WarningMsg
        echomsg "Cannot start interpreter because not inside a Tmux session."
        echohl Normal
        return
    endif

    let tcmd = "tmux split-window -d -t $TMUX_PANE -P -F \"#{pane_id}\" "
    if g:cmdline_vsplit
        if g:cmdline_term_width == -1
            let tcmd .= "-h"
        else
            let tcmd .= "-h -l " . g:cmdline_term_width
        endif
    else
        let tcmd .= "-l " . g:cmdline_term_height
    endif
    let tcmd .= " " . a:app
    let paneid = system(tcmd)
    if v:shell_error
        exe 'echoerr ' . paneid
        return
    endif
    let s:cmdline_app_pane = paneid
endfunction

function cmdline#CreateMaps(lng)
    exe 'nmap <silent><buffer> ' . g:cmdline_map_send . ' <Cmd>call cmdline#SendLine()<CR>'
    exe 'nmap <silent><buffer> ' . g:cmdline_map_send_and_stay . ' <Cmd>call cmdline#SendLineAndStay()<CR>'
    exe 'nmap <silent><buffer> ' . g:cmdline_map_send_motion . ' <Cmd>set opfunc=cmdline#SendMotion<CR>g@'
    exe 'vmap <silent><buffer> ' . g:cmdline_map_send .
                \ ' <Esc>:call cmdline#SendSelection()<CR>'
    if exists("b:cmdline_source_fun")
        exe 'nmap <silent><buffer> ' . g:cmdline_map_source_fun .
                    \ ' <Cmd>call b:cmdline_source_fun(getline(1, "$"))<CR>'
        exe 'nmap <silent><buffer> ' . g:cmdline_map_send_paragraph .
                    \ ' <Cmd>call cmdline#SendParagraph()<CR>'
        exe 'nmap <silent><buffer> ' . g:cmdline_map_send_block .
                    \ ' <Cmd>call cmdline#SendMBlock()<CR>'
    endif
    if exists("b:cmdline_quit_cmd")
        exe 'nmap <silent><buffer> ' . g:cmdline_map_quit . ' <Cmd>call cmdline#Quit("' . b:cmdline_filetype . '")<CR>'
    endif

    for ft in keys(g:cmdline_actions)
        if ft == a:lng
            for amap in g:cmdline_actions[ft]
                exe 'nmap <silent><buffer> ' . amap[0] . ' <Cmd>call cmdline#Action("' . substitute(amap[1], '"', '\\"', 'g') . '")<CR>'
            endfor
        endif
    endfor
endfunction

" Common procedure to start the interpreter
function cmdline#StartApp()
    let lng = cmdline#QuartoLng()
    if lng == 'none'
        return
    endif

    " Ensure that the necessary variables were created
    if !exists("g:cmdline_job")
        call cmdline#Init()
    endif

    call cmdline#SetApp(lng)

    if !exists("b:cmdline_app")
        echomsg 'There is no application defined to be executed for file of type "' . b:cmdline_filetype . '".'
        return
    endif

    call cmdline#CreateMaps(lng)

    if !isdirectory(g:cmdline_tmp_dir)
        call mkdir(g:cmdline_tmp_dir)
    endif

    if exists("g:cmdline_external_term_cmd")
        call cmdline#Start_ExTerm(b:cmdline_app)
    else
        if g:cmdline_use_zellij
            call cmdline#Start_Zellij(b:cmdline_app)
        else
            call cmdline#Start_Tmux(b:cmdline_app)
        endif
    endif
endfunction

" Send a single line to the interpreter
function cmdline#SendCmd(...)
    if has_key(g:cmdline_job, b:cmdline_filetype) && g:cmdline_job[b:cmdline_filetype]
        if exists('*chansend')
            call chansend(g:cmdline_job[b:cmdline_filetype], a:1 . b:cmdline_nl)
        else
            call jobsend(g:cmdline_job[b:cmdline_filetype], a:1 . b:cmdline_nl)
        endif
    else
        let str = substitute(a:1, "'", "'\\\\''", "g")
        if str =~ '^-'
            let str = ' ' . str
        endif
        if exists("g:cmdline_external_term_cmd") && g:cmdline_tmuxsname[b:cmdline_filetype] != ""
            let scmd = "tmux -L VimCmdLine set-buffer '" . str .
                        \ "\<C-M>' && tmux -L VimCmdLine paste-buffer -t " . g:cmdline_tmuxsname[b:cmdline_filetype] . '.0'
            call system(scmd)
            if v:shell_error
                echohl WarningMsg
                echomsg 'Failed to send command. Is "' . b:cmdline_app . '" running?'
                echohl Normal
                unlet g:cmdline_tmuxsname[b:cmdline_filetype]
            endif
        elseif g:cmdline_use_zellij && g:cmdline_zellij_pane
            " For Zellij, we need to focus the next pane and write the command
            let focus_cmd = "zellij action focus-next-pane"
            call system(focus_cmd)
            if v:shell_error
                echohl ErrorMsg
                echomsg "ERROR: Focus command failed with error: " . v:shell_error
                echohl Normal
                return
            endif

            " Write characters to the focused pane
            let write_cmd = "zellij action write-chars '" . str . "'"
            call system(write_cmd)
            if v:shell_error
                echohl ErrorMsg
                echomsg "ERROR: Write command failed with error: " . v:shell_error
                echohl Normal
                return
            endif

            " Send the enter key separately
            let enter_cmd = "zellij action write-chars '\n'"
            call system(enter_cmd)

            " Return focus to vim pane
            let return_focus_cmd = "zellij action focus-previous-pane"
            call system(return_focus_cmd)
            if v:shell_error
                echohl ErrorMsg
                echomsg "ERROR: Return focus command failed with error: " . v:shell_error
                echohl Normal
                return
            endif
        elseif s:cmdline_app_pane != ''
            let scmd = "tmux set-buffer '" . str . "\<C-M>' && tmux paste-buffer -t " . s:cmdline_app_pane
            call system(scmd)
            if v:shell_error
                echohl WarningMsg
                echomsg 'Failed to send command. Is "' . b:cmdline_app . '" running?'
                echohl Normal
                let s:cmdline_app_pane = ''
            endif
        endif
    endif
endfunction

" Send current line to the interpreter and go down to the next non empty line
function cmdline#SendLine()
    if cmdline#QuartoLng() == 'none'
        return
    endif

    if exists('*b:cmdline_send')
        call b:cmdline_send()
        return
    endif

    let line = getline(".")
    if strlen(line) > 0 || b:cmdline_send_empty
        call cmdline#SendCmd(line)
    endif
    call cmdline#Down()
endfunction

" Send current line to the interpreter and but keep cursor on current line
function cmdline#SendLineAndStay()
    if cmdline#QuartoLng() == 'none'
        return
    endif

    let line = getline(".")
    if strlen(line) > 0 || b:cmdline_send_empty
        call cmdline#SendCmd(line)
    endif
endfunction

function cmdline#SelectionToString()
    try
        let a_orig = @a
        silent! normal! gv"ay
        return @a
    finally
        let @a = a_orig
    endtry
endfunction

function cmdline#SendSelection()
    if cmdline#QuartoLng() == 'none'
        return
    endif

    if line("'<") == line("'>")
        let line = cmdline#SelectionToString()
        call cmdline#SendCmd(line)
    elseif exists("b:cmdline_source_fun")
        let lines = split(cmdline#SelectionToString(), "\n")
        call b:cmdline_source_fun(lines)
    endif
endfunction

function cmdline#SendParagraph()
    if cmdline#QuartoLng() == 'none'
        return
    endif

    let i = line(".")
    let c = col(".")
    let max = line("$")
    let j = i
    let gotempty = 0
    while j < max
        let j += 1
        let line = getline(j)
        if line =~ '^\s*$'
            break
        endif
    endwhile
    let lines = getline(i, j)
    call b:cmdline_source_fun(lines)
    if j < max
        call cursor(j, 1)
    else
        call cursor(max, 1)
    endif
endfunction

function cmdline#SendMotion(type, ...)
    let sel_save = &selection
    let &selection = "inclusive"
    let reg_save = @@

    if a:0
        silent exe "normal! gvy"
    elseif a:type == 'line'
        silent exe "normal! '[V']y"
    else
        silent exe "normal! `[v`]y"
    endif

    let the_list = []
    for line in split(@@, "\n")
        call add(the_list, line)
    endfor

    call b:cmdline_source_fun(the_list)

    let &selection = sel_save
    let @@ = reg_save
endfunction

let s:all_marks = "abcdefghijklmnopqrstuvwxyz"

function cmdline#SendMBlock()
    let curline = line(".")
    let lineA = 1
    let lineB = line("$")
    let maxmarks = strlen(s:all_marks)
    let n = 0
    while n < maxmarks
        let c = strpart(s:all_marks, n, 1)
        let lnum = line("'" . c)
        if lnum != 0
            if lnum <= curline && lnum > lineA
                let lineA = lnum
            elseif lnum > curline && lnum < lineB
                let lineB = lnum
            endif
        endif
        let n = n + 1
    endwhile
    if lineA == 1 && lineB == (line("$"))
        echo "The file has no mark!"
        return
    endif
    if lineB < line("$")
        let lineB -= 1
    endif
    let lines = getline(lineA, lineB)
    call b:cmdline_source_fun(lines)
endfunction

function cmdline#Action(fmt)
    if cmdline#QuartoLng() == 'none'
        return
    endif

    if a:fmt =~ '%s'
        let cmd = printf(a:fmt, expand('<cword>'))
    else
        let cmd = a:fmt
    endif
    call cmdline#SendCmd(cmd)
endfunction

" Quit the interpreter
function cmdline#Quit(ftype)
    if cmdline#QuartoLng() == 'none'
        return
    endif

    if exists("b:cmdline_quit_cmd")
        call cmdline#SendCmd(b:cmdline_quit_cmd)

        if has_key(g:cmdline_termbuf, a:ftype) && g:cmdline_termbuf[a:ftype] != ""
            exe "sb " . g:cmdline_termbuf[a:ftype]
            startinsert
            let g:cmdline_termbuf[a:ftype] = ""
        endif
        let g:cmdline_tmuxsname[a:ftype] = ""
        let g:cmdline_zellij_pane = 0
        let s:cmdline_app_pane = ''
    else
        echomsg 'Quit command not defined for file of type "' . a:ftype . '".'
    endif
endfunction

" Register that the job no longer exists
function cmdline#JobExit(job_id, data, etype)
    for ftype in keys(g:cmdline_job)
        if a:job_id == g:cmdline_job[ftype]
            let g:cmdline_job[ftype] = 0
        endif
    endfor
endfunction

" Replace default application with custom one
function cmdline#SetApp(ftype)
    if exists("g:cmdline_app")
        for key in keys(g:cmdline_app)
            if key == a:ftype
                let b:cmdline_app = g:cmdline_app[a:ftype]
            endif
        endfor
    endif
endfunction

function cmdline#Leave()
    let flist = split(glob(g:cmdline_tmp_dir . '/lines.*'), '\n')
    for fname in flist
        call delete(fname)
    endfor
    if executable("rmdir")
        call system("rmdir '" . g:cmdline_tmp_dir . "'")
    endif
endfunction

