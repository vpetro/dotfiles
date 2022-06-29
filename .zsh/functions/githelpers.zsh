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
