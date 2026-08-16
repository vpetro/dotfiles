#!/usr/bin/env python3
"""
Alfred script filter: jump straight to a Slack DM or channel.

Replaces the old hs.chooser-based Slack teleporter in .hammerspoon/slack.lua.

Input:  sys.argv[1] -- the user's query (possibly multi-word).
Output: Alfred 5 script filter JSON on stdout.

Each item's `arg` is the Slack deep link to open, already resolved from the
roster entry's id. Filtering happens here (not Alfred's built-in) so
multi-word queries match as AND across name + subtitle + keywords.

The roster lives in roster.json next to this script -- adding a teammate is a
data edit, not a code edit.
"""

from __future__ import annotations

import json
import os
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
ROSTER = HERE / "roster.json"

SLACK_APP = "/Applications/Slack.app"
SLACK_ICON = {"type": "fileicon", "path": SLACK_APP} if os.path.exists(SLACK_APP) else None


def slack_uri(team: str, ident: str) -> str:
    """Build the right slack:// deep link for a Slack object ID.

    Slack IDs are prefixed by type, so the prefix tells us which URI form to
    use:
        D -- DM conversation      -> channel?  (lands in the message box)
        C -- public/private chan  -> channel?
        G -- legacy private group -> channel?
        U -- user (workspace)     -> user?     (opens/creates the DM)
        W -- user (Enterprise Grid org-wide)   -> user?

    Prefer a D... id when you have one: it lands with the cursor in the
    message box, whereas user? just opens the conversation.
    """
    kind = "user" if ident[:1] in ("U", "W") else "channel"
    return f"slack://{kind}?team={team}&id={ident}"


def load_roster() -> tuple[str, list[dict]]:
    with open(ROSTER) as f:
        data = json.load(f)
    return data["team"], data.get("entries", [])


def matches(entry: dict, terms: list[str]) -> bool:
    """AND across all terms, each matched anywhere in the entry's text."""
    haystack = " ".join(
        [entry.get("name", ""), entry.get("subtitle", ""), entry.get("keywords", "")]
    ).lower()
    return all(t in haystack for t in terms)


def main() -> None:
    query = sys.argv[1] if len(sys.argv) > 1 else ""
    terms = [t for t in query.lower().split() if t]

    try:
        team, entries = load_roster()
    except (OSError, json.JSONDecodeError, KeyError) as exc:
        print(json.dumps({"items": [{
            "title": "Could not read roster.json",
            "subtitle": str(exc),
            "valid": False,
        }]}))
        return

    items = []
    for entry in entries:
        if terms and not matches(entry, terms):
            continue
        item = {
            "title": entry["name"],
            "subtitle": entry.get("subtitle", ""),
            "arg": slack_uri(team, entry["id"]),
            "uid": entry["id"],
            "valid": True,
            "match": " ".join(
                [entry.get("name", ""), entry.get("keywords", "")]
            ),
        }
        if SLACK_ICON:
            item["icon"] = SLACK_ICON
        items.append(item)

    if not items:
        items.append({
            "title": f"No match for {query!r}",
            "subtitle": "Edit roster.json to add people or channels",
            "valid": False,
        })

    print(json.dumps({"items": items}))


if __name__ == "__main__":
    main()
