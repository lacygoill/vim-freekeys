vim9script

if exists('b:current_syntax')
    finish
endif

highlight fk_operator ctermfg=black ctermbg=173    guifg=#000000 guibg=#d78700
highlight fk_command  ctermfg=black ctermbg=yellow guifg=#000000 guibg=#ffff00
highlight fk_motion   ctermfg=black ctermbg=green  guifg=#000000 guibg=#00d700

syntax match fk_operator '[!=<>cdy]'
syntax match fk_command  '[~@&qQrRYuUiIoOpPaAsSDJK:xXCvVm.]\|Tab'
syntax match fk_motion   '[#$%()*+,-/0;?BEFGHLMNTW^_befhjklntw{|}]'

syntax keyword fk_command Tab
syntax keyword fk_motion  Space BS CR

syntax keyword Normal NORMAL VISUAL INSERT OPERATOR PENDING COMMAND LINE MODE

# We can't use `CTRL-` as a keyword because sometimes it fails:
#
#     CTRL-_
#     CTRL-K
#     Z CTRL-

syntax match Normal 'CTRL-.\|CTRL-$\|Leader'

highlight def link fk_warning WarningMsg

const WARNING_REGEXES: dict<dict<string>> = {
    normal: {
        'op+g': '[!=<>cdy]g',
        'do dp zu': '\%(do\|dp\|zu\)',
        'op+ctrl-v': '\%(c\|d\|y\) CTRL-',
        'U Bar': '\%(U\||\).*',
        'ctrl-char': 'CTRL-\%([\@]\|Space\)',
        'g[]+ctrl': '[g[\]] CTRL.*',
        '[] "': '[[\]]"',
    },
    visual: {},
    insert: {},
    command-line: {},
    operator-pending: {},
}

# FIXME:
# How to pass the mode from the `autoload/` file to this syntax file?
# We can't use this:
#
#     tabnew +let\ b:_fk=... freekeys
#
# ... because it  seems the `let` command  is executed after the  syntax file is
# sourced.

for regex: string in WARNING_REGEXES['normal']->values()
    execute 'syntax match fk_warning ' .. string('^' .. regex .. '$')
endfor

b:current_syntax = 'freekeys'
