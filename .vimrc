
set clipboard=unnamed
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Run in vim mode all the time.
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set nocompatible


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Basic editor settings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set hidden         " hide buffers, instead of closing them

syntax on                    " turn on syntax highlighting
filetype plugin indent on    " detect filetype and use indent rules

set history=10000
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4

set autoindent
set laststatus=2
set ruler             " show cursor position
set showmatch
set number            " show line numbers
set shell=bash
set showcmd
set cursorline
let mapleader=","
set backspace=indent,eol,start


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Search
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set hlsearch       " highlight matching search results
set incsearch      " use incremental search
set ignorecase     " ignore case when searching...
set smartcase      " ...unless caps were explicitly used in search


" http://vim.wikia.com/wiki/Word_wrap_without_line_breaks
set wrap
set linebreak
set nolist  " list disables linebreak
set textwidth=0
set wrapmargin=0
set formatoptions+=l



"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Backup and swap file locations
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set directory=~/.backup//
set backupdir=~/.backup//



"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Color settings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set t_Co=256
colors zenburn
hi Normal ctermfg=none ctermbg=none
hi CursorLine ctermfg=none ctermbg=none


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Quickly edit and source .vimrc
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
nmap <leader>ev :e $MYVIMRC
nmap <leader>sv :so $MYVIMRC



"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Ctrl-S to save (like I'm used to)
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
nmap <c-s> :w<cr>
imap <c-s> <esc>:w<cr>a
" Also need to put the following in .bashrc in order to allow c-s to be passed
" through to VIM:  bind -r '\C-s'; stty -ixon


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Pathogen :)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" execute pathogen#infect()
filetype off                    " force reloading *after* pathogen loaded
call pathogen#helptags()
call pathogen#infect()
filetype plugin indent on       " enable detection, plugins and indenting in one step


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Explore settings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:netrw_preview   = 1
let g:netrw_liststyle = 3
let g:netrw_winsize   = 30
nnoremap <F5> :buffers<CR>:buffer<Space>
autocmd vimenter * if !argc() | NERDTree | endif
"autocmd VimEnter * wincmd p
nnoremap <F2> <c-w><c-w>
map <F6> :NERDTreeToggle<CR>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Moving around
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" move down actual lines on the screen, not real lines in file
nmap j gj
nmap k gk
set whichwrap+=<,>,h,l,[,]

augroup vimrcEx
  autocmd!

  " Set syntax highlighting for specific file types
  autocmd BufRead,BufNewFile *.md set filetype=markdown

  " Enable spellchecking for Markdown
  autocmd FileType markdown setlocal spell spelllang=en_us

  " Automatically wrap at 72 characters and spell check git commit messages
  "autocmd FileType gitcommit setlocal textwidth=72
  " autocmd FileType gitcommit setlocal spell spellang=en_us

augroup END
