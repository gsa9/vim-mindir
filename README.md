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

### Replacing netrw

Set `g:mindir_replace_netrw` before the plugin loads to disable netrw and redirect all directory opens to mindir:

```vim
let g:mindir_replace_netrw = 1
```

Now `:e .`, `:e ~/code`, `:split ~/Downloads`, etc. all launch the popup instead of netrw.

### Keys

| Key | Action |
|---|---|
| `CR` | Open file or enter directory |
| `p` | Go to parent directory |
| `d` | Toggle dotfiles |
| `h` | Go to home directory |
| `j` / `Down` | Move cursor down |
| `k` / `Up` | Move cursor up |
| `gg` | Go to first entry |
| `G` | Go to last entry |
| `Esc` / `q` | Close popup |

### Customizing keys

Override individual actions via `g:mindir_keys`. Unspecified actions keep their defaults.

All actions and their defaults:

```vim
let g:mindir_keys = {
      \ 'open':   "\<CR>",
      \ 'parent': 'p',
      \ 'dots':   'd',
      \ 'home':   'h',
      \ 'down':   ['j', "\<Down>"],
      \ 'up':     ['k', "\<Up>"],
      \ 'close':  ['q', "\<Esc>"],
      \ 'bottom': 'G',
      \ }
```

Values can be a single key or a list of keys. Only include actions you want to change — unspecified actions keep their defaults:

```vim
let g:mindir_keys = {'open': 'l', 'parent': 'h'}
```

Available actions: `open`, `parent`, `dots`, `home`, `down`, `up`, `close`, `bottom`.

`gg` (go to first entry) is built-in and always available unless `g` is mapped to an action via `g:mindir_keys`.

### Appearance

The popup sizes itself to fit its contents, up to a maximum based on the Vim window dimensions. Long listings scroll automatically.

The popup uses the `MindirPopup` highlight group (black background by default). Directories and `..` use the built-in `Directory` group. Override either in your vimrc:

```vim
" popup body and border
highlight MindirPopup ctermbg=DarkBlue guibg=#1a1a2e

" directory entries
highlight Directory ctermfg=Cyan guifg=#5eead4
```

The `cursorline` highlight inside the popup follows your `PmenuSel` group.

### Example mappings

The plugin does not define any global keymaps — only the `:Mindir` command. Add mappings to your vimrc to launch it quickly:

```vim
" browse from the current file's directory
nnoremap <Leader>e :Mindir<CR>

" browse from the working directory
nnoremap <Leader>. :Mindir .<CR>

" browse from home
nnoremap <Leader>~ :Mindir ~<CR>

" browse a project root
nnoremap <Leader>p :Mindir ~/code<CR>
```

Any directory path works — `:Mindir` accepts the same paths as `:edit`:

```vim
" jump straight to vim config
nnoremap <Leader>v :Mindir ~/.vim<CR>

" browse parent of current file's directory
nnoremap <Leader>u :Mindir %:p:h:h<CR>
```

## Options

| Variable | Values | Default |
|---|---|---|
| `g:mindir_dots` | `0` / `1` — show dotfiles on startup | `0` |
| `g:mindir_keys` | `{}` — action-to-key overrides (see above) | `{}` |
| `g:mindir_replace_netrw` | `0` / `1` — disable netrw, open directories with mindir | `0` |

## Migrating from the buffer-based version

If you have an `after/ftplugin/mindir.vim` file with key remappings, it is no longer needed and can be removed. Use `g:mindir_keys` instead.

## Attribution

Inspired by [ap/vim-readdir](https://github.com/ap/vim-readdir).
Built with [Claude Code](https://claude.ai/code) by Anthropic.
