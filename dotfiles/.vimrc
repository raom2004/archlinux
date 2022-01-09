syntax on
" colorscheme torte
set tabstop=4
set softtabstop=4
set expandtab
set number
set showcmd
" set cursorline
filetype indent on
set wildmenu
set lazyredraw
set showmatch
set incsearch
set hlsearch
nnoremap <leader><space> :nohsearch<CR>
set nofoldenable
" set foldenablestart=10
nnoremap <space> za
set foldmethod=indent

" Plugins will be downloaded under the specified directory.

call plug#begin('~/.vim/plugged')

" Declare list of plugins.
Plug 'jcherven/jummidark.vim'

" Unmanaged plugin (manually installed and updated)
" Plug '~/my-prototype-plugin'

" List ends here. Plugins become visible to Vim after this call
call plug#end()

syntax enable
colorscheme jummidark
