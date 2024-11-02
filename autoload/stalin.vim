" Vim status line plugin
" Maintainer:   matveyt
" Last Change:  2024 Nov 02
" License:      VIM License
" URL:          https://github.com/matveyt/vim-stalin

let s:save_cpo = &cpo
set cpo&vim

let s:vmode = {
    \ 'v': 'VISUAL', 'V': 'V-LINE', "\<C-V>": 'V-BLOC',
    \ 's': 'SELECT', 'S': 'S-LINE', "\<C-S>": 'S-BLOC'
\ }

let s:messages = #{
    \ en: ['INSERT', 'RPLACE'],
    \ by: ['УСТАЎК', 'ЗАМЕНА'],
    \ cr: ['UMETAK', 'ZAMJEN'],
    \ cz: ['VLOŽKA', 'NAHRAD'],
    \ pl: ['WSTAWK', 'ZAMIEŃ'],
    \ ru: ['ВСТВКА', 'ЗАМЕНА'],
    \ se: ['УМЕТАК', 'ЗАМЕНА'],
    \ sk: ['VLOŽKA', 'NAHRAD'],
    \ uk: ['ВСТВКА', 'ЗАМIНА'],
\ }

function! stalin#vmode() abort
    return get(s:vmode, mode(), '')
endfunction

function! stalin#localize(num) abort
    return get(s:messages, &iminsert ? slice(b:keymap_name, 0, 2)->tolower() : 'en',
        \ s:messages.en)[a:num]
endfunction

function! stalin#branch() abort
    let l:result = get(g:, 'loaded_fugitive') ? fugitive#Head(-1) : ''
    if empty(l:result)
        " nothing to do
    elseif has('gui_running') || get(g:, 'GuiLoaded')
        let l:result = nr2char(0x652f, v:true) .. l:result
    else
        let l:result = printf('[%s]', l:result)
    endif
    return l:result
endfunction

function s:trhelper(item, which=0) abort
    if empty(a:item[1])
        let l:result = ''
    elseif a:item[1] =~# '^\d\?\*$'
        let l:result = '%' .. a:item[1]
    else
        let l:result = printf('%%#%s#', a:item[1])
    endif
    if a:which == 0
        let l:result ..= a:item[0]
    elseif a:which > 0
        let l:result ..= printf('%%( %s %%)', a:item[0])
    endif
    return l:result
endfunction

function s:advance(item, color, indic) abort
    let l:result = get(a:indic, a:item, [a:item, a:color])
    return len(l:result) == 1 ? [l:result[0], a:color] : l:result
endfunction

function s:translate(item, indic, sep1, sep2) abort
    if a:item[0] =~# printf('[^a-z%s%s]', a:sep1, a:sep2)
        return s:trhelper(a:item, 1)
    endif

    let l:subitems = split(a:item[0], a:sep1)
    if len(l:subitems) > 1
        let l:status = ''
        for l:subitem in l:subitems
            let l:next = s:advance(l:subitem, a:item[1], a:indic)
            let l:status ..= empty(l:subitem) ? s:trhelper(l:next) :
                \ s:translate(l:next, a:indic, a:sep1, a:sep2)
        endfor
        return l:status
    endif

    let l:subitems = split(a:item[0], a:sep2)
    let l:num = len(l:subitems)
    if l:num > 1
        let l:status = s:trhelper(a:item, -1)
        for l:subitem in l:subitems
            let l:next = s:advance(l:subitem, '', a:indic)
            let l:num -= 1
            if l:num <= 0
                let l:status ..= s:translate(l:next, a:indic, '', a:sep2)
            else
                let l:status ..= '%(' .. s:translate(l:next, a:indic, '', a:sep2) ..
                    \ s:trhelper([a:sep2 .. '%)', repeat(a:item[1], !empty(l:next[1]))])
            endif
        endfor
        return l:status
    endif

    if has_key(a:indic, a:item[0])
        let l:next = s:advance(a:item[0], a:item[1], a:indic)
        return s:translate(l:next, a:indic, a:sep1, a:sep2)
    endif

    return s:trhelper(a:item, 1)
endfunction

let s:indic = {
    \ '': ['%=', 'CursorLine'],
    \ 'mode': ['normal,cmdline,visual,insert,replace,terminal'],
    \ 'normal': ['%{repeat("NORMAL",mode()==#"n")}', 'CursorLine'],
    \ 'cmdline': ['%{repeat("CMDLIN",mode()==#"c")}', 'PMenu'],
    \ 'visual': ['%{stalin#vmode()}', 'Visual'],
    \ 'insert': ['%{mode()==#"i"?stalin#localize(0):""}',
        \ 'DiffAdd'],
    \ 'replace': ['%{mode()==#"R"?stalin#localize(1):""}',
        \ 'DiffDelete'],
    \ 'terminal': ['%{repeat("TERMNL",mode()==#"t")}', '*'],
    \ 'branch': ['%{stalin#branch()}', 'CursorLine'],
    \ 'buffer': ['%n:%<%t%( %m%)', '*'],
    \ 'cmdloc': ['%S', 'Search'],
    \ 'flags': ['paste|spell|ft|ff|fe', 'CursorLine'],
    \ 'ft': ['%{&ft}'],
    \ 'ff': ['%{&ff}'],
    \ 'fe': ['%{empty(&fenc)?&enc:&fenc}%{repeat(":bom",&bomb)}'],
    \ 'paste': ['%{repeat("paste",&paste)}', 'Search'],
    \ 'spell': ['%{repeat("spell",&spell)}', 'Search'],
    \ 'ruler': ['%l:%c%V %p%%', '*'],
\ }

function! stalin#build(fmt, ...) abort
    let l:indic = extend(copy(s:indic), get(a:, 1, {}))
    return s:translate([a:fmt, ''], l:indic, ',', "\<Bar>")
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
