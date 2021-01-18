vim9 noclear

if exists('loaded') | finish | endif
var loaded = true

com -bar -nargs=? -complete=custom,freekeys#complete FreeKeys freekeys#main(<q-args>)

nno <unique> -k <cmd>call freekeys#main()<cr>
#             ^
#             Mnemonic: Keys

nno <unique> -K <cmd>call freekeys#main('-nomapcheck')<cr>

