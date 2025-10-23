
autoload -Uz edit-command-line
zle -N edit-command-line

autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
