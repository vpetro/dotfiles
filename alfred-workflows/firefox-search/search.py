#!/usr/bin/env python3
"""
Alfred script filter: search Firefox tabs (via brotab) + recent history
(via a snapshot of Firefox's places.sqlite).

Input:  sys.argv[1] -- the user's query (possibly multi-word).
Output: Alfred 5 script filter JSON on stdout.

Each item's `arg` is one of:
    tab|<brotab-id>     -- activate an open tab
    url|<url>           -- open this history URL in Firefox

Filtering happens here (not Alfred's built-in), so multi-word queries match
as AND across title + URL, case-insensitive.

Debug log at /tmp/ff-alfred-debug.log -- tail it when iterating.
"""

# PEP 563: make `Path | None` annotations parse under macOS's bundled 3.9.
from __future__ import annotations

import json
import os
import pathlib
import shutil
import sqlite3
import subprocess
import sys
import time

HOME        = pathlib.Path(os.environ["HOME"])
BROTAB      = HOME / ".local/share/uv/tools/brotab/bin/brotab"
FF_PROFILES = HOME / "Library/Application Support/Firefox/Profiles"

# Firefox's app icon -- Alfred extracts it from the .app bundle when we pass
# { type: fileicon, path: ... }. Fall back gracefully if Firefox moved.
FIREFOX_APP = "/Applications/Firefox.app"
FIREFOX_ICON = {"type": "fileicon", "path": FIREFOX_APP} if os.path.exists(FIREFOX_APP) else None

CACHE_DIR   = pathlib.Path(os.environ.get("alfred_workflow_cache", "/tmp/ff-alfred-cache"))
CACHE_DIR.mkdir(parents=True, exist_ok=True)
PLACES_COPY = CACHE_DIR / "places-copy.sqlite"

# Firefox updates places.sqlite continuously; copying is cheap but not worth
# doing on every keystroke.
PLACES_TTL_SECS = 30

HISTORY_LIMIT = 300


def _debug(msg: str) -> None:
    try:
        with open("/tmp/ff-alfred-debug.log", "a") as f:
            f.write(f"{time.strftime('%H:%M:%S')} {msg}\n")
    except OSError:
        pass


def find_firefox_profile() -> pathlib.Path | None:
    """Return the path to the current Firefox profile's places.sqlite.

    Prefers ESR, then release, then plain `default`. The prefix before the
    suffix is a random string that differs per install, so we glob.
    """
    for suffix in ("default-esr", "default-release", "default"):
        for p in FF_PROFILES.glob(f"*.{suffix}"):
            places = p / "places.sqlite"
            if places.is_file():
                return places
    return None


def get_tabs() -> list[dict]:
    """Return [{id, title, url}, ...] from `brotab list`. Empty on failure."""
    try:
        out = subprocess.check_output(
            [str(BROTAB), "list"],
            text=True,
            timeout=5,
            stderr=subprocess.DEVNULL,
        )
    except (subprocess.SubprocessError, FileNotFoundError) as e:
        _debug(f"  brotab failed: {e}")
        return []

    tabs = []
    for line in out.splitlines():
        parts = line.split("\t")
        if len(parts) >= 3:
            tabs.append({"id": parts[0], "title": parts[1], "url": parts[2]})
    return tabs


def get_history() -> list[dict]:
    """Return [{title, url}, ...] of recent history, newest first."""
    src = find_firefox_profile()
    if not src:
        return []

    if (not PLACES_COPY.exists()
            or time.time() - PLACES_COPY.stat().st_mtime > PLACES_TTL_SECS):
        try:
            shutil.copyfile(src, PLACES_COPY)
        except OSError as e:
            _debug(f"  copyfile failed: {e}")
            return []

    try:
        conn = sqlite3.connect(f"file:{PLACES_COPY}?mode=ro", uri=True)
        rows = conn.execute(
            "SELECT title, url FROM moz_places "
            "WHERE title IS NOT NULL AND url LIKE 'http%' "
            "ORDER BY last_visit_date DESC LIMIT ?",
            (HISTORY_LIMIT,),
        ).fetchall()
        conn.close()
    except sqlite3.Error as e:
        _debug(f"  sqlite failed: {e}")
        return []

    return [{"title": t, "url": u} for t, u in rows if t]


def matches(item: dict, words: list[str]) -> bool:
    """Multi-word AND filter over title + subtitle (== URL)."""
    if not words:
        return True
    haystack = f"{item['title']} {item['subtitle']}".lower()
    return all(w in haystack for w in words)


def build_items() -> list[dict]:
    """Combine tabs + history into Alfred items (no emojis; clean titles)."""
    tabs = get_tabs()
    history = get_history()

    def with_icon(item: dict) -> dict:
        if FIREFOX_ICON:
            item["icon"] = FIREFOX_ICON
        return item

    items = []
    for t in tabs:
        items.append(with_icon({
            "uid":      f"tab-{t['id']}",
            "title":    t["title"],
            "subtitle": t["url"],
            "arg":      f"tab|{t['id']}",
        }))

    seen_urls = {t["url"] for t in tabs}
    for h in history:
        if h["url"] in seen_urls:
            continue  # don't duplicate: if it's already an open tab, skip the history entry
        items.append(with_icon({
            "uid":      f"url-{h['url']}",
            "title":    h["title"],
            "subtitle": h["url"],
            "arg":      f"url|{h['url']}",
        }))

    return items


def main() -> int:
    query = sys.argv[1] if len(sys.argv) > 1 else ""
    words = [w for w in query.lower().split() if w]

    _debug(f"invoked  query={query!r}  python={sys.version.split()[0]}")

    items = build_items()
    filtered = [i for i in items if matches(i, words)]

    _debug(f"  {len(items)} total -> {len(filtered)} after filter for {words!r}")

    if not filtered:
        filtered = [{
            "title": f"No matches for {query!r}" if query else "No Firefox tabs or history",
            "subtitle": "Is brotab installed and is Firefox running?" if not items else "",
            "valid": False,
        }]

    print(json.dumps({"items": filtered}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
