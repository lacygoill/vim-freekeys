vim9script noclear

# TODO: {{{
#
# Add `C-g` as a prefix with warning; same thing for `+` and `-`
#
# ---
#
# Look  at all  the 'default_mappings'  mappings, and  see if  some of  them are
# useless, or only useful with a count.
# If there are, add them as free keys (with warnings).
# Example: `go`, useful with a count, useless without
#
# I've removed  `go` from the  default keys (inside `DefaultMappings()`),  but I
# haven't added a warning for it.  To do.
#
# ---
#
# Improve help:
#
#    - readibility
#    - sections by mode
#    - integrate most of the comments which are in this file, and in our notes
#
# ---
#
# Add `op+*`, `op+#` but with warning.
#
# Although  these syntaxes  are valid,  I'm not  sure one  would use  them often
# because `*` and `#` are much more unpredictable than `2j` or `3k` for example.
# We don't systematically see all the text between current position and the next
# occurrence of the current word.
#
# Check if there are other  unpredictable `operator + motions` combinations like
# `c*`, `!*`, which would be rarely used; add them with warnings
#
# Also, I think, ` `, `CR`, `BS` could be used after an op.
# We wouldn't lose anything.  There must be synonym syntaxes.  To be verified.
#
# ---
#
# Add `<+char`, `>+char` in visual mode.
#
# ---
#
# Add other  control characters in  normal mode `C-k` is  not the only  one, for
# example `C-j` is a synonym for `j`.
#
# ---
#
# Find invalid syntaxes for insert/visual/Ex/operator-pending mode.
#
# ---
#
# After executing  `:FK -nomapcheck`, if  we hit `gh`  twice, a `Leader`  is added.
# Specifically, `CTRL-Space` becomes `CTRL-Leader`.
#
# ---
#
# Can we use the  same command (`x`, `a`, `i`, `m`, `o`, ...)  as a suffix for a
# normal command, and as a prefix for an object?
#
# The {lhs} in normal mode can be used as an operator or not.
# It can be prefixed by an operator or not.
# 2 * 2 possibilities = 4
#
#     Zi is a cmd    o_iw = pb?   NO, because `Ziw` has no meaning; neither Z nor Zi are ops
#     Zi "  an op    o_iw "       NO, because `Ziw` and `Ziiw` both work
#
#     cX "  a cmd    o_Xw "       YES, we can't type `cXw`, the command `cX`
#                                 shadows the operator `c` + the object `Xw`
#
#     cx "  an op    o_xw "       YES, we can't type `c`+`xw` because `cx`  shadows `c`
#                                 and we can't type `cx`+`xw` because `cxx` shadows `cxxw`
#
#                                 The 2 last problems are the consequence of how
#                                 Vim process the typed keys.
#                                 It doesn't invoke an operator until there's no
#                                 ambiguity anymore regarding the operator.
#                                 And as soon as it recognizes an operator without
#                                 ambiguity, it invokes it.
#
# ---
#
# The previous section  is to be reviewed further.  In  particular, I'm not sure
# of what the rules are regarding the processing of typed keys.
# For example, forget the meaning of the keys, and suppose we have:
#
#    ab   = op
#    cdef = object
#
#    abcd = op
#    ef   = object
#
# When we type `abcdef`, what happens?
#
#     ab   + cdef
# OR
#     abcd + ef
#
# Answer:
#
# Vim  processes  `abcd`  as  the  operator  iff  the  keys  are  pressed  under
# `&timeoutlen` ms.
# Otherwise,  it processes  `ab`  as the  operator iff  the  keys pressed  under
# `&timeoutlen` ms.
#
# MWE:
#
#     set showcmd
#
#     nnoremap ab <Cmd>set operatorfunc=FuncA<CR>g@
#     def FuncA(_)
#         echo 'ab'
#     enddef
#     onoremap cdef <Cmd>normal V<CR>
#
#     nnoremap abcd <Cmd>set operatorfunc=FuncB<CR>g@
#     def FuncB(_)
#         echo 'abcd'
#     enddef
#     onoremap ef <Cmd>normal V<CR>
#
# If you press `ab` then wait 1s, it's parsed as the operator calling `FuncA()`.
# If you press `abcd` without more than 1s between each keypress, it's parsed as
# the operator calling `FuncB()`.
#
# ---
#
# All in all, the syntax for operator-pending mode seems very tricky.
# It's probably  best to use  only `i` and  `a` as prefixes  in operator-pending
# mode.  And maybe even remove `prefix + i/a` (better be safe than sorry).
# Or not.  Vim uses `zi` by default, so `prefix + i/a` should be safe to keep.
#
# ---
#
# In the help, remove the color names,  replace them with some text colored with
# the proper HG; because the names don't match what we've written.
#  For example, the "red" mappings are not red when my colorscheme is dark, they
#  are orange.
#
# ---
#
# We've omitted one syntax:
#
#     command which expects an argument (like `q`, `r`, ...) + invalid argument
#
# For example, `q C-a` is an invalid key sequence, thus free.
#
# ---
#
# `:FreeKeys` ignores free sequences beginning with `m`, `'` and `@`.
# This is because it thinks it would introduce a timeout with some of our custom
# mappings.
# In reality, there would  be no timeout, because `m`, `'`  and `@` mappings are
# special: they ask for an argument.
# Check whether we have other similar special mappings causing `:Freekeys` to ignore
# whole families of mappings:
#
#     verbose filter /^.$/ map
#     global/last set from/delete _
#     global/^<Plug>/delete _
#
# How to handle the issue?
# Maybe we  should take  the habit of  executing `:Freekeys  -nomapcheck` (we've
# added a `-K` mapping for that).
#}}}
# The algorithm deliberately omits special keys: {{{
#
#     <F1> ... <F9>
#     <BS>
#     <Del>
#     <Home>
#     <End>
#     <Left>
#     <Right>
#     <Down>
#     <Up>
#     <PageDown>
#     <PageUp>
#     <LeftMouse>
#     <RightMouse>
#     <MiddleMouse>
#     <ScrollWheelDown>
#     <ScrollWheelUp>
#     <ScrollWheelLeft>
#     <ScrollWheelRight>
#     ...
#
# If we wanted to add these, to find the syntaxes leading to meaningless
# sequences, we would have to consider 2 cases:
#
#   - the special key is mapped by default to a command:
#
#         prefix + special key
#         op     + special key
#
#   - it isn't mapped to anything:
#
#         special key + anything (including nothing)
#
# We also omit the digits.
# If we wanted to include them, there would be only two possible syntaxes:
#
#     prefix + digit
#     digit  + prefix + digit
#
# `g8` and `8g8` are 2 default examples of these syntaxes.
#
# Finally, if we break a default motion/command/operator, it also creates
# new free keys.
# For example, if we use `Space` as the Leader key, then we should consider
# it as a prefix.
# In normal mode, a prefix can be used to produce meaningless sequences, in 2 syntaxes:
#
#     pfx + char    obvious, that's why we chose a Leader key in the first place
#     op  + pfx     NEW
#
# So, now we can use `d Space`, `y Space`, `c Space` ...
#}}}

