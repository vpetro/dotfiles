# ---------------------------------------------------------------------------
# tmux
# ---------------------------------------------------------------------------

# Switch to a tmux session via fzf.
fs() {
    local session
    session=$(tmux list-sessions -F "#{session_name}" |
        fzf --query="$1" --select-1 --exit-0) && \
        tmux switch-client -t "$session"
}

# ---------------------------------------------------------------------------
# docker
# ---------------------------------------------------------------------------

# Guard: the caller wants to operate on containers; verify some exist.
# Arg: if non-empty, consider stopped containers too.
__docker_pre_test() {
    if [[ -z "$1" ]] && [[ $(docker ps --format '{{.Names}}') ]]; then
        return 0
    fi
    if [[ -n "$1" ]] && [[ $(docker ps -a --format '{{.Names}}') ]]; then
        return 0
    fi
    echo "No containers found"
    return 1
}

# docker stop (interactive: pick containers via fzf)
ds() {
    __docker_pre_test \
        && docker ps --format '{{.Names}}' \
            | fzf -m \
            | while read -r name; do
                docker update --restart=no "$name"
                docker stop "$name"
              done
}

# docker stop all running containers
dsa() {
    __docker_pre_test || return
    docker update --restart=no $(docker ps -q)
    docker stop $(docker ps -q)
}

# ---------------------------------------------------------------------------
# git (repo-level helpers)
# ---------------------------------------------------------------------------

# Check out a PR by number (e.g. `gcop 123` or `gcop #123`).
gcop() {
    local pr_number branch_name
    pr_number=$(echo "$1" | sed 's/[^0-9]*//g')
    branch_name="pr${pr_number}"

    git fetch origin "pull/${pr_number}/head:${branch_name}"
    git checkout "${branch_name}"
}

# ---------------------------------------------------------------------------
# kubernetes
# ---------------------------------------------------------------------------

# Pick a pod via fzf, then tail its logs. Extra args are passed to both
# kubectl calls (useful for -n <namespace>).
kl() {
    local pod
    pod=$(kubectl get pods --no-headers -o custom-columns=':metadata.name' "$@" \
        | fzf --height=40% --reverse) || return
    kubectl logs -f "$pod" "$@"
}

# ---------------------------------------------------------------------------
# bookmarks (buku) -- open a bookmark selected via fzf in qutebrowser
# ---------------------------------------------------------------------------

ob() {
    local result
    result=$(buku -p -f 40 | fzf | cut -f1)
    open -a /Applications/qutebrowser.app "$result"
}

# ---------------------------------------------------------------------------
# YouTube: transcript + summary via fabric
# ---------------------------------------------------------------------------

# Shared: download a YouTube URL's subtitles, strip timing/markup, leave a
# single-line transcript at /var/tmp/output.txt. Prints the path on success.
#
# We download TTML and convert to SRT because YouTube's auto-caption VTT uses
# rolling/overlapping cues that produce massively duplicated text; the TTML
# track is already deduped per cue.
_yt_fetch_transcript() {
    # NULL_GLOB so unmatched cleanup globs disappear instead of erroring out.
    setopt local_options null_glob

    local url="$1"
    if [[ -z "$url" ]]; then
        echo "usage: yt_transcript <youtube-url>" >&2
        return 2
    fi

    local dir="/var/tmp"
    local out="$dir/output.txt"

    # Clean prior run so a failed fetch can't silently reuse stale subtitles.
    rm -f "$dir"/transcript.*.srt "$dir"/transcript.*.ttml \
          "$dir"/transcript.*.vtt "$out"

    # List explicit English variants. Avoid a broad "en.*" regex because
    # YouTube also exposes auto-translate pseudo-langs like "en-de" that the
    # regex would pick up and that YouTube aggressively rate-limits (HTTP 429).
    if ! yt-dlp --skip-download --no-warnings \
            --write-subs --write-auto-subs \
            --sub-langs "en,en-orig,en-US,en-GB,en-CA,en-AU" \
            --sub-format ttml --convert-subs srt \
            --output "$dir/transcript.%(ext)s" "$url"; then
        echo "yt_transcript: yt-dlp failed for $url" >&2
        return 1
    fi

    local srt
    srt=$(ls -1 "$dir"/transcript.*.srt 2>/dev/null | head -1)
    if [[ -z "$srt" || ! -s "$srt" ]]; then
        echo "yt_transcript: no English subtitles found for $url" >&2
        return 1
    fi

    # SRT -> single-line plain text:
    #   drop blank lines, sequence-number lines, and timestamp lines
    #   strip HTML/font tags
    #   join into one space-separated paragraph, collapse runs of spaces
    awk 'NF && !/^[0-9]+$/ && !/-->/' "$srt" \
        | sed 's/<[^>]*>//g' \
        | tr '\n' ' ' \
        | sed 's/  */ /g' > "$out"

    if [[ ! -s "$out" ]]; then
        echo "yt_transcript: transcript came out empty" >&2
        return 1
    fi

    echo "$out"
}

