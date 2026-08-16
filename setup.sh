#!/bin/bash
# Install dotfiles by symlinking everything in this repo into $HOME.
# Safe to re-run; existing symlinks are detected and skipped.

set -e
CUR_DIR="$(cd "$(dirname "$0")" && pwd)"

# Top-level dotfiles that get symlinked in wholesale.
# (.config is NOT in here -- we symlink selected subdirs only, see below,
#  so that apps writing credentials/cache to ~/.config don't pollute the repo.)
TOP_LEVEL=(
    .ghci.conf
    .gitconfig
    .gitignore
    .hammerspoon
    .inputrc
    .ipython
    .mpv
    .qutebrowser
    .tmux.conf
    .zsh
    .zshrc
)

# Curated ~/.config subdirs (anything else in ~/.config stays local & untracked).
CONFIG_SUBDIRS=(alacritty gh ghostty karabiner)

link() {
    local src="$1" dst="$2"
    if [[ ! -e "$src" ]]; then
        echo "  skip (no source)  $dst"
        return
    fi
    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
        echo "  ok                $dst"
        return
    fi
    if [[ -e "$dst" ]]; then
        echo "  EXISTS, not touching: $dst  (remove it by hand if you want the symlink)"
        return
    fi
    ln -s "$src" "$dst"
    echo "  linked            $dst"
}

echo "=== top-level dotfiles ==="
for item in "${TOP_LEVEL[@]}"; do
    link "$CUR_DIR/$item" "$HOME/$item"
done

echo ""
echo "=== .config subdirs ==="
mkdir -p "$HOME/.config"
for sub in "${CONFIG_SUBDIRS[@]}"; do
    link "$CUR_DIR/.config/$sub" "$HOME/.config/$sub"
done

echo ""
echo "=== ~/bin scripts ==="
mkdir -p "$HOME/bin"
for f in "$CUR_DIR"/bin/*; do
    [[ -f "$f" ]] && link "$f" "$HOME/bin/$(basename "$f")"
done

echo ""
echo "=== Alfred workflows ==="
ALFRED_WF="$HOME/Library/Application Support/Alfred/Alfred.alfredpreferences/workflows"
if [[ -d "$ALFRED_WF" ]]; then
    for wf in "$CUR_DIR"/alfred-workflows/*/; do
        [[ -d "$wf" ]] || continue
        name="$(basename "$wf")"
        # Alfred expects each workflow in a dir starting with `user.workflow.<UUID>`.
        # We pick a deterministic UUID-ish name derived from the workflow's basename
        # so re-running this script is idempotent.
        dst_name="user.workflow.dotfiles.$name"
        link "${wf%/}" "$ALFRED_WF/$dst_name"
    done
else
    echo "  skip (Alfred not installed or preferences not initialised)"
fi

echo ""
echo "done."
