if exists('did_load_filetypes')
    finish
endif

augroup filetypedetect
    au! BufRead,BufNewFile  FreeKeys  set filetype=freekeys
augroup END
