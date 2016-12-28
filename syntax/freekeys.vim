hi fk_operator ctermfg=black ctermbg=173    guifg=#000000 guibg=#d78700
hi fk_command  ctermfg=black ctermbg=yellow guifg=#000000 guibg=#ffff00
hi fk_motion   ctermfg=black ctermbg=green  guifg=#000000 guibg=#00d700

syn match fk_operator '\v[!=<>cdy]'
syn match fk_command  '\v[~@&qQrRYuUiIoOpPaAsSDJK:xXCvVm.]|Tab'
syn match fk_motion   '\v[#$%()*+,-/0;?BEFGHLMNTW^_befhjklntw{|}]'

syn keyword fk_command Tab
syn keyword fk_motion  Space BS CR

syn keyword Normal NORMAL VISUAL INSERT OPERATOR PENDING COMMAND LINE MODE

" We can't use `CTRL-` as a keyword because sometimes it fails:
"
"         CTRL-_
"         CTRL-K
"         Z CTRL-

syn match Normal     '\vCTRL-.|CTRL-$|Leader'

hi link fk_warning WarningMsg

let mode = b:_fk.mode

let s:warning_regexes = {
                        \ 'normal'           : { 'op+g'      : '[!=<>cdy]g',
                        \                        'do dp zu'  : '%(do|dp|zu)',
                        \                        'op+ctrl-v' : '%(c|d|y) CTRL-',
                        \                        'gw U Bar'  : '%(gw|U|\|).*',
                        \                        'ctrl-char' : 'CTRL-%([\@]|Space)',
                        \                        'g[]+ctrl'  : '[g[\]] CTRL.*',
                        \                        '[] "'      : '[[\]]"',
                        \                        },
                        \ 'visual'           : {},
                        \ 'insert'           : {},
                        \ 'command-line'     : {},
                        \ 'operator-pending' : {},
                        \ }

for regex in values(s:warning_regexes[mode])
    exe 'syn match fk_warning '.string('\v^'.regex.'$')
endfor
