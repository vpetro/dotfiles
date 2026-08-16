# basic
alias ls="ls -G"
alias rls="ls"
alias eixt="exit"

# shorter commands (global aliases: expand anywhere on the command line)
alias -g G="| egrep -i"
alias -g L="| less"
alias -g H="| head"
alias -g T="| tail"

# Single-quoted so the subshell runs each time FC is expanded, not at shell
# startup (which was costing ~75ms and also captured a stale container list).
alias -g FC='$(docker ps --format "{{.Names}}")'

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

# neovim
alias v='nvim'

# mpv: online radio streams and generic "listen to a URL"
alias radio='mpv --volume=90 --mute=no https://somafm.com/defcon.pls'
alias radio2="mpv --volume=90 --mute=no --no-video 'https://www.youtube.com/watch?v=jfKfPfyJRdk'"
alias radio3="mpv --volume=90 --mute=no --no-video 'https://www.youtube.com/watch?v=4xDzrJKXOOY'"
alias listen='mpv --no-video --volume=90 --mute=no'

# docker / kubernetes / gcloud shortcuts
alias dk="docker"
alias kb="kubectl"
alias gcl="gcloud"

# macOS-specific
alias chrome="open -a /Applications/Chromium.app"
alias who-is-listening='sudo lsof -iTCP -sTCP:LISTEN -n -P'
# List USB devices (adapted from https://apple.stackexchange.com/a/170128)
alias lsusb="ioreg -p IOUSB -w0 | sed 's/[^o]*o //; s/@.*$//' | grep -v '^Root.*'"

# tmux
alias tma="tmux attach -t"
alias tmc="tmux new-session -s"
alias tm="tmux"
