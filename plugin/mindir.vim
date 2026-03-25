if !has('popupwin')
  echoerr 'mindir.vim requires Vim with +popupwin'
  finish
endif

if exists('g:loaded_mindir')
  finish
endif
let g:loaded_mindir = 1

highlight default MindirPopup ctermbg=Black guibg=Black cterm=NONE gui=NONE

let s:SEP = fnamemodify('.', ':p')[-1 :]

let s:DEFAULT_KEYS = {
      \ 'open':   "\<CR>",
      \ 'parent': 'p',
      \ 'dots':   'd',
      \ 'home':   'h',
      \ 'down':   ['j', "\<Down>"],
      \ 'up':     ['k', "\<Up>"],
      \ 'close':  ['q', "\<Esc>"],
      \ 'bottom': 'G',
      \ }

let s:state = {}

function! s:BuildKeymap()
  let l:merged = copy(s:DEFAULT_KEYS)
  call extend(l:merged, get(g:, 'mindir_keys', {}))
  let l:keymap = {}
  for [l:action, l:keys] in items(l:merged)
    for l:key in (type(l:keys) == v:t_list ? l:keys : [l:keys])
      let l:keymap[l:key] = l:action
    endfor
  endfor
  return l:keymap
endfunction

function! s:Render(dir, focus)
  let l:path = fnamemodify(a:dir, ':p')
  let l:parent = fnamemodify(l:path[: -2], ':h')

  let l:entries = []
  try
    let l:entries = readdirex(l:path, {e -> s:state.dots || e.name[0] != '.'})
  catch
    echohl ErrorMsg | echomsg 'mindir: ' . v:exception | echohl None
    return ['..'], [l:parent], 1
  endtry

  let l:dirs = []
  let l:files = []
  for l:e in l:entries
    if l:e.type ==# 'dir' || l:e.type ==# 'linkd'
      call add(l:dirs, l:e.name)
    else
      call add(l:files, l:e.name)
    endif
  endfor
  call sort(l:dirs, 'i')
  call sort(l:files, 'i')

  let l:lines = ['..']
  let l:content = [l:parent]
  for l:d in l:dirs
    call add(l:lines, l:d . s:SEP)
    call add(l:content, l:path . l:d)
  endfor
  for l:f in l:files
    call add(l:lines, l:f)
    call add(l:content, l:path . l:f)
  endfor

  let s:state.cwd = l:path
  let s:state.content = l:content

  let l:target = substitute(a:focus, '[/\\]$', '', '')
  let l:idx = l:target == '' ? -1 : index(l:content, l:target)
  let l:focus_line = l:idx >= 0 ? l:idx + 1 : 1

  return [l:lines, l:content, l:focus_line]
endfunction

function! s:ApplySyntax()
  call win_execute(s:state.winid, 'syntax clear | syntax match Directory /^\.\.$\|.*[/\\]$/')
endfunction

function! s:SetCursor(line)
  call win_execute(s:state.winid, 'call cursor(' . a:line . ', 1)')
endfunction

function! s:Navigate(dir, focus)
  let [l:lines, l:content, l:focus_line] = s:Render(a:dir, a:focus)
  call popup_settext(s:state.winid, l:lines)
  call popup_setoptions(s:state.winid, {'title': ' ' . fnamemodify(s:state.cwd[: -2], ':t') . ' '})
  call s:ApplySyntax()
  call s:SetCursor(l:focus_line)
endfunction

function! s:Selected(winid)
  let l:idx = line('.', a:winid) - 1
  if l:idx < 0 || l:idx >= len(s:state.content)
    return s:state.cwd
  endif
  return s:state.content[l:idx]
endfunction

function! s:Filter(winid, key)
  if s:state.pending ==# 'g'
    let s:state.pending = ''
    if a:key ==# 'g'
      call s:SetCursor(1)
      return 1
    endif
    " Not gg — fall through and handle this key normally
  endif

  if a:key ==# 'g' && !has_key(s:state.keymap, 'g')
    let s:state.pending = 'g'
    return 1
  endif

  let l:action = get(s:state.keymap, a:key, '')

  if l:action ==# 'open'
    let l:sel = s:Selected(a:winid)
    if isdirectory(l:sel)
      if fnamemodify(l:sel, ':p') !=? s:state.cwd
        call s:Navigate(l:sel, s:state.cwd)
      endif
    else
      call popup_close(a:winid)
      call win_execute(s:state.caller, 'edit ' . fnameescape(l:sel))
    endif
  elseif l:action ==# 'parent'
    if !empty(s:state.content)
      call s:Navigate(s:state.content[0], s:state.cwd)
    endif
  elseif l:action ==# 'dots'
    let s:state.dots = !s:state.dots
    call s:Navigate(s:state.cwd, s:Selected(a:winid))
  elseif l:action ==# 'home'
    call s:Navigate($HOME, '')
  elseif l:action ==# 'down'
    call win_execute(a:winid, 'normal! j')
  elseif l:action ==# 'up'
    call win_execute(a:winid, 'normal! k')
  elseif l:action ==# 'bottom'
    call s:SetCursor(len(s:state.content))
  elseif l:action ==# 'close'
    call popup_close(a:winid)
  endif

  return 1
endfunction

function! s:Open(...)
  let l:dir = a:0 ? a:1 : ''
  if l:dir ==# ''
    let l:dir = expand('%:p:h')
    if l:dir ==# '' || !isdirectory(l:dir)
      let l:dir = getcwd()
    endif
  endif
  let l:dir = fnamemodify(l:dir, ':p')

  let s:state = {
        \ 'cwd':     '',
        \ 'content': [],
        \ 'dots':    get(g:, 'mindir_dots', 0),
        \ 'winid':   0,
        \ 'caller':  win_getid(),
        \ 'keymap':  s:BuildKeymap(),
        \ 'pending': '',
        \ }

  let [l:lines, l:content, l:focus_line] = s:Render(l:dir, '')

  let s:state.winid = popup_create(l:lines, {
        \ 'filter':     function('s:Filter'),
        \ 'mapping':    0,
        \ 'cursorline': 1,
        \ 'border':     [],
        \ 'title':      ' ' . fnamemodify(s:state.cwd[: -2], ':t') . ' ',
        \ 'maxheight':  &lines - 6,
        \ 'maxwidth':   &columns - 10,
        \ 'minwidth':   30,
        \ 'highlight':  'MindirPopup',
        \ 'borderhighlight': ['MindirPopup'],
        \ })

  call s:ApplySyntax()
  call s:SetCursor(l:focus_line)
endfunction

command! -nargs=? -complete=dir Mindir call s:Open(<f-args>)

if get(g:, 'mindir_replace_netrw', 0)
  let g:loaded_netrwPlugin = 1
  let g:loaded_netrw = 1

  augroup mindir_netrw
    autocmd!
    autocmd BufEnter * if isdirectory(expand('%:p')) |
          \ let s:dir = expand('%:p') |
          \ bwipeout! |
          \ execute 'Mindir ' . fnameescape(s:dir) |
          \ endif
  augroup END
endif
