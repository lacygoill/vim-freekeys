if exists('g:loaded_freekeys')
    finish
endif
let g:loaded_freekeys = 1

com! -nargs=? -complete=custom,freekeys#complete FK call freekeys#main(<q-args>)
