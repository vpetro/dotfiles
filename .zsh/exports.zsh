
export KEYTIMEOUT=1
export DISABLE_AUTO_TITLE="true"

export SDKMAN_DIR="$HOME/.sdkman"
export PYENV_ROOT="$HOME/.pyenv"

export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:$PATH
export PATH=/usr/X11/bin:$PATH
export PATH=/usr/local/sbin:/usr/local/bin:$PATH
export PATH=$HOME/.cabal/bin:$PATH
export PATH=/usr/local/texlive/2016basic/bin/x86_64-darwin:$PATH
#export PATH=/usr/local/opt/python@2/libexec/bin:$PATH
# pyenv bin
export PATH=$PYENV_ROOT/bin:$PATH
export PATH=$HOME/.local/bin:$PATH
# rust cargo bin
export PATH=$HOME/.cargo/bin:$PATH
export PATH="/Users/petrov/Library/Application Support/Coursier/bin:$PATH"
export PATH="/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/bin/:$PATH"
export PATH=$HOME/bin:$PATH



export GIT_EDITOR="nvim"
export EDITOR="nvim"
export VISUAL=$EDITOR

export WORKON_HOME=~/envs
export NOTES_DIR=~/notes

export FZF_DEFAULT_COMMAND='rg --files --smart-case --hidden --no-ignore --no-follow --glob "!.git/*"'

export HOMEBREW_CASK_OPTS="--no-quarantine"

export USE_GKE_GCLOUD_AUTH_PLUGIN=True

export NVM_DIR="$HOME/.nvm"

# completion for google cloud cli
# source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc
# source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc
#
export UV_KEYRING_PROVIDER=subprocess