# Interface {{{1
def freekeys#main(args = '') #{{{2
    var splitted_args: list<string> = split(args)
    options = {
        mode: args->matchstr('-mode\s\+\zs\%(\w\|-\)\+'),
        nospecial: splitted_args->index('-nospecial') >= 0,
        nomapcheck: splitted_args->index('-nomapcheck') >= 0,
        noleader: splitted_args->index('-noleader') >= 0,
    }

    if empty(options.mode)
        options.mode = 'normal'
    endif

    var categories: dict<list<string>> = Categories()
    var candidates: list<string> = Candidates(categories)
    var default_mappings: list<string> = DefaultMappings(categories)
    var free: list<string> = IsUnmapped(candidates, default_mappings)

    Display(free)
enddef

var options: dict<any>

def freekeys#complete( #{{{2
    arglead: string,
    cmdline: string,
    pos: number
): string

    var pat: string = '.*\s\zs-.*\%' .. (pos + 1) .. 'c'
    var from_dash_to_cursor: string = cmdline->matchstr(pat)

    if from_dash_to_cursor =~ '^-mode\s*'
        var modes: list<string> =<< trim END
            normal
            visual
            operator-pending
            insert
            command-line
        END
        return modes->join("\n")

    elseif empty(arglead) || arglead[0] == '-'
        var cmdline_options: list<string> =<< trim END
            -noleader
            -nomapcheck
            -nospecial
            -mode
        END
        return cmdline_options->join("\n")
    endif

    return ''
