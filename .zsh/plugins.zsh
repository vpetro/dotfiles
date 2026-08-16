: ${HOMEBREW_PREFIX:=/opt/homebrew}

# -- zsh-vi-mode -----------------------------------------------------------
# Vi-style modal editing in zsh. We queue the fzf keybindings and our own
# bindkeys file into its post-init hook so zvm doesn't clobber them.
zvm_after_init_commands+=('source <(fzf --zsh)')
zvm_after_init_commands+=('source ~/.zsh/bindkeys.zsh')

source ${HOMEBREW_PREFIX}/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh

# -- tab completion --------------------------------------------------------
# No fzf-tab: plain TAB uses zsh's native menu (see completion.zsh:
# `menu select`). Fuzzy file picking lives on the fzf `**<TAB>` trigger and
# CTRL-T, both provided by `source <(fzf --zsh)` queued above.
