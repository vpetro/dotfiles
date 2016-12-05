integer t0=$(date '+%s')  # move this around

fpath=($fpath $HOME/.zsh/functions)
typeset -U fpath

source ~/.zsh/setopt.zsh
source ~/.zsh/colors.zsh
source ~/.zsh/completion.zsh
source ~/.zsh/editor.zsh
source ~/.zsh/bindkeys.zsh
source ~/.zsh/history.zsh
source ~/.zsh/exports.zsh
source ~/.zsh/aliases.zsh
source ~/.zsh/prompt.zsh
source ~/.zsh/functions.zsh


# notify if startup time is too long
function {
    local -i t1 startup
    t1=$(date '+%s')
    startup=$(( t1 - t0 ))
    [[ $startup -gt 1 ]] && print "Hmm, poor shell startup time: $startup"
}
unset t0



[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

