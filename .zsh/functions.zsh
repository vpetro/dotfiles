wmd() {
    watchmedo shell-command --patterns="\*.py;\*.txt" --recursive --command='echo "$1"' .
}

note_to_html() {
    filename=$(basename $1)
    rst2html.py $filename > "${filename%.*}.html"
}

rh() {
    hlint $1 && runhaskell -Wall $1
}

ydl() {
    youtube-dl "$1" && terminal-notifier -title 'youtube-dl' -message 'Download complete.'
}

ydl_files() {
    while read in; do youtube-dl --extract-audio --audio-format "mp3" --audio-quality 0 "$in"; done < $1
}

fco() {
  local tags branches target
  tags=$(
    git tag | awk '{print "\x1b[31;1mtag\x1b[m\t" $1}') || return
  branches=$(
    git branch --all | grep -v HEAD             |
    sed "s/.* //"    | sed "s#remotes/[^/]*/##" |
    sort -u          | awk '{print "\x1b[34;1mbranch\x1b[m\t" $1}') || return
  target=$(
    (echo "$tags"; echo "$branches") |
    fzf-tmux -- --no-hscroll --ansi +m -d "\t" -n 2) || return
  git checkout $(echo "$target" | awk '{print $2}')
}

dkw() {
    if [ $# -eq 0 ]; then
        echo "Syntax: dkw PORT"
        exit 1
    fi
    open http://`docker-machine ip`:$1
}

fs() {
  local session
  session=$(tmux list-sessions -F "#{session_name}" | \
      fzf --query="$1" --select-1 --exit-0) && \
      tmux switch-client -t "$session"
}

use() {
    eval "$(docker-machine env $1)"
}


gcop() {
    local $pr_number
    local $branch_name
    pr_number=$(echo $1 | sed 's/[^0-9]*//g')
    branch_name="pr${pr_number}"

    git fetch origin pull/${pr_number}/head:${branch_name}
    git checkout ${branch_name}
}
