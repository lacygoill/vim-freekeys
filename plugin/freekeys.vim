if exists('g:loaded_freekeys')
    finish
endif
let g:loaded_freekeys = 1

com -bar -nargs=? -complete=custom,freekeys#complete FreeKeys call freekeys#main(<q-args>)

nno <unique><silent> -k :<c-u>call freekeys#main('')<cr>
"                     ^
"                     Mnemonic: Keys

nno <unique><silent> -K :<c-u>call freekeys#main('-nomapcheck')<cr>

augroup my_freekeys
    au!
    au FileType freekeys call lg#set_stl('freekeys', '%=%-5l ')
augroup END

