# vim-mindir

Minimal directory browser for Vim/GVim 9.0+ on Windows.
Replaces netrw with a fast, keyboard-driven file listing using `readdirex`.

## Install

```vim
Plug 'gsa9/vim-mindir'
```

netrw is disabled automatically when mindir loads.

## Usage

Open any directory (`:edit .`, `:edit ~/`, etc.) and mindir takes over.

| Key | Action |
|---|---|
| `e` | Enter directory (no-op on files) |
| `o` / double-click | Open file (wipes mindir buffer) or enter directory |
| `<CR>` | Open file (keeps mindir buffer listed), no-op on directories |
| `p` | Go to parent directory |
| `d` | Toggle dotfiles |
| `h` | Go to home directory |
| `r` | Refresh listing |
| `q` | Quit browser |

### e vs o vs CR

| | On file | On directory |
|---|---|---|
| `e` | No-op | Navigate in-place (same buffer) |
| `o` | Open file, wipe mindir buffer (clean exit) | No-op |
| `<CR>` | Open file, keep mindir buffer listed (provisional open) | No-op |

`e` is directory navigation only — it enters directories and ignores files.
`o` is a clean exit — the mindir buffer is removed from the buffer list after
opening the file. `<CR>` is a provisional open — the file opens but mindir
stays in the buffer list so you can switch back to it.

## Design

- One `readdirex` call per render — returns name and type together, avoids
  per-entry `GetFileAttributes` syscalls.
- Buffer settings: `buftype=nofile bufhidden=hide buflisted`. The buffer stays
  in the buffer list when hidden (visible in buftab) until explicitly wiped.
- `o` saves the mindir buffer number before `:edit`, then runs
  `silent! bwipeout` on it after the file loads.
- `<CR>` opens the file without wiping the mindir buffer, so it remains in the
  buffer list for quick switching.
- `e` checks `isdirectory()` and returns early on files to prevent accidental
  file opens when navigating directories.

## Remapping

The defaults are opinionated single-letter keys optimized for touch-typing.
The filetype is `mindir`. To remap keys, create `after/ftplugin/mindir.vim`.
These are buffer-local mappings (`<buffer>`) — they only apply inside mindir
buffers and do not interfere with the same keys in regular buffers.

Available `<Plug>` mappings:

| Plug | Default | Action |
|---|---|---|
| `<Plug>(mindir-dir)` | `e` | Enter directory (no-op on files) |
| `<Plug>(mindir-open)` | `o` | Open file (wipes mindir buffer), no-op on directories |
| `<Plug>(mindir-enter)` | double-click | Open file (wipes mindir buffer) or enter directory |
| `<Plug>(mindir-peek)` | `<CR>` | Open file (keeps mindir listed), no-op on directories |
| `<Plug>(mindir-up)` | `p` | Go to parent directory |
| `<Plug>(mindir-dots)` | `d` | Toggle dotfiles |
| `<Plug>(mindir-home)` | `h` | Go to home directory |
| `<Plug>(mindir-refresh)` | `r` | Refresh listing |
| `<Plug>(mindir-quit)` | `q` | Quit browser |

Example — restore classic keys:

```vim
" after/ftplugin/mindir.vim
nmap <buffer><nowait> <CR> <Plug>(mindir-enter)
nmap <buffer><nowait> - <Plug>(mindir-up)
nmap <buffer><nowait> ~ <Plug>(mindir-home)
```

## Tab title

The mindir buffer names itself `{prefix}<dirname>`. The prefix defaults to `d::` and can be customized via `g:mindir_prefix`.

## Options

| Variable | Values | Default |
|---|---|---|
| `g:mindir_dots` | `0/1` show dotfiles by default | `1` |
| `g:mindir_prefix` | string prepended to dirname in buffer name (fallback `' '` if empty) | `'d::'` |

## Attribution

Inspired by [ap/vim-readdir](https://github.com/ap/vim-readdir).
Built with [Claude Code](https://claude.ai/code) by Anthropic.
