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

ob() {

  result=$(buku -p -f 40 | fzf | cut -f1)
  open -a /Applications/qutebrowser.app "$result"

}

__docker_pre_test() {
  if [[ -z "$1" ]] && [[ $(docker ps --format '{{.Names}}') ]]; then
    return 0;
  fi

  if [[ ! -z "$1" ]] && [[ $(docker ps -a --format '{{.Names}}') ]]; then
    return 0;
  fi

  echo "No containers found";
  return 1;
}

#docker stop
ds() {
  __docker_pre_test \
    && docker ps --format '{{.Names}}' \
      | fzf -m  \
      | while read -r name; do
          docker update --restart=no $name
          docker stop $name
        done
}

#docker stop all
dsa() {
  __docker_pre_test
  if [ $? -eq 0 ]; then
    docker update --restart=no $(docker ps -q)
    docker stop $(docker ps -q)
  fi
}

pyright_config() {
  jq \
    --null-input \
    --arg venv "$(basename $(poetry env info -p))" \
    --arg venvPath "$(dirname $(poetry env info -p))" \
    '{ "venv": $venv, "venvPath": $venvPath }' \
    > pyrightconfig.json
  }

run_on_save() {
  # use it like this: run_on_save dir_name pytest something
  fswatch -0 -o -r --event=Created $1 |  xargs -0 -n1 -I{} ${@:2}
}

log_interactive_command() {
  local logfile="chat_log_$(date +"%Y%m%d_%H%M%S").log"

    # Create a pseudo-terminal
    zpty start_command "$1"

    # Capture output while preserving interactivity
    zpty -r start_command > >(tee "$logfile")

    # Wait for the command to finish
    zpty -w start_command $'\004'  # Send EOF
    zpty -d start_command
  }

l() {
  interaction_mode="chat"
  model_name="claude-3.5-sonnet"

  logfile=~/.llm/$(date +"%Y-%m-%d").log

  if [[ ! -e $logfile ]]; then
    touch $logfile
  fi

  # llm chat -m claude-3.5-sonnet 2>&1 | tee $logfile
  script $logfile llm $interaction_mode -m $model_name
}

