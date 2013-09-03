"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Run in vim mode all the time.
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set nocompatible


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Setup Pathogen
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" call pathogen#infect()


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


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Turn on line breaks
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"set lbr


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Color settings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set t_Co=256
set background=dark


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Quickly edit and source .vimrc
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
nmap <leader>ev :e $MYVIMRC
nmap <leader>sv :so $MYVIMRC



"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Moving around
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" move down actual lines on the screen, not real lines in file
nmap j gj
nmap k gk

