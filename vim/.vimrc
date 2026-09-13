if &compatible
  set nocompatible
endif
inoremap jk <ESC>
syntax on
colorscheme murphy
filetype on
set nobackup
set novisualbell
set visualbell t_vb=
set ruler
set nu
set rnu
set showcmd
set backspace=indent,eol,start
set scrolloff=3
set hlsearch
set expandtab
set autoindent
set smartindent
set cursorline
set smarttab
set shiftwidth=2
set tabstop=2
set softtabstop=2
" 设置光标样式
if has("gui_running") || has("termguicolors")
  " Normal 模式下的光标样式为实心方块
  set guicursor=n-v-c:block-Cursor
  " 插入模式下的光标样式为竖线
  set guicursor+=i:ver25-Cursor
endif
" Set cursor shape and color
if &term =~ "xterm"
  " INSERT mode
  let &t_SI = "\<Esc>[6 q" . "\<Esc>]12;yellow\x7"
  " REPLACE mode
  let &t_SR = "\<Esc>[2 q" . "\<Esc>]12;yellow\x7"
  " NORMAL mode
  let &t_EI = "\<Esc>[2 q" . "\<Esc>]12;green\x7"
endif
