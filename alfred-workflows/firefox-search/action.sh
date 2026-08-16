#!/bin/bash
# Handle a selection from the Firefox-search Alfred script filter.
#
# $1 is one of:
#   tab|<brotab-id>   -- activate that open tab and raise Firefox
#   url|<url>         -- open the URL in Firefox
set -euo pipefail

arg="$1"
kind="${arg%%|*}"
payload="${arg#*|}"

BROTAB="$HOME/.local/share/uv/tools/brotab/bin/brotab"

case "$kind" in
    tab)
        "$BROTAB" activate "$payload"
        osascript -e 'tell application "Firefox" to activate'
        ;;
    url)
        open -a Firefox "$payload"
        ;;
    *)
        echo "unknown action kind: $kind" >&2
        exit 1
        ;;
esac
