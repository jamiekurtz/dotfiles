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
"set t_Co=256
"set background=dark
colors zenburn


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Quickly edit and source .vimrc
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
nmap <leader>ev :e $MYVIMRC
nmap <leader>sv :so $MYVIMRC



"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Ctrl-S to save (like I'm used to)
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
:nmap <c-s> :w<CR>
:imap <c-s> <Esc>:w<CR>a
":imap <c-s> <Esc><c-s>


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Moving around
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" move down actual lines on the screen, not real lines in file
nmap j gj
nmap k gk


