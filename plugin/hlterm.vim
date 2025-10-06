if exists("s:did_warn")
    finish
endif
let s:did_warn = 1

if has("nvim")
    if exists("g:cmdline_app") ||
                \ exists("g:cmdline_external_term_cmd") ||
                \ exists("g:cmdline_map_quit") ||
                \ exists("g:cmdline_map_send") ||
                \ exists("g:cmdline_map_send_and_stay") ||
                \ exists("g:cmdline_map_send_block") ||
                \ exists("g:cmdline_map_send_motion") ||
                \ exists("g:cmdline_map_send_paragraph") ||
                \ exists("g:cmdline_map_source_fun") ||
                \ exists("g:cmdline_map_start") ||
                \ exists("g:cmdline_term_height") ||
                \ exists("g:cmdline_term_width") ||
                \ exists("g:cmdline_tmp_dir") ||
                \ exists("g:cmdline_tmux_conf") ||
                \ exists("g:cmdline_use_zellij") ||
                \ exists("g:cmdline_vsplit")
        function CmdLineNvimWarn(...)
            echohl WarningMsg
            echomsg "'vimcmdline' now is 'hlterm'. Please, update your Neovim configuration. The global options starting with 'cmdline_' are no longer used."
            echohl None
        endfunction
        call timer_start(1000, 'CmdLineNvimWarn')
    endif
    finish
endif

function CmdLineNvimWarn(...)
    echohl WarningMsg
    echomsg '`vimcmdline` now is `hlterm`. Please, use the branch "vim".'
    echohl None
endfunction
call timer_start(1000, 'CmdLineNvimWarn')
