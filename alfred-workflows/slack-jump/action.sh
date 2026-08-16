#!/bin/bash
# Handle a selection from the slack-jump script filter.
#
# $1 is a slack:// deep link built by search.py.
#
# `open -a Slack` rather than a bare `open`: Hammerspoon is the registered
# default handler for http(s), and going through it would bounce us to
# Firefox. Naming the app keeps the link inside the desktop client.
set -euo pipefail

url="$1"

open -a Slack "$url"

# `open` hands the URL to Slack but does not reliably raise it.
osascript -e 'tell application "Slack" to activate'
