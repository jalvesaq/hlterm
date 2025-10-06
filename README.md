# hlterm: Send code to Neovim's terminal and highlight the output

**Notes:**

- `hlterm` is the `vimcmdline` plugin converted from VimScript to Lua.

- `hlterm` only works in Neovim, but Vim users can use the branch "vim".

This plugin sends lines from [Neovim] to a command line
interpreter (REPL application). There is support for
Clojure, Golang, Haskell, JavaScript, Julia, Jupyter, Kotlin, Lisp,
Lua, Macaulay2, Matlab, Prolog, Python, R, Racket, Ruby, Sage,
Scala, Shell script, Swift, Kdb/q and TypeScript
(see [R.nvim] for a more compreehsive support for R in Neovim).
If the file type is `quarto`, `hlterm` will try to infer what interpreter
should be started.

The interpreter runs in Neovim's built-in terminal.
If Tmux or Zellij is installed, the interpreter can also run in
an external terminal emulator (tmux-only) or in a tmux/zellij pane. The main
advantage of running the interpreter in a Neovim terminal is that the output is
colorized, as in the screenshot below, where we have different colors for
general output, positive and negative numbers, and the prompt line:

![nvim running octave](https://cloud.githubusercontent.com/assets/891655/7090493/5fba2426-df71-11e4-8eb8-f17668d9361a.png)

If running in either a Neovim built-in terminal or an external terminal, the
plugin runs one instance of the REPL application for each file type. If
running in a tmux or zellij pane, it runs one REPL application for Neovim instance.

## How to install

Use a plugin manager to install hlterm.

You need to install either Tmux or Zellij if you want to run the interpreter in
a split pane. Note that external terminal emulator support requires Tmux
specifically.


## Usage and options

In Normal mode, type `<LocalLeader>s` to start the interpreter.

Please, read the plugin's
[documentation](https://raw.githubusercontent.com/jalvesaq/hlterm/master/doc/hlterm.txt)
for further instructions.


## How to add support for a new language

  1. Look at the Lua scripts in the `ftplugin` directory and make a copy of
     the one closer to the language that you want to support.

  2. Save the new script with the name "filetype\_hlterm.lua" where
     "filetype" is the output of `:echo &filetype` when you are editing a
     script of the language that you want to support.

  3. Edit the new script and change the values of its variables as necessary.

  4. Test your new file-type script by running your application in Neovim.

  5. Test your new output highlighting by running your application in a
     Neovim built-in terminal.

When editing your new file-type script, keep in mind that the goal is to
highlight the output, not the language. The code is properly highlighted in
the editor. In the terminal, we want to focus in the output and not be
distracted by a colorful input. Change the patterns used to recognize the
input line, errors, warnings, and the keywords that identify boolean values
and constants (such as `None` in Python, `nil` in Lua, and `NULL` and `NA` in
R).

String delimiters are not what the language accepts as input, but what it
outputs. For example, in Python

```python
txt = "abc"
txt
```

outputs `'abc'` while in R

```r
txt <- 'abc'
txt
```

outputs `[1] "abc"`.
Hence, the string delimiter is `'` in Python and `"` in R.


## See also

Similar plugins are [toggleterm.nvim], [iron.nvim], [vim-slime], [neoterm],
[sniprun], [conjure], and [yarepl.nvim].

[Neovim]: https://github.com/neovim/neovim
[R.nvim]: https://github.com/R-nvim/R.nvim
[toggleterm.nvim]: https://github.com/akinsho/toggleterm.nvim
[iron.nvim]: https://github.com/Vigemus/iron.nvim
[vim-slime]: https://github.com/jpalardy/vim-slime
[neoterm]: https://github.com/kassio/neoterm
[sniprun]: https://github.com/michaelb/sniprun
[conjure]: https://github.com/Olical/conjure
[yarepl.nvim]: https://github.com/milanglacier/yarepl.nvim
