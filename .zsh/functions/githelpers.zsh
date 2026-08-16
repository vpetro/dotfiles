# NOTE: PR checkout is `gcop` in functions.zsh (same purpose).

# List files changed in the current branch relative to <upstream>, sorted by
# number of commits that touched each file (ascending).
git_list_files_in_pr() {
    local upstream_branch=$1
    local current_branch
    current_branch=$(git current-branch)
    local files=("${(@f)$(git diff ${upstream_branch}...${current_branch} --name-only --pretty='')}")
    for f in $files; do
        local count
        count=$(git rev-list ${upstream_branch}...${current_branch} --count -- $f)
        echo $count $f
    done | sort -n
}

# Open a difftool for the file whose name is in the clipboard.
git_review_file() {
    local upstream_branch=$1
    local current_branch
    current_branch=$(git current-branch)
    git difftool ${upstream_branch}...${current_branch} -- $(pbpaste)
}

# Top 20 most-changed files in the repo (across all history).
git_most_changed_files() {
    local files=("${(@f)$(git ls-files)}")
    for f in $files; do
        local count
        count=$(git rev-list HEAD --count -- $f)
        echo $count $f
    done | sort -n | tail -n 20
}

# Files changed between current branch and its merge-base with main.
git_changed_files() {
    local current_branch merge_base
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    merge_base=$(git merge-base "$current_branch" main)
    git diff --name-only "$current_branch" "$merge_base"
}

# fzf picker over all branches (local + remote), with commit preview.
fzf-git-branch() {
    git rev-parse HEAD > /dev/null 2>&1 || return

    git branch --color=always --all --sort=-committerdate \
        | grep -v HEAD \
        | fzf --height 50% --ansi --no-multi --preview-window right:65% \
              --preview 'git log -n 50 --color=always --date=short --pretty="format:%C(auto)%cd %h%d %s" $(sed "s/.* //" <<< {})' \
        | sed "s/.* //"
}

# git-pick-checkout: fzf-select a branch and check it out, handling remotes.
gpc() {
    git rev-parse HEAD > /dev/null 2>&1 || return

    local branch
    branch=$(fzf-git-branch)
    if [[ -z "$branch" ]]; then
        echo "No branch selected."
        return
    fi

    # Remote branch: use --track so we get a local branch with upstream set.
    if [[ "$branch" = 'remotes/'* ]]; then
        git checkout --track "$branch"
    else
        git checkout "$branch"
    fi
}

# Open the current repo's GitHub page in the browser.
ghp() {
    local remote url
    remote=$(git remote -v | grep fetch | awk '{print $2}')
    url=$(echo "$remote" | sed 's/git@github.com:/https:\/\/github.com\//' | sed 's/\.git$//')
    open "$url"
}