yt_transcript() { _yt_fetch_transcript "$1"; }
summarize()     { _yt_fetch_transcript "$1" >/dev/null && fabric -sp extract_wisdom < /var/tmp/output.txt; }

# Rip YouTube audio as MP3, using Firefox cookies so playlists/age-gated
# videos work. Accepts one or more URLs (or a playlist URL).
ytmp3() {
    yt-dlp -x -t mp3 --cookies-from-browser firefox "$@"
}

# ---------------------------------------------------------------------------
# Jira
# ---------------------------------------------------------------------------

# List my open tickets across projects.
jg() {
    curl -s -u "$JIRA_EMAIL:$JIRA_TOKEN" \
        "$JIRA_URL/rest/api/3/search/jql" \
        -G --data-urlencode "jql=assignee=currentUser() AND status != Done ORDER BY updated DESC" \
        --data-urlencode "fields=key,summary,status,project" \
        --data-urlencode "maxResults=100" \
        | jq -r '.issues[] | "\(.key)\t\(.fields.project.key)\t\(.fields.status.name)\t\(.fields.summary)"' \
        | column -t -s $'\t'
}

# Pick a ticket via fzf and stash it in $JIRA_TICKET / $JIRA_SUMMARY for
# subsequent commands (jt, jb, ju, jpr, jo).
jp() {
    local ticket
    ticket=$(curl -s -u "$JIRA_EMAIL:$JIRA_TOKEN" \
        "$JIRA_URL/rest/api/3/search/jql" \
        -G --data-urlencode "jql=project=AISHOPPING AND status != Done ORDER BY updated DESC" \
        --data-urlencode "fields=key,summary" \
        --data-urlencode "maxResults=100" \
        | jq -r '.issues[] | "\(.key)\t\(.fields.summary)"' \
        | fzf --delimiter='\t' --with-nth=1,2 \
        | cut -f1)
    [ -z "$ticket" ] && return 1
    export JIRA_TICKET="$ticket"
    export JIRA_SUMMARY=$(curl -s -u "$JIRA_EMAIL:$JIRA_TOKEN" \
        "$JIRA_URL/rest/api/3/issue/$ticket?fields=summary" \
        | jq -r '.fields.summary')
    echo "→ $JIRA_TICKET: $JIRA_SUMMARY"
}

