# Prompt.
#
# Renders as:  (venv) cwd branch λ
#
# The branch name is color-coded based on git state:
#   %F{240} gray   = clean tree
#   %F{green}      = dirty tree (any staged, unstaged, or untracked changes)
#
# Design notes:
#   - All parts are precomputed in precmd; PROMPT is pure variable expansion,
#     so hitting Enter is free regardless of repo size.
#   - Hand-rolled git prompt instead of vcs_info: the built-in has ~20ms of
#     zsh-level overhead on top of the git calls it makes.
#   - Single `git status --porcelain` call handles staged/unstaged/untracked
#     in one shot (cheaper than 2-3 `git diff` calls, and gets untracked for
#     free).
#   - Outside a git repo, cost is one `git symbolic-ref` that fails fast.
#
# Typical per-prompt cost: ~20ms inside a repo, <5ms outside. If this ever
# gets painful in a giant monorepo, see the async upgrade note at the bottom.

setopt prompt_subst

autoload -Uz add-zsh-hook

typeset -g _venv_prompt=""
typeset -g _git_prompt=""

_update_git_prompt() {
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null) \
        || branch=$(git rev-parse --short HEAD 2>/dev/null) \
        || { _git_prompt=""; return }

    # Any output from `git status --porcelain` means the tree is dirty
    # (covers staged, unstaged, and untracked in one call).
    local branch_color='%F{240}'   # gray = clean
    if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
        branch_color='%F{green}'   # green = dirty
    fi

    _git_prompt="${branch_color}${branch}%f"
}

_update_venv_prompt() {
    if [[ -n $VIRTUAL_ENV ]]; then
        _venv_prompt="(${VIRTUAL_ENV:t}) "
    else
        _venv_prompt=""
    fi
}

_prompt_precmd() {
    _update_git_prompt
    _update_venv_prompt
}
add-zsh-hook precmd _prompt_precmd

PROMPT='${_venv_prompt}%F{130}%2~%f ${_git_prompt} %F{yellow}λ%f '

# Upgrade path if per-prompt cost becomes a problem (huge monorepo, slow FS):
# run _update_git_prompt asynchronously via a background job that writes its
# result to a file and signals the shell with SIGUSR1 to redraw. See:
#   https://github.com/mafredri/zsh-async
#   https://www.zsh.org/mla/users/2017/msg00644.html
