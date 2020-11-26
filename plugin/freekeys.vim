if exists('g:loaded_freekeys')
    finish
endif
let g:loaded_freekeys = 1

com -bar -nargs=? -complete=custom,freekeys#complete FreeKeys call freekeys#main(<q-args>)

nno <unique> -k <cmd>call freekeys#main()<cr>
"             ^
"             Mnemonic: Keys

nno <unique> -K <cmd>call freekeys#main('-nomapcheck')<cr>

