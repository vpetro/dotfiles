# basic

# shorter commands
alias -g G="| egrep -i"
alias -g L="| less"
alias -g H="| head"
alias -g T="| tail"

# git
alias gc="git commit -v"
alias gp="git push"
alias gs="git st"
alias gd="git diff"
alias gau="git au"
alias gsl="git sl"
alias gsh="git stash"
alias gco="git checkout"
alias gl="git pull"
alias gap="git add -p"
alias ga='git add'
alias gu='git pull origin `git current-branch`'

# python
alias ipy="ipython --no-confirm-exit --profile=petro"

# scala
alias ss='/Users/petrov/bin/sbt'
alias ts="tree src/main/scala"
alias sst="sbt \~test"
alias ssc="sbt \~compile"
alias scala-desugar="scala -Xprint:typer"

alias cp=cp

# ssh
alias st="ssh -L 13013:localhost:13013"
alias ssh="ssh"

# silver searcher
alias ag='ag --smart-case --hidden'

# neovim
alias v='nvim'

# vlc
alias vlc='/Applications/VLC.app/Contents/MacOS/VLC'
alias cvlc='/Applications/VLC.app/Contents/MacOS/VLC -I rc'
alias radio='/Applications/VLC.app/Contents/MacOS/VLC https://somafm.com/defcon.pls'

# surfraw
alias srg="sr google"

# vagrant
alias vm='vagrant'

# docker
alias dk="docker"
alias dkm="docker-machine"

alias em='exercism'

alias ldl="cd ~/Downloads && find . -type f -maxdepth 1 -print0 | xargs -0 stat -f \"%c %N\" | sort -n | cut -f 2- -d' ' | tail -n1 | sed 's/.*/\"&\"/' | xargs open"

alias -s pdf="acroread"

alias who-is-listening='sudo lsof -iTCP -sTCP:LISTEN -n -P'

# latex
alias lx="latex-mk -pdf -pvc"

# chrome
alias chrome="open -a /usr/local/Caskroom/google-chrome/latest/Google\ Chrome.app"

# android
alias adb="/Users/petrov/Library/Android/sdk/platform-tools/adb"
alias fastboot="/Users/petrov/Library/Android/sdk/platform-tools/fastboot"

# from https://apple.stackexchange.com/questions/170105/list-usb-devices-on-osx-command-line
alias lsusb="ioreg -p IOUSB -w0 | sed 's/[^o]*o //; s/@.*$//' | grep -v '^Root.*'"
