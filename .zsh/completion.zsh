# setup the cache dir
[[ -d ~/.zsh/cache/$HOST ]] || mkdir -p ~/.zsh/cache/$HOST

# Guarded: fpath only gets the path if the directory actually exists.
# Old value (/usr/local/share/zsh-completions) was an Intel-homebrew path
# and also zsh-completions wasn't installed anyway.
[[ -d ${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh-completions ]] && \
    fpath=(${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh-completions $fpath)

# Enable completion caching, use rehash to clear
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path ~/.zsh/cache/$HOST

# Fallback to built in ls colors
zstyle ':completion:*' list-colors 'di=34:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'

# Make the selection prompt friendly when there are a lot of choices
zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'

# list of completers to use
zstyle ':completion:*::::' completer _expand _complete _ignored _approximate

# Native zsh menu on TAB: highlight the first match, then arrow/TAB through.
zstyle ':completion:*' menu select

# Keep git-checkout in committer-date order rather than alphabetical.
zstyle ':completion:*:git-checkout:*' sort false

# match uppercase from lowercase
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
