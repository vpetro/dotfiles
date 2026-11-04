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
