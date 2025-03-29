zmodload zsh/zprof

integer t0=$(date '+%s')  # move this around

fpath=($fpath $HOME/.zsh/functions)
typeset -U fpath

source ~/.zsh/setopt.zsh
source ~/.zsh/colors.zsh
source ~/.zsh/completion.zsh
source ~/.zsh/editor.zsh
# source ~/.zsh/bindkeys.zsh
source ~/.zsh/history.zsh
source ~/.zsh/exports.zsh
source ~/.zsh/aliases.zsh
source ~/.zsh/prompt.zsh
source ~/.zsh/functions.zsh
source ~/.zsh/functions/githelpers.zsh
source ~/.zsh/functions/docker.zsh
source ~/.zsh/functions/google_cloud.zsh
source ~/.zsh/fzf_theme.zsh

source ~/.zsh/plugins.zsh

# notify if startup time is too long
# function {
#     local -i t1 startup
#     t1=$(date '+%s')
#     startup=$(( t1 - t0 ))
#     [[ $startup -gt 1 ]] && print "Hmm, poor shell startup time: $startup"
# }
# unset t0

#[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# add homebrew ruby
if [ -d "/opt/homebrew/opt/ruby/bin" ]; then
  export PATH=/opt/homebrew/opt/ruby/bin:$PATH
  export PATH=`gem environment gemdir`/bin:$PATH
fi

# TODO uncomment this this if you're turning of the vi mode plugin
# eval "$(fzf --zsh)"

alias luamake=/Users/petrov/oss/lua-language-server/3rd/luamake/luamake

eval $(/opt/homebrew/bin/brew shellenv)

# python version management, just like sdkman
eval "$(pyenv init -)"

# load sdkman to manage jdk versions/tools
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# load nvm to manage nodejs versions
# [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"

# enable opam / ocaml setup
[[ ! -r '/Users/petrov/.opam/opam-init/init.zsh' ]] || source '/Users/petrov/.opam/opam-init/init.zsh' > /dev/null 2> /dev/null


# #  add direnv - loading of env vars per project
# # ensure compatibility tmux <-> direnv
# if [ -n "$TMUX" ] && [ -n "$DIRENV_DIR" ]; then
#   # unset env vars starting with DIRENV_
#   unset -m "DIRENV_*"
# fi
# eval "$(direnv hook zsh)"

if [ -n "$TMUX" ]; then
  eval "$(direnv hook zsh)"
fi

# notify if startup time is too long
function {
    local -i t1 startup
    t1=$(date '+%s')
    startup=$(( t1 - t0 ))
    [[ $startup -gt 1 ]] && print "Hmm, poor shell startup time: $startup"
}
unset t0


