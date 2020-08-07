let &l:stl = '%!g:statusline_winid == win_getid() ? "%y%=%l " : "%y"'

let b:undo_ftplugin = get(b:, 'undo_ftplugin', 'exe') .. '| set stl<'