enddef
#}}}1
# Core {{{1
def Categories(): dict<list<string>> #{{{2
    var mode: string = options.mode
    var noleader: bool = options.noleader

    var categories: dict<list<string>> = {
        prefixes: ['"', '@', 'm', "'", '`', '[', ']', 'Z', '\', 'g', 'z', '|'],
        commands: !&tildeop ? ['~'] : [],
        operators: ['!', '<', '=', '>', 'c', 'd', 'y'] + (&tildeop ? ['~'] : []),
        operators_linewise: ['!', '<', '=', '>'],
    }

    # we add `U` as a prefix in normal mode
    # `u` and `C-r` could be used to handle undo operations
    #
    # we also add `Leader` as a prefix, unless the `-noleader` argument was
    # passed to `:FK`
    categories.prefixes += (mode == 'normal' ? ['U'] : []) + (!noleader ? ['Leader'] : [])

    categories.motions =<< trim END
        *
        #
        $
        %
        (
        )
        +
        -
        ,
        ;
        /
        ?
        B
        E
        F
        G
        H
        L
        M
        N
        T
        W
        ^
        _
        b
        e
        f
        h
        j
        k
        l
        n
        t
        w
        {
        }
        BS
        CR
    END
    categories.motions += [' ']

    # The 14 following motions stay on the line most of the time.{{{
    # The last 11 can move across different lines, but very limitedly.
    # So it doesn't make a lot of sense to use any of them after an operator
    # which acts upon a set of lines.
    # For example:
    #
    #     >h    ✘   works but not intuitive
    #     >>    ✔   better
    #
    #     =b    ✘   the cursor being at the beginning of a line
    #     =k    ✔
    #
    #     !w    ✘   the cursor being at the end of a line
    #     !j    ✔
    #
    # Thus, the syntax:
    #
    #     linewise operator + motion which stays on current line
    #
    # ... although valid, is unintuitive and useless.
    #
    # This creates new free key sequences.
    #}}}
    categories.motions_limited =<< trim END
        $
        ^
        |
        w
        B
        E
        W
        b
        e
        h
        l
        BS
        CR
    END
    categories.motions_limited += [' ']

    # We don't consider Tab as a motion, because even though `C-i` jumps forward
    # in the jumplist, by default, `operator + Tab` doesn't do anything.
    # So, we could consider it as a command, which gives us the free key sequences:
    #
    #     operator + Tab

    var l: list<string> =<< trim END
        &
        .
        :
        A
        C
        D
        I
        J
        K
        O
        P
        Q
        R
        S
        V
        X
        Y
        a
        i
        o
        p
        q
        r
        s
        u
        v
        x
        Tab
    END
    categories.commands += l

    # If the `-noleader` argument wasn't provided,  it means we want the algo to
    # consider the usage of a Leader  key.  So, we remove `g:mapleader` from all
    # the categories.
    # Indeed, the key stored in `g:mapleader`  should be considered as a prefix,
    # and nothing else.
    if !noleader
        for [category, keys] in categories->items()
            keys->filter((_, v: string): bool => v != g:mapleader)
        endfor
    endif
    return categories
enddef

def Candidates(categories: dict<list<string>>): list<string> #{{{2
    var syntaxes: dict<list<list<string>>> = Syntaxes(categories)
    var candidates: list<string>

    for [left_key_category, right_key_category] in syntaxes->values()
        for key1 in left_key_category
            for key2 in right_key_category
                candidates += [[key1, key2]->join('')]
            endfor
        endfor
    endfor
    return candidates
enddef

def DefaultMappings(categories: dict<list<string>>): list<string> #{{{2
    var mode: string = options.mode
    var prefixes: list<string> = categories.prefixes
    var operators: list<string> = categories.operators

    # NOTE:{{{
    #
    # Why can we copy something in the pseudo-register `~`?
    #
    #     "~yy
    #
    # And why can't we paste it?
    #
    #     "~p
    #
    # ---
    #
    # What do `@_` and `@~`?
    # They don't raise the error:
    #
    #     E354: Invalid register name:˜
    #
    # ---
    #
    # We don't remove `m(` and `m(`,  because you can't really change them.  Vim
    # constantly updates them automatically, so  that they match the beginning /
    # end of the current sentence.
    #
    # Same thing for `m{` and `m}`.
    # They match the beginning / end of the current paragraph.
    #
    # Same thing for `m.`, and `m^`.
    # It doesn't seem possible to manually set those marks.
    # They match the last position where resp. a change was made, and
    # insertion mode was stopped.
    #}}}
    var default_mappings: dict<dict<any>> = {
        command-line: {},
        insert: {},
        operator-pending: {},
    }

    default_mappings.normal = {
        'prefix + letter': PrefixPlusLetter(),
        'double prefix': DoublePrefix(prefixes),
        'op + forbidden cmd': OpPlusForbiddenCmd(operators),

        'mark': ['m"', "m'", 'm<', 'm>', 'm[', 'm]', 'm`'],
        'double operator': ['!!', '==', '<<', '>>', 'cc', 'dd', 'yy'],
        'at': ['@"', '@*', '@+', '@-', '@.', '@/', '@:', '@='],

        'backtick': ['`"', '`.', '`(', '`)', '`<', '`>',
                     '`[', '`]', '`^', '``', '`{', '`}'],

        'double quote': ['"+', '"-', '"*', '"/', '"=', '"%', '"#',
                         '":', '".', '"_'],

        'single quote': ['''"', "'.", "'(", "')", "'<", "'>",
                         "'[", "']", "'^", "'`", "'{", "'}"],
    }

    default_mappings.normal.various =<< trim END
        [*
        ]*
        [#
        ]#
        ['
        ]'
        [(
        ])
        [{
        ]}
        []
        ][
        [`
        ]`
        [/
        ]/
        [D
        ]D
        [I
        ]I
        [M
        ]M
        [P
        ]P
        [S
        ]S
        [c
        ]c
        [d
        ]d
        [f
        ]f
        [i
        ]i
        [m
        ]m
        [p
        ]p
        [s
        ]s
        [z
        ]z
        g#
        g*
        g$
        g&
        g'
        g+
        g,
        g-
        g;
        g<
        g?
        g@
        gD
        gE
        gF
        gH
        gI
        gJ
        gN
        gP
        gQ
        gR
        gT
        gU
        g]
        g^
        g_
        g`
        gd
        ge
        gf
        gh
        gi
        gj
        gk
        gm
        gn
        gp
        gq
        gr
        gs
        gt
        gu
        gv
        gw
        g~
        ZQ
        z#
        z+
        z-
        z.
        z=
        zCR
        zA
        zC
        zD
        zE
        zF
        zG
        zH
        zL
        zM
        zN
        zO
        zR
        zW
        zX
        z^
        za
        zb
        zc
        zd
        ze
        zf
        zg
        zh
        zi
        zj
        zk
        zl
        zm
        zn
        zo
        zr
        zs
        zt
        zv
        zw
        zx
    END

    default_mappings.visual = {'prefix + letter': PrefixPlusLetter()}

    default_mappings.visual.various =<< trim END
        a(
        a)
        a<
        a>
        aB
        aW
        a[
        a]
        a`
        ab
        ap
        as
        at
        aw
        a{
        a}
        g?
        gF
        gN
        g]
        gf
        gn
        gv
        i(
        i)
        i<
        i>
        iB
        iW
        i[
        i]
        i`
        ib
        ip
        is
        it
        iw
        i{
        i}
        i'
        a'
    END

    var result: list<string>
    for a_list in default_mappings[mode]->values()
        result += a_list
    endfor

    return result
enddef

def IsUnmapped( #{{{2
    candidates: list<string>,
    default_mappings: list<string>
): list<string>

    var nomapcheck: bool = options.nomapcheck
    var nospecial: bool = options.nospecial
    var mode: string = options.mode

    # `"`, `@`, `m`, `'`, ```, `[` and `]` are special motions, commands,{{{
    # because contrary to the other ones, they wait for an argument.
    # This creates a new free key sequence, each time they don't understand an
    # argument.
    # That's why we put them in the prefixes category.
    #
    # This choice of categorization has a consequence: we'll have to REMOVE
    # all the "mapped_to_sth" key sequences generated by our algorithm.
    # If instead we had chosen to categorize them as motions or commands, we
    # would have to do the opposite: ADD the unmapped key sequences forgotten by
    # the algorithm.
    #
    # Why this choice?
    # The "mapped_to_sth" sequences seem to be more structured than the unmapped
    # ones.  You can express a large chunk of them with a simple syntax:
    #
    #         prefix + letter
    #
    # So, it's easier to *remove mapped* sequences, than to *add unmapped* sequences.
    #}}}

    # If  a sequence  shadows another  one, or  it overrides  a default  action,
    # remove it.
    return candidates
        ->filter((_, key: string): bool =>
            index(default_mappings, key) == -1
            && (
                !nospecial && nomapcheck
                ||
                nospecial && nomapcheck && key !~ '[[:punct:]]'
                ||
                !nospecial && !nomapcheck
                    && TranslateSpecialKey(key)
                    ->mapcheck(mode[0])
                    ->empty()
                ||
                nospecial && !nomapcheck && key !~ '[[:punct:]]'
                    && TranslateSpecialKey(key)
                    ->mapcheck(mode[0])
                    ->empty()
               ))
enddef

def Display(free: list<string>) #{{{2
    # Get the unique id of the window we're coming from.
    # Necessary to restore the focus correctly when we'll close the FK window.
    var id_orig_window: number = win_getid()

    var tempfile: string = tempname() .. '/FreeKeys'
    execute 'topleft :' .. (&columns / 6) .. ' vnew ' .. tempfile
    b:_fk = extend(options,
        {id_orig_window: id_orig_window, leader_key: 'shown'})

    &l:bufhidden = 'delete'
    &l:buftype = 'nofile'
    &l:buflisted = false
    &l:swapfile = false
    &l:wrap = false
    &l:winfixwidth = true

    free->setline(1)
    sort

    # Make the space key more visible.
    silent keepjumps keeppatterns :% substitute/ /Space/e

    # Add spaces around special keys:   BS, CR, CTRL-, Leader, Space, Tab
    # to make them more readable
    silent keepjumps keeppatterns :% substitute/^Leader\zs\ze\S/ /e
    silent keepjumps keeppatterns :% substitute/\%(CTRL-\)\@5<!\%(BS\|CR\|CTRL-\|Leader\|Space\|Tab\)$/ &/e
    silent keepjumps keeppatterns :% substitute/  / /e

    # If there're double sequences, like `operator + space`:
    #
    #     Leader = Space
    #     op_l + motion_s
    #     op   + leader
    #
    # ... remove them.
    silent keepjumps keeppatterns :% substitute/^\(.*\)\n\1$/\1/e

    # Trim whitespace.  There shouldn't be any, but better be safe than sorry.
    silent keepjumps keeppatterns :% substitute/\s*$//e

    [options.mode->substitute('.', '\U&', 'g') .. ' MODE', '']
        ->append(0)
    cursor(1, 1)

    nnoremap <buffer><nowait> <CR> <Cmd>call <SID>ShowHelp()<CR>
    nnoremap <buffer><nowait> q <Cmd>call <SID>CloseWindow()<CR>
    nnoremap <buffer><nowait> g? <Cmd>help freekeys-mappings<CR>

    execute 'nnoremap <buffer><nowait> gl <Cmd>call <SID>ToggleLeaderKey(v:' .. options.noleader .. ')<CR>'
enddef

def Syntaxes(categories: dict<list<string>>): dict<list<list<string>>> #{{{2
    var mode: string = options.mode

    var prefixes: list<string> = categories.prefixes
    var motions: list<string> = categories.motions
    var motions_limited: list<string> = categories.motions_limited
    var commands: list<string> = categories.commands
    var operators: list<string> = categories.operators
    var operators_linewise: list<string> = categories.operators_linewise

    var chars: list<string> = prefixes + motions + commands + operators

    var syntaxes: dict<dict<list<list<string>>>> = {
        insert: {'ctrl + char': [['CTRL-'], chars]},
        command-line: {'ctrl + char': [['CTRL-'], chars]},
        operator-pending: {'adverb + char': [['i', 'a'], chars]},
    }

    # In visual mode, we don't put `i`, `a` inside the commands category
    # because of the convention which uses them as prefix to build
    # text-objects.

    syntaxes.visual = {
          'pfx + char': [prefixes, chars],
          'pfx + CTRL': [prefixes, ['CTRL-']],
          'CTRL + char': [['CTRL-'], chars],
          'cmd + char': [['&', '.', 'Q', 'Tab'], chars],
    }

    # Most of the meaningless sequences need at least 2 keys.
    # But one of them need at least 3 keys:    digit + prefix + digit

    syntaxes.normal = {
          'pfx + char':      [prefixes, chars],
          'op + cmd':        [operators, commands],
          'op1 + op2':       [operators, operators],
          'op + pfx':        [operators, prefixes],
          'op_l + motion_s': [operators_linewise, motions_limited],
          'CTRL + char':     [['CTRL-'], ['K', 'Space', '\', '_', '@']],
          'op + CTRL':       [operators, ['CTRL-']],
          'pfx + CTRL':      [prefixes, ['CTRL-']],
    }

    # These 8 syntaxes should produce all 2-key meaningless sequences.
    # For n-key meaningless sequences (n>2), there's only 1 possible syntax:
    #
    #    - 2-key meaningless + any (n-2)-key sequence

    # CTRL is treated as a special prefix.
    # Indeed, there are very few USABLE unmapped key sequences with `CTRL-`.
    #
    # Beginning with `CTRL-`, I only found 4:
    #
    #     CTRL-K
    #     CTRL-\
    #     CTRL-_
    #     CTRL-Space or CTRL-@
    #
    # Ending with `CTRL-`, I only found 2:
    #
    #     op     + CTRL-
    #     prefix + CTRL-    with some exceptions like g C-G

    return syntaxes[mode]
enddef

def PrefixPlusLetter(): list<string> #{{{2
    var prefix_plus_letter: list<string>

    for prefix in ['"', '@', 'm', "'", '`']
        prefix_plus_letter += (
                range(char2nr('a'), char2nr('z'))
              + range(char2nr('A'), char2nr('Z'))
              )->mapnew((_, v: number): string => prefix .. nr2char(v))
    endfor
    return prefix_plus_letter
enddef

def DoublePrefix(prefixes: list<string>): list<string> #{{{2
    var double_prefix: list<string>

    for prefix in prefixes
        double_prefix += [prefix .. prefix]
    endfor

    return double_prefix
enddef

def OpPlusForbiddenCmd(operators: list<string>): list<string> #{{{2
    var op_plus_forbidden_cmd: list<string>

    for operator in operators
        for command in ['a', 'i']
            op_plus_forbidden_cmd += [operator .. command]
        endfor
    endfor

    for operator in ['c', 'd', 'y'] + (&tildeop ? ['~'] : [])
        for command in ['v', 'V']
            op_plus_forbidden_cmd += [operator .. command]
        endfor
    endfor

    return op_plus_forbidden_cmd
enddef

def TranslateSpecialKey(key: string): string #{{{2
    if key =~ 'CTRL-$'
        return ''
    endif
    return key
        ->substitute('Leader', g:mapleader, 'g')
        ->substitute('Tab', '<Tab>', 'g')
        ->substitute('CR', '<CR>', 'g')
        ->substitute('BS', '<BS>', 'g')
enddef

def ShowHelp() #{{{2
    # All tags  from the plugin begin  with the prefix `fk_`  to avoid conflicts
    # with default ones.  Add it to the key sequence under the cursor.

    var topic: string = 'fk_' .. getline('.')
        ->matchstr('\S.*\S')
        ->escape('\')
        ->substitute(' ', '_', 'g')

    var substitutions: dict<list<string>> = {
        'U':         ['U\zs.*', ''],
        'Bar':       ['\zs|.*', 'Bar'],
        '[] ctrl-':  ['[[\]]_CTRL-', 'fk_[]_CTRL-'],
        '[] "':      ['[[\]]"', 'fk_[]_double_quote'],
        'op ctrl-':  ['[cdy]_CTRL-', 'fk_operator_and_CTRL-V'],
        'op prefix': ['[!<>=cdy]g', 'fk_operator_and_prefix_g'],
    }

    for [pat, rep] in substitutions->values()
        topic = topic->substitute('^\Cfk_' .. pat .. '$', rep, '')
    endfor

    execute 'silent! help ' .. topic
enddef

def CloseWindow() #{{{2
    if reg_recording() != ''
        feedkeys('q', 'in')
        return
    endif
    var id_orig_window: number = b:_fk.id_orig_window
    quit
    win_gotoid(id_orig_window)
enddef

def ToggleLeaderKey(noleader: bool) #{{{2
    if noleader
        return
    endif

    var curpos: list<number> = getcurpos()

    if b:_fk.leader_key == 'shown'
        execute 'silent keepjumps keeppatterns :% substitute/Leader/'
            .. g:mapleader->substitute(' ', 'Space', '') .. '/e'
    else
        execute 'silent keepjumps keeppatterns :% substitute/'
            .. g:mapleader->substitute(' ', 'Space', '') .. '/Leader/e'
    endif

    setpos('.', curpos)

    b:_fk.leader_key = ['shown', 'replaced']
        ->filter((_, v: string): bool => v != b:_fk.leader_key)[0]
enddef

