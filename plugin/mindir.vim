" mindir.vim — minimal directory browser for gVim 9.0+ on Windows 11
" Inspired by vim-readdir by Aristotle Pagaltzis (https://github.com/ap/vim-readdir)
" ~/vimfiles/plugin/mindir.vim
"
" e/2-click = open   p = up   d = dotfiles   h = home
" r = refresh   q = quit

if v:versionlong < 9000000
  echoerr 'mindir.vim requires Vim 9.0+'
  finish
endif

let g:loaded_netrwPlugin = 1

if exists('g:loaded_mindir')
  finish
endif
let g:loaded_mindir = 1

let s:SEP = fnamemodify('.', ':p')[-1 :]

function! s:Selected()
  let l:i = line('.') - 1
  if l:i < 0 || l:i >= len(b:mindir.content)
    return b:mindir.cwd
  endif
  return b:mindir.content[l:i]
endfunction

function! s:Render(dir, focus)
  let l:path = fnamemodify(a:dir, ':p')
  let l:parent = fnamemodify(l:path[: -2], ':h')

  " readdirex: one FindFirstFile call returns name + type together,
  " avoids N separate GetFileAttributes syscalls from isdirectory()
  let l:entries = []
  try
    let l:entries = readdirex(l:path, {e -> b:mindir.dots || e.name[0] != '.'})
  catch
    echohl ErrorMsg | echomsg 'mindir: ' . v:exception | echohl None
    return
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

  setlocal modifiable
  call deletebufline(bufnr(), 1, line('$'))
  call setline(1, l:lines)
  setlocal nomodifiable nomodified

  let b:mindir.cwd = l:path
  let b:mindir.content = l:content

  let l:target = substitute(a:focus, '[/\\]$', '', '')
  let l:idx = l:target == '' ? -1 : index(l:content, l:target)
  call cursor(l:idx >= 0 ? l:idx + 1 : 1, 1)

  let l:pfx = get(g:, 'mindir_prefix', 'd::')
  if l:pfx ==# ''
    let l:pfx = ' '
  endif
  silent! execute 'file' fnameescape(l:pfx . fnamemodify(l:path[: -2], ':t'))
  silent execute 'lchdir' fnameescape(l:path)
endfunction

function! s:Enter()
  let l:target = s:Selected()
  if isdirectory(l:target)
    " ==? is case-insensitive — required for Windows paths
    if fnamemodify(l:target, ':p') ==? b:mindir.cwd
      return
    endif
    call s:Render(l:target, b:mindir.cwd)
  else
    let l:mindir_buf = bufnr()
    execute 'edit' fnameescape(l:target)
    execute 'silent! bwipeout' l:mindir_buf
  endif
endfunction

function! s:Up()
  if empty(b:mindir.content)
    return
  endif
  call s:Render(b:mindir.content[0], b:mindir.cwd)
endfunction

function! s:Open()
  let l:target = s:Selected()
  if isdirectory(l:target)
    return
  endif
  execute 'edit' fnameescape(l:target)
endfunction

function! s:ToggleDots()
  let b:mindir.dots = !b:mindir.dots
  call s:Render(b:mindir.cwd, s:Selected())
endfunction

function! s:Refresh()
  call s:Render(b:mindir.cwd, s:Selected())
endfunction

function! s:Quit()
  let l:buf = bufnr()
  if winnr('$') > 1
    close
  elseif len(getbufinfo({'buflisted': 1})) > 0
    bprevious
  else
    quit
  endif
  execute 'silent! bwipeout' l:buf
endfunction

function! s:Setup(dir)
  setlocal buftype=nofile bufhidden=hide buflisted
  setlocal noswapfile undolevels=-1 nowrap nomodifiable
  setlocal cursorline nonumber norelativenumber signcolumn=no

  let b:mindir = {'cwd': '', 'content': [], 'dots': get(g:, 'mindir_dots', 1)}

  call s:Render(a:dir, '')

  nnoremap <buffer>        <Plug>(mindir-enter)   :call <SID>Enter()<CR>
  nnoremap <buffer>        <Plug>(mindir-up)      :call <SID>Up()<CR>
  nnoremap <buffer>        <Plug>(mindir-dots)    :call <SID>ToggleDots()<CR>
  nnoremap <buffer>        <Plug>(mindir-home)    :call <SID>Render($HOME, '')<CR>
  nnoremap <buffer>        <Plug>(mindir-refresh) :call <SID>Refresh()<CR>
  nnoremap <buffer>        <Plug>(mindir-open)    :call <SID>Open()<CR>
  nnoremap <buffer>        <Plug>(mindir-quit)    :call <SID>Quit()<CR>

  nmap <buffer><nowait> e             <Plug>(mindir-enter)
  nmap <buffer><nowait> <2-LeftMouse> <Plug>(mindir-enter)
  nmap <buffer><nowait> p             <Plug>(mindir-up)
  nmap <buffer><nowait> d             <Plug>(mindir-dots)
  nmap <buffer><nowait> h             <Plug>(mindir-home)
  nmap <buffer><nowait> r             <Plug>(mindir-refresh)
  nmap <buffer><nowait> o             <Plug>(mindir-open)
  nmap <buffer><nowait> q             <Plug>(mindir-quit)

  syntax clear
  syntax match Directory /^\.\.$\|.*[/\\]$/

  setlocal filetype=mindir
endfunction

function! s:OnBufEnter()
  if exists('b:mindir')
    silent execute 'lchdir' fnameescape(b:mindir.cwd)
    return
  endif
  let l:path = expand('%:p')
  if !isdirectory(l:path)
    return
  endif
  call s:Setup(l:path)
endfunction

augroup Mindir
  autocmd!
  autocmd BufEnter * call s:OnBufEnter()
augroup END
