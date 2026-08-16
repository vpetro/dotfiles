# Shell behavior
export KEYTIMEOUT=1           # vi-mode: faster ESC response
export DISABLE_AUTO_TITLE=true # don't let oh-my-zsh-style plugins retitle the tab

# Editors (everything points at nvim)
export EDITOR="nvim"
export VISUAL="$EDITOR"
export GIT_EDITOR="$EDITOR"
export JIRA_EDITOR="$EDITOR"

# Notes directory (used by personal note-taking tools)
export NOTES_DIR=~/notes

# fzf: use ripgrep for file search; include hidden, skip .git
export FZF_DEFAULT_COMMAND='rg --files --smart-case --hidden --no-ignore --no-follow --glob "!.git/*"'

# Homebrew: skip Gatekeeper quarantine prompt on every cask install
export HOMEBREW_CASK_OPTS="--no-quarantine"

# GKE auth helper required for kubectl against GKE clusters
export USE_GKE_GCLOUD_AUTH_PLUGIN=True

# uv: use subprocess keyring provider (works with private package indexes)
export UV_KEYRING_PROVIDER=subprocess

# Virtualenv: our prompt renders the venv; prevent `activate` scripts from also
# prefixing `(venv)` to PS1.
export VIRTUAL_ENV_DISABLE_PROMPT=1

# Tell self-updating tools (Claude Code, etc.) to stay put.
export DISABLE_AUTOUPDATER=1

# Yubikey PIN keychain entry label
export KEYCHAIN_YUBIPIN_ENTRY="yubikey PIN"

# Have to export this because of colima
export DOCKER_HOST="unix:///Users/pverkhogliad/.colima/default/docker.sock"

export GH_HOST="github.com"

# PATH additions not already provided by /etc/paths / /etc/paths.d / brew.
# `typeset -U path` (set in setopt.zsh) dedupes automatically, so these are
# safe to add even if something else also adds them.
path=(
    "$HOME/.bin"
    "$HOME/.cargo/bin"
    "$HOME/.rd/bin"
    /opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/bin
    $path
)

