# vim-mindir

Popup-based directory browser for Vim 8.2+ (requires `+popupwin`).

## Install

```vim
Plug 'gsa9/vim-mindir'
```

## Usage

```vim
:Mindir          " browse from current file's directory
:Mindir ~/code   " browse a specific directory
```

Directories are listed first (with a trailing separator), then files, both sorted case-insensitively. The `..` entry at the top always leads to the parent directory.

### Keys

| Key | Action |
|---|---|
| `CR` | Open file or enter directory |
| `p` | Go to parent directory |
| `d` | Toggle dotfiles |
| `h` | Go to home directory |
| `j` / `Down` | Move cursor down |
| `k` / `Up` | Move cursor up |
| `Esc` | Close popup |

### Customizing keys

Override individual actions via `g:mindir_keys`. Unspecified actions keep their defaults.

```vim
let g:mindir_keys = {
      \ 'open':   'o',
      \ 'parent': '-',
      \ 'home':   '~',
      \ }
```

Available actions: `open`, `parent`, `dots`, `home`, `down`, `up`, `close`.

`j`/`k`, arrow keys, and `Esc` are always active regardless of overrides.

## Options

| Variable | Values | Default |
|---|---|---|
| `g:mindir_dots` | `0` / `1` — show dotfiles on startup | `0` |
| `g:mindir_keys` | `{}` — action-to-key overrides (see above) | `{}` |

## Migrating from the buffer-based version

If you have an `after/ftplugin/mindir.vim` file with key remappings, it is no longer needed and can be removed. Use `g:mindir_keys` instead.

## Attribution

Inspired by [ap/vim-readdir](https://github.com/ap/vim-readdir).
Built with [Claude Code](https://claude.ai/code) by Anthropic.
