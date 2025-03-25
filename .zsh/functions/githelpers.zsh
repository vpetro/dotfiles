git_download_pr() {
    local $pr_number
    local $branch_name
    pr_number=$(echo $1 | sed 's/[^0-9]*//g')
    branch_name="pr${pr_number}"
    git fetch origin pull/${pr_number}/head:${branch_name}
    git checkout ${branch_name}
}

git_list_files_in_pr() {
    upstream_branch=$1
    current_branch=$(git current-branch)
    files=("${(@f)$(git diff ${upstream_branch}...${current_branch} --name-only --pretty='')}")
    for f in $files; do
        count=$(git rev-list ${upstream_branch}...${current_branch} --count -- $f)
        echo $count $f
    done | sort -n

}

git_review_file() {
    upstream_branch=$1
    current_branch=$(git current-branch)
    git difftool ${upstream_branch}...${current_branch} -- $(pbpaste)
}

git_most_changed_files() {
    files=("${(@f)$(git ls-files)}")
    for f in $files; do
        count=$(git rev-list HEAD --count -- $f)
        echo $count $f
    done | sort -n | tail -n 20
}

# this either needs to get fixed or just remove it in favour of the other thing
# git_checkout_branch() {
#   local branches branch
#   branches=$(git branch -vv) &&
#   branch=$(echo "$branches" | fzf +m) &&
#   git checkout $(echo "$branch" | awk '{print $1}' | sed "s/.* //")
# }

git_changed_files() {
  local branch
  current_branch=$(git rev-parse --abbrev-ref HEAD)
  merge_base=$(git merge-base "$current_branch" main)
  files=$(git diff --name-only "$current_branch" "$merge_base")
  echo "$files"
}

fzf-git-branch() {
    git rev-parse HEAD > /dev/null 2>&1 || return

    git branch --color=always --all --sort=-committerdate |
        grep -v HEAD |
        fzf --height 50% --ansi --no-multi --preview-window right:65% \
            --preview 'git log -n 50 --color=always --date=short --pretty="format:%C(auto)%cd %h%d %s" $(sed "s/.* //" <<< {})' |
        sed "s/.* //"
}

gpc() {
    git rev-parse HEAD > /dev/null 2>&1 || return

    local branch

    branch=$(fzf-git-branch)
    if [[ "$branch" = "" ]]; then
        echo "No branch selected."
        return
    fi

    # If branch name starts with 'remotes/' then it is a remote branch. By
    # using --track and a remote branch name, it is the same as:
    # git checkout -b branchName --track origin/branchName
    if [[ "$branch" = 'remotes/'* ]]; then
        git checkout --track $branch
    else
        git checkout $branch;
    fi
}

ghp () {
  remote=$(git remote -v | grep fetch | awk '{print $2}')
  url=$(echo "$remote" | sed 's/git@github.com:/https:\/\/github.com\//' | sed 's/\.git$//')
  open $url
}