# Transition a Jira ticket by status name.
# Usage: jt                          → fzf-select status for $JIRA_TICKET
#        jt "In Progress"            → transition $JIRA_TICKET to "In Progress"
#        jt TICKET-123 "In Progress" → transition specific ticket
jt() {
    local ticket="" target=""

    if [ $# -eq 0 ]; then
        ticket="$JIRA_TICKET"
    elif [ $# -eq 1 ]; then
        ticket="$JIRA_TICKET"
        target="$1"
    else
        ticket="$1"
        target="$2"
    fi

    [ -z "$ticket" ] && echo "No ticket specified and \$JIRA_TICKET is not set. Run jp first." && return 1

    local transitions
    transitions=$(curl -s -u "$JIRA_EMAIL:$JIRA_TOKEN" \
        "$JIRA_URL/rest/api/3/issue/$ticket/transitions")

    local tid
    if [ -z "$target" ]; then
        local selection
        selection=$(echo "$transitions" \
            | jq -r '.transitions[] | "\(.id)\t\(.name)"' \
            | fzf --delimiter='\t' --with-nth=2 --prompt="$ticket → ")
        [ -z "$selection" ] && return 1
        tid=$(echo "$selection" | cut -f1)
        target=$(echo "$selection" | cut -f2)
    else
        tid=$(echo "$transitions" \
            | jq -r --arg name "$target" \
                '.transitions[] | select(.name | test($name; "i")) | .id' \
            | head -1)

        if [ -z "$tid" ]; then
            echo "✗ No transition matching '$target' for $ticket. Available:"
            echo "$transitions" | jq -r '.transitions[] | "  \(.id): \(.name)"'
            return 1
        fi
    fi

    curl -s -u "$JIRA_EMAIL:$JIRA_TOKEN" \
        "$JIRA_URL/rest/api/3/issue/$ticket/transitions" \
        -H "Content-Type: application/json" \
        -X POST -d "{\"transition\": {\"id\": \"$tid\"}}" > /dev/null

    echo "→ $ticket transitioned to '$target'"
}

# Create a branch from the current ticket and move it to In Progress.
jb() {
    [ -z "$JIRA_TICKET" ] && echo "No ticket selected. Run jp first." && return 1
    local branch
    branch=$(echo "$JIRA_TICKET/$JIRA_SUMMARY" \
        | tr '[:upper:]' '[:lower:]' \
        | sed 's/[^a-z0-9/-]/-/g' \
        | sed 's/--*/-/g' \
        | sed 's/-$//')
    git checkout -b "$branch" main
    jt "$JIRA_TICKET" "In Progress"
}

# Add the last $1 commits (default 5) as a comment on the current ticket.
ju() {
    [ -z "$JIRA_TICKET" ] && echo "No ticket selected. Run jp first." && return 1
    local n="${1:-5}"
    local log
    log=$(git log --oneline -n "$n" --no-decorate)
    echo "$log" | jira issue comment add "$JIRA_TICKET" --no-input
    echo "→ Added $n commits as comment to $JIRA_TICKET"
}

# Open a PR for the current ticket and move it to In Code Review.
jpr() {
    [ -z "$JIRA_TICKET" ] && echo "No ticket selected. Run jp first." && return 1
    local title="[$JIRA_TICKET] $JIRA_SUMMARY"
    gh pr create --title "$title" --fill
    jt "$JIRA_TICKET" "In Code Review"
}

# Create a Story (or other issue type) in a Jira project.
# Works like `git commit -v`:
#   line 1        → summary/title
#   blank line    → separator
#   rest          → description
#
# Usage: jc                           → opens editor
#        jc "Summary here"            → quick, no description
#        jc -p PROJ "Summary here"    → different project
#        jc -t Task                   → different issue type
jc() {
    local project="AISHOPPING"
    local issuetype="Story"
    local team_id="00cb79f8-85c3-4c3a-a423-05afdfeff264"  # Commerce AI Data

    while getopts ":p:t:" opt; do
        case $opt in
            p) project="$OPTARG" ;;
            t) issuetype="$OPTARG" ;;
        esac
    done
    shift $((OPTIND - 1))

    local summary=""
    local description=""

    if [ $# -gt 0 ]; then
        summary="$*"
    else
        local tmpfile
        tmpfile=$(mktemp /tmp/jira-create-XXXXXX)
        cat > "$tmpfile" <<'EOF'

# Enter story above. First line = summary/title.
# Everything after the first blank line = description.
# Lines starting with # are ignored.
# Save and quit to create. Empty summary aborts.
EOF
        ${EDITOR:-nvim} "$tmpfile"

        local body
        body=$(grep -v '^#' "$tmpfile")
        rm -f "$tmpfile"

        summary=$(echo "$body" | head -1 | xargs)
        [ -z "$summary" ] && echo "Aborted — empty summary." && return 1

        description=$(echo "$body" | sed '1d' | awk 'NF{found=1} found' \
            | awk '{lines[NR]=$0} END{for(i=NR;i>=1;i--)if(lines[i]!=""){last=i;break} for(i=1;i<=last;i++)print lines[i]}')
    fi

    local payload
    if [ -n "$description" ]; then
        local desc_json
        desc_json=$(echo "$description" | jq -Rs '
            split("\n")
            | map(select(length > 0))
            | map({
                type: "paragraph",
                content: [{ type: "text", text: . }]
              })')
        payload=$(jq -n \
            --arg proj "$project" \
            --arg sum "$summary" \
            --arg type "$issuetype" \
            --arg team "$team_id" \
            --argjson desc "$desc_json" \
            '{
                fields: {
                    project:   { key:  $proj },
                    summary:   $sum,
                    issuetype: { name: $type },
                    customfield_13804: $team,
                    description: {
                        type: "doc",
                        version: 1,
                        content: $desc
                    }
                }
            }')
    else
        payload=$(jq -n \
            --arg proj "$project" \
            --arg sum "$summary" \
            --arg type "$issuetype" \
            --arg team "$team_id" \
            '{
                fields: {
                    project:   { key:  $proj },
                    summary:   $sum,
                    issuetype: { name: $type },
                    customfield_13804: $team
                }
            }')
    fi

    local response
    response=$(curl -s -u "$JIRA_EMAIL:$JIRA_TOKEN" \
        "$JIRA_URL/rest/api/3/issue" \
        -H "Content-Type: application/json" \
        -X POST -d "$payload")

    local key
    key=$(echo "$response" | jq -r '.key // empty')
    if [ -z "$key" ]; then
        echo "Failed to create issue:"
        echo "$response" | jq .
        return 1
    fi

    export JIRA_TICKET="$key"
    export JIRA_SUMMARY="$summary"
    echo "✓ Created $issuetype → $key: $summary"
    [ -n "$description" ] && echo "  (with description)"
    echo "  $JIRA_URL/browse/$key"
}

# Open the current ticket in the browser.
jo() {
    [ -z "$JIRA_TICKET" ] && echo "No ticket selected. Run jp first." && return 1
    local url="$JIRA_URL/browse/$JIRA_TICKET"
    if command -v open &>/dev/null; then
        open "$url"
    else
        xdg-open "$url"
    fi
}
