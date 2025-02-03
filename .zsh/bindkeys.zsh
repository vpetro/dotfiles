
bindkey -v
bindkey '\e[3~' delete-char
bindkey -M vicmd v edit-command-line
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end
bindkey "^A" beginning-of-line
bindkey "^E" end-of-line
bindkey "^F" forward-char
bindkey "^B" backward-char
bindkey "^T" forward-word
bindkey "^V" backward-word

autoload -U select-word-style
select-word-style bash
# bindkey "^R" history-incremental-search-backward
