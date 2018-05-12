if exists('g:loaded_freekeys')
    finish
endif
let g:loaded_freekeys = 1

com! -nargs=? -complete=custom,freekeys#complete FreeKeys call freekeys#main(<q-args>)

nno  <unique><silent>  -k  :<c-u>call freekeys#main('')<cr>
"                       ^
"                       Mnemonic: Keys

nno  <unique><silent>  -K  :<c-u>call freekeys#main('-nomapcheck')<cr>
