vim9script

&l:stl = '%!g:statusline_winid == win_getid() ? "%y%=%l " : "%y"'

b:undo_ftplugin = get(b:, 'undo_ftplugin', 'exe') .. '| set stl<'
