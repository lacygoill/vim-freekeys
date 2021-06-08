vim9script

&l:statusline = '%!g:statusline_winid == win_getid() ? "%y%=%l " : "%y"'

b:undo_ftplugin = get(b:, 'undo_ftplugin', 'exe') .. '| set statusline<'
