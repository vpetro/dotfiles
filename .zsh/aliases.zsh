# basic

alias ls="ls -G"

# shorter commands
alias -g G="| egrep -i"
alias -g L="| less"
alias -g H="| head"
alias -g T="| tail"

alias -g FC="$(docker ps --format '{{.Names}}')"

# git
alias gc="git commit -v -S"
alias gp="git push"
alias gs="git st"
alias gd="git diff"
alias gdc="git diff --cached"
alias gau="git au"
alias gsl="git sl"
alias gsh="git stash"
alias gco="git checkout"
alias gl="git pull"
alias gap="git add -p"
alias ga='git add'
alias gu='git pull origin `git current-branch`'
alias gm="git merge"

# python
alias ipy="ipython --no-confirm-exit --profile=petro"
#alias python="/usr/local/bin/python3"

# scala
alias scala-desugar="scala -Xprint:typer"

alias cp=cp

# neovim
alias v='nvim'

# vlc
alias radio='mpv --volume=90 --mute=no https://somafm.com/defcon.pls'
#alias radio2="mpv --volume=90 --mute=no 'https://www.yutube.com/watch?v=cXzYWEFib4M'"
alias radio2="mpv --volume=90 --mute=no --no-video 'https://www.youtube.com/watch?v=jfKfPfyJRdk'"
# good for playing something from youtube
alias listen='mpv --no-video --volume=90 --mute=no'

# docker
alias dk="docker"

alias em='exercism'

alias ldl="cd ~/Downloads && find . -type f -maxdepth 1 -print0 | xargs -0 stat -f \"%c %N\" | sort -n | cut -f 2- -d' ' | tail -n1 | sed 's/.*/\"&\"/' | xargs open"

alias who-is-listening='sudo lsof -iTCP -sTCP:LISTEN -n -P'

# latex
alias lx="latex-mk -pdf -pvc"

# chrome
alias chrome="open -a /Applications/Chromium.app"

# android
alias adb="/Users/petrov/Library/Android/sdk/platform-tools/adb"
alias fastboot="/Users/petrov/Library/Android/sdk/platform-tools/fastboot"

# from https://apple.stackexchange.com/questions/170105/list-usb-devices-on-osx-command-line
alias lsusb="ioreg -p IOUSB -w0 | sed 's/[^o]*o //; s/@.*$//' | grep -v '^Root.*'"

alias tma="tmux attach -t"
alias tmc="tmux new-session -s"
alias tm="tmux"

alias ge="sh gradlew"

alias kb="kubectl"

alias pe="poetry"

alias gcl="gcloud"
