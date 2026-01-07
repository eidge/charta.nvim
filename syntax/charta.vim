" Syntax highlighting for Charta bookmark files
" Extends markdown syntax with charta-specific patterns

if exists("b:current_syntax")
  finish
endif

" Load markdown syntax as the base
runtime! syntax/markdown.vim
unlet! b:current_syntax

" Match the filepath:line or filepath:line-line pattern
" The filepath is everything before the colon, but only if line doesn't start with whitespace
syntax match chartaFilePath "^\S[^:]*:" contains=chartaLineNumber
syntax match chartaLineNumber ":\d\+\(-\d\+\)\?$" contained

" Highlight groups
highlight default link chartaFilePath Constant
highlight default link chartaLineNumber Label

let b:current_syntax = "charta"
