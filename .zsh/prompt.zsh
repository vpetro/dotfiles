autoload -U colors && colors
autoload -U promptinit && promptinit
autoload -U zgitinit && zgitinit

fpath=($fpath $HOME/.zsh/functions)

setopt prompt_subst

function current_dir_path {
    CURRENT=$(print -P %2~)
    echo $CURRENT
}

function git_status {
    local branch=$(zgit_branch)
    local prompt=""
    if zgit_inworktree; then
        if zgit_isworktreeclean; then
            prompt="%F{240}${branch}"
        else
            prompt="%{$fg[green]%}${branch}"
        fi
    fi
    echo $prompt
}
export PROMPT='%F{130}$(current_dir_path)%{$reset_color%} $(git_status)%{$reset_color%} %{$fg[yellow]%}λ%{$reset_color%}%{%F{250}%}%{$reset_color%} '

