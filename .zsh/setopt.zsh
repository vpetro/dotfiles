# command correction
unsetopt correct
unsetopt correct_all

setopt autocd
setopt histignorespace

# Dedupe PATH (and fpath) automatically. Without this, repeated shell initialization
# (or sourcing ~/.zshrc) silently accumulates duplicate entries.
typeset -U path PATH
typeset -U fpath FPATH
