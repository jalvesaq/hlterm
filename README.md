# vimcmdline: Send lines to interpreter

This plugin sends lines from either [Vim] to a command line interpreter (REPL
application). There is support for Clojure, Golang, Haskell, JavaScript,
Julia, Jupyter, Kotlin, Lisp, Lua, Macaulay2, Matlab, Prolog, Python, R,
Racket, Ruby, Sage, Scala, Shell script, Swift, Kdb/q and TypeScript (see
[Vim-R] for a more compreehsive support for R in Vim). If the file type is
`quarto`, `vimcmdline` will try to infer what interpreter should be started.

If Tmux or Zellij is installed, the interpreter can run in
an external terminal emulator (tmux-only) or in a tmux/zellij pane.

If running in an external terminal, the plugin runs one instance of the REPL
application for each file type. If running in a tmux or zellij pane, it runs
one REPL application for Vim instance.

## How to install

Use a plugin manager to install vimcmdline.

You need to install either Tmux or Zellij.


## Usage and options

Please, read the plugin's
[documentation](https://raw.githubusercontent.com/jalvesaq/vimcmdline/master/doc/vimcmdline.txt)
for further instructions.


[Vim]: http://www.vim.org
[Vim-R]: https://github.com/jalvesaq/Vim-R
