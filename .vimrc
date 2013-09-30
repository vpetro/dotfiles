" Petro Verkhogliad <vpetro@gmail.com>
" last modification: 2013-09-04

filetype off
call pathogen#infect()
filetype on
set t_Co=256

" compatibility {
set nocompatible
set hidden
set nolazyredraw
set ttyfast
" }

" indenting {
set autoindent
set smartindent
set tabstop=4
set shiftwidth=4
set expandtab
filetype indent on
set list listchars=tab:»·,trail:·,extends:·,precedes:·,
highlight SpecialKey ctermfg=235
"
" }

" scrolling {
set nowrap
set scrolloff=4
nnoremap <C-e> 3<C-e>
nnoremap <C-y> 3<C-y>
" }

" searching {
set ignorecase
set smartcase
set incsearch
set hlsearch
nmap <silent> <C-n> :noh<CR>
nmap n nzz
nmap N Nzz

nmap * *zz
nmap # #zz
nmap g* g*zz
nmap g# g#zz

" searching with TheSilverSearcher and Ag.vim
command -nargs=1 AgPythonFiles :Ag! "<args>" **/*.py
command -nargs=1 AgConfFiles :Ag! "<args>" **/*.conf
command -nargs=1 AgJsonFiles :Ag! "<args>" **/*.json

nmap <leader>ap :AgPythonFiles <cword><cr>
nmap <leader>aa :Ag!
" }

" misc {
filetype plugin on
syntax on

set showmatch
set previewheight=20
set backspace=2
set whichwrap+=<,>,h,l
set iskeyword=~,@,48-57,_,192-255
set history=1000

set suffixes=.bak,~,.swp,.o,.info,.aux,.log,.dvi,.bbl,.blg,.brf,.cb,.ind,.idx,.ilg,.inx,.out,.toc,.cmi,.cmo,.cmx,.cmxa,.exe,.ho,.hi,.bc,.out,.annot,.spot
set wildmenu
"set wildmode=list:longest
set wildignore+=*/.hg/*,*/.svn/*,*/bin/*,*/images/*
set wildignore+=*.dll,*.exe
set wildignore+=*.o,*.obj,*.class,*.pyc,*.log,*.pidb,*.jar,*.class
set wildignore+=*.aux,*.bbl,*.blg,*.fdb_latexmk,*.bst,*.pdf,*.png,*.jpg,*.gif
set wildignore+=*.json,*.bson

" dont show the line numbers or relative numbers
set nonumber
set norelativenumber
set ruler

" set to auto read when a file is changed from the outside
set autoread

" save the file when vim loses focus. useful.
au FocusLost * :wa

" set the the dir where to store the swap files.
set noswapfile nowritebackup nobackup
"set dir=/Users/petrov/.tmp

" set encoding
set enc=utf-8
set fileformats=unix,dos,mac

" Enable fancy % matching
if has("eval")
    runtime! macros/matchit.vim
endif
" }

" error bell and status line {
set noerrorbells
set novisualbell
set visualbell t_vb=
set laststatus=2
set statusline=%<%f\ %h%w%m%r%y%=L:%l/%L\ G:%{fugitive#statusline()}
" }

" set up leaders {
let mapleader = ","
let g:mapleader = ","
let localleader ="\\"
let maplocalleader = "\\"
" }

" set colorscheme and colorcolumn {
set background=dark
colorscheme petro
set colorcolumn=79
" }

" normal mode mappings for all {
nmap <leader>m :make<CR>
nmap <leader>sp :setlocal spell! spelllang=en<CR>
noremap W :w<cr>

" faster quiting and saving
nmap <leader>q :q!<cr>
nmap <leader>w :w!<cr>
nmap <leader>f :find<cr>

" make the current vertical split wider
nmap <leader>b :exe "normal " . (winwidth(0)*3/2) . "\<C-W>|"
" Pull word under cursor into LHS of a substitute
nmap <leader>z :%s#\<<c-r>=expand("<cword>")<cr>\>#
" increase the vertical size of the current window by 1.5 times.
nmap <leader>b :exe "vertical resize" (winwidth(0)*3/2)
" reload all snipmate snippets
nmap <leader>rr :call ReloadAllSnippets()<cr>
" run rsync
nmap <space>rr :execute ":!rsr pg"<cr>
" }

" insert mappings for all {
" remap the escape, it is tiny on the macbook keyboard and i miss the ctrl-[ key
ino jj <esc>
cno jj <C-c>
imap \d :execute ":r!date \"+%Y-%m-%d\"<cr>
" }

" quickfix {
nmap <leader>co :botright cwindow<cr>
nmap <leader>cq :cclose<cr>
nmap <leader>cn :cnext<cr>
nmap <leader>cl :clast<cr>
nmap <leader>cp :cprevious<cr>
" }

" fugitive mappings {
nmap <leader>gs :Gstatus<cr>
nmap <leader>gu :Gwrite<cr>
nmap <leader>gg :Gcommit -v<cr>
nmap <leader>gb :Gblame<cr>
nmap <leader>gl :Git log
nmap <leader>gd :Gdiff<cr>
" }

" completion {
autocmd FileType javascript set omnifunc=javascriptcomplete#CompleteJS
autocmd FileType html set omnifunc=htmlcomplete#CompleteTags
autocmd FileType c set omnifunc=ccomplete#Complete

" dont display pydoc window
set completeopt=longest,menuone
set completeopt-=preview

" limit the popup menu height to 15
set pumheight=15

" }

" NERDCommenter {
let NERDShutUp=1
" }

" ctrlp {
let g:ctrlp_match_window_reversed = 0
let g:ctrlp_max_height = 10
let g:ctrlp_working_path_mode = 0
let g:ctrlp_dotfiles = 0
let g:ctrlp_extensions = ['line']

map <leader>t :CtrlP<cr>
map <space>t :CtrlPTag<cr>
nmap <space>ct :CtrlPTag<cr><C-\>r/

let g:ctrlp_custom_ignore = {
  \ 'dir':  '\v[\/]\.(git|hg|svn)$',
  \ 'file': '\v\.(exe|so|dll)$',
  \ 'link': 'some_bad_symbolic_links',
  \ }

" }

" easier split movement {

nmap <space>j <C-w>j
nmap <space>k <C-w>k
nmap <space>h <C-w>h
nmap <space>l <C-w>l

" }

 "html {
augroup html
    autocmd!
    autocmd FileType html,xhtml,xml,htmldjango,htmljinja,mako setlocal expandtab shiftwidth=2 tabstop=2 softtabstop=2
augroup END
" }

" xml {
augroup ft_xml
    au!
    au FileType xml nmap <leader>x :execute "!tidy -m -xml -i -utf8 " . expand("%:p")
augroup END
" }

" clojure {
augroup clojure
    au!
    au BufRead,BufNewFile *.clj set ft=clojure
augroup END
" }

augroup json
    au!
    au BufRead,BufNewFile *.json set ft=javascript
augroup END

" latex {
augroup ft_tex
    " format paragraph quickly
    au!
    au BufRead *.tex set ft=tex
    au FileType tex nmap <leader>f vipgq
    au BufEnter *.tex :source ~/.vim/abbreviations
augroup END
" }

" haskell {
augroup haskell
    autocmd!
    au FileType haskell nnoremap <buffer> <leader>ht :HdevtoolsType<CR>
    au FileType haskell nnoremap <buffer> <silent> <leader>hc :HdevtoolsClear<CR>
    " map <leader>r to reload the current module in ghci that is running in
    " the other pane
    au FileType haskell nmap <leader>r :call Send_to_Tmux(':load ' . expand('%:b') . " \n")
augroup end
" }

" python {
augroup ft_python
    au!

    " write the parameters for a given function
    au FileType python nmap <leader>wp :call WriteParams()<cr>

    "au FileType python set foldmethod=indent
    au FileType python set omnifunc=pythoncomplete#Complete
    au FileType python set nosmartindent
    au FileType python set makeprg=pylint-2.6\ --reports=n\ --output-format=parseable\ %:p
    au FileType python set errorformat=%f:%l:\ %m
    au BufWritePost *.py call Flake8()

    " map <leader>r to run nosetests on the current file in another tmux pane
    nmap \te :execute "vertical rightb split " . GetPathToTestFile()<cr>
    nmap \t :execute RunTest()<cr>
    let g:flake8_ignore = "W801,E128,W806"
augroup END
" }

" restructured text {
augroup ft_rest
    au!
    au Filetype rst nnoremap <buffer> <leader>1 yypVr=
    au Filetype rst nnoremap <buffer> <leader>2 yypVr-
    au Filetype rst nnoremap <buffer> <leader>3 yypVr~
    au Filetype rst nnoremap <buffer> <leader>4 yypVr`
augroup END
" }

" vim {
augroup ft_vim
    au!
    au FileType vim set foldmethod=marker
    au FileType vim set foldmarker={,}
augroup END
" }

" misc gui hacks {
nmap <leader>rp :RainbowParenthesesToggle
set foldtext=CustomFoldText()

autocmd FileType qf wincmd J
" }

" functions {
function! ConvertRstToHtml()
    :!/opt/local/bin/rst2html-2.6.py --stylesheet-path=/Users/petrov/blog/style/lsr.css <afile> <afile>:p:r.html && python /Users/petrov/.rst/insert_jsmath.py <afile>:p:r.html
endfunction

" test function for running the file
function! GetPathToTestFile()
    let test_prefix = "test_"
    let current_dir = getcwd()
    let test_path = current_dir . "/Tests/" . expand("%:h") . "/test_" . expand("%:t")
    return test_path
endf

function! RunTest()
    let module_path = substitute(expand("%"), getcwd(), "", "g")
    let module_path = substitute(module_path, "/", ".", "g")
    let module_path = substitute(module_path, ".py", "", "g")
    let nose_command = "!nosetests --with-coverage --cover-erase --cover-package=" . module_path . " "

    let test_prefix = "test_"
    let filename = expand("%:t")
    let filename_prefix = strpart(filename, 0,5)
    if filename_prefix == test_prefix
        return nose_command . expand("%")
    endif
    let test_file_path = GetPathToTestFile()
    return nose_command . test_file_path
endf

function! WriteParams()
python << endpython
import re
import vim

# get the function definition line
line = vim.eval("getline(line('.'))")
# get the number of spaces to add to the start of the line
num_spaces = 4 + len(line) - len(line.lstrip())
# get the line number wher to do the insertion
line_number = int(vim.eval("line('.')"))

# find the parameter names in the function definition
params = re.findall("[\w=]+", line)[2:]

# the header and the footer of the doctstring
lines = ['"""', ""]

for param in params:
    # skip the 'self' since it doesn't have to be documented.
    if param == "self":
        continue
    # handle the default argument parameters
    if "=" in param:
        param_name = param.split('=')[0]
        param_default_value = "".join(param.split('=')[1:])
        lines.append(":param %s: (Default value: %s)" % (param_name, param_default_value))
        lines.append(":type %s:" % param_name)
    else:
        lines.append(":param %s:" % param)
        lines.append(":type %s:" % param)

lines.append(":returns:")
lines.append('"""')
# insert the contents of the list into the buffer
vim.current.buffer[:] = vim.current.buffer[:line_number] + [(" "*num_spaces)+line for line in lines] + vim.current.buffer[line_number:] 
endpython
endfunction

fu! CustomFoldText()
    "get first non-blank line
    let fs = v:foldstart
    while getline(fs) =~ '^\s*$' | let fs = nextnonblank(fs + 1)
    endwhile
    if fs > v:foldend
        let line = getline(v:foldstart)
    else
        let line = substitute(getline(fs), '\t', repeat(' ', &tabstop), 'g')
    endif

    let w = winwidth(0) - &foldcolumn - (&number ? 8 : 0)
    let foldSize = 1 + v:foldend - v:foldstart
    let foldSizeStr = " " . foldSize . " lines "
    let foldLevelStr = repeat("+--", v:foldlevel)
    let lineCount = line("$")
    let foldPercentage = printf("[%.1f", (foldSize*1.0)/lineCount*100) . "%] "
    let expansionString = repeat(".", w - strwidth(foldSizeStr.line.foldLevelStr.foldPercentage))
    return line . expansionString . foldSizeStr . foldPercentage . foldLevelStr
endf
" }

" close the quickfix window if it it is the only remaining open window
autocmd BufEnter * if (winnr('$') == 1 && &ft ==# 'qf') | q | en

" convert json date to python datetime
function! ConvertJsonDate()
python << EOF
def _convert_json_date():
    import vim
    from datetime import datetime
    json_date = int(vim.eval("expand(\"<cword>\")"))
    return datetime.fromtimestamp(json_date / 1000.0)
print _convert_json_date()
EOF
endfunction

nmap \fd :call ConvertJsonDate()<cr>
nmap \v :source ~/.vimrc<cr>
