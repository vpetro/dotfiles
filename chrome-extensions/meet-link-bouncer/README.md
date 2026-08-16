# Meet Link Bouncer

Chrome extension for **Chrome-for-Meet** — the dedicated Chrome profile that
lives at `~/.chrome-for-meet/` and exists only to host Google Meet calls.

## What it does

Intercepts link clicks inside `meet.google.com` (shared in chat, clicked
from the people panel, etc.). If the target URL isn't on `meet.google.com`
itself, the click is bounced through Hammerspoon via a
`hammerspoon://open-external?url=…` URL. Hammerspoon then hands the URL to
its normal routing logic, which sends it to your system default browser
(Firefox).

End result: links clicked in Meet never accumulate tabs in Chrome-for-Meet
— they open in Firefox with your real browsing session, history,
extensions, etc.

## Install

1. In **Chrome-for-Meet** (the profile in `~/.chrome-for-meet/`):
   - Open `chrome://extensions`
   - Toggle *Developer mode* on
   - Click *Load unpacked*, select this directory.
2. First time you click a non-Meet link, Chrome will ask
   *"Open Hammerspoon?"* — check **"Always allow meet.google.com to open
   links of this type"** and click **Open**.

## Relationship to Hammerspoon

This relies on a `hs.urlevent.bind("open-external", …)` handler registered
by `~/.hammerspoon/urlhandler.lua`. The handler URL-decodes the `url`
parameter and calls back into the default-browser routing function, so
the same rules that apply to any other link click (meet.google.com ->
Chrome, youtube.com -> mpv, everything else -> Firefox) apply here too.
