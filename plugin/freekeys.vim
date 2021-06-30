vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

command -bar -nargs=? -complete=custom,freekeys#complete FreeKeys freekeys#main(<q-args>)

nnoremap <unique> -k <Cmd>call freekeys#main()<CR>
#                  ^
#                  Mnemonic: Keys

nnoremap <unique> -K <Cmd>call freekeys#main('-nomapcheck')<CR>

