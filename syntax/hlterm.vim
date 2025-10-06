" Vim syntax file
" Language:    No language. Output of any interpreter
" Maintainer:  Jakson Aquino <jalvesaq@gmail.com>


if exists('b:current_syntax')
    finish
endif

" Normal text
syn match hltermNormal "."

" Strings
if exists('b:hlterm_string_delimiter') && b:hlterm_string_delimiter == "'"
    syn region hltermString start=/'/ skip=/\\\\\|\\'/ end=/'/
else
    syn region hltermString start=/"/ skip=/\\\\\|\\"/ end=/"/
endif

" integer
syn match hltermInteger "\<\d\+L"
syn match hltermInteger "\<0x\([0-9]\|[a-f]\|[A-F]\)\+L"
syn match hltermInteger "\<\d\+[Ee]+\=\d\+L"

" number with no fractional part or exponent
syn match hltermNumber "\<\d\+\>"
syn match hltermNegNum "-\<\d\+\>"
" hexadecimal number
syn match hltermNumber "\<0x\([0-9]\|[a-f]\|[A-F]\)\+"

" floating point number with integer and fractional parts and optional exponent
syn match hltermFloat "\<\d\+\.\d*\([Ee][-+]\=\d\+\)\="
syn match hltermNegFloat "-\<\d\+\.\d*\([Ee][-+]\=\d\+\)\="
" floating point number with no integer part and optional exponent
syn match hltermFloat "\<\.\d\+\([Ee][-+]\=\d\+\)\="
syn match hltermNegFloat "-\<\.\d\+\([Ee][-+]\=\d\+\)\="
" floating point number with no fractional part and optional exponent
syn match hltermFloat "\<\d\+[Ee][-+]\=\d\+"
syn match hltermNegFloat "-\<\d\+[Ee][-+]\=\d\+"

" complex number
syn match hltermComplex "\<\d\+i"
syn match hltermComplex "\<\d\++\d\+i"
syn match hltermComplex "\<0x\([0-9]\|[a-f]\|[A-F]\)\+i"
syn match hltermComplex "\<\d\+\.\d*\([Ee][-+]\=\d\+\)\=i"
syn match hltermComplex "\<\.\d\+\([Ee][-+]\=\d\+\)\=i"
syn match hltermComplex "\<\d\+[Ee][-+]\=\d\+i"

" dates and times
syn match hltermDate "[0-9][0-9][0-9][0-9][-/][0-9][0-9][-/][0-9][-0-9]"
syn match hltermDate "[0-9][0-9][-/][0-9][0-9][-/][0-9][0-9][0-9][-0-9]"
syn match hltermDate "[0-9][0-9]:[0-9][0-9]:[0-9][-0-9]"

let   b:current_syntax = 'hlterm'

" vim: ts=8 sw=4
