-- Google Meet control via `meetctl` (Chrome DevTools Protocol client).
--
-- See meetctl/ in the dotfiles repo for install steps.
--
-- Hotkeys:
--   Hyper+9 — toggle mic in the open Meet tab. No-op if no tab exists.
--   Hyper+0 — jump to the Meet tab; if none, launch a new pre-muted
--             meeting and copy its URL to the clipboard.
--   Hyper+p — start sharing the entire screen (or stop if already sharing).
--             One key, zero clicks: calls `meetctl present-screen` which
--             drives Meet's Share button + Chrome's native picker end-to-end.

local kb = require("keyboard")

-- Absolute path: hs.execute runs in a bash login shell and doesn't see zsh's
-- PATH additions, so $HOME/bin may not be on PATH.
local MEETCTL = os.getenv("HOME") .. "/bin/meetctl"

-- Run `meetctl <cmd>`. Returns (result, err):
--   result -- parsed JSON (table), boolean, or bare string
--   err    -- non-nil on non-zero exit; contains the combined stderr text
local function meetctl(cmd)
    local output, status = hs.execute(MEETCTL .. " " .. cmd .. " 2>&1")
    output = (output or ""):gsub("%s+$", "")
    if not status then
        return nil, output ~= "" and output or "meetctl failed"
    end
    local decoded = hs.json.decode(output)
    if decoded ~= nil then return decoded, nil end
    return output, nil
end

local function errIsNoTab(err)
    return err and err:find("no meet tab", 1, true) ~= nil
end

-- Hyper+9: toggle mic.
local function toggleMic()
    local r, err = meetctl("mute")
    if errIsNoTab(err) then
        hs.alert.show("🎤 No Meet tab — use Hyper+0 to start one", 2)
        return
    end
    if err then
        hs.alert.show("⚠️ " .. err, 2)
        return
    end
    local mic = type(r) == "table" and r.mic or nil
    if     mic == "on"  then hs.alert.show("🎤 Mic: ON",  1.5)
    elseif mic == "off" then hs.alert.show("🎤 Mic: OFF", 1.5)
    else                     hs.alert.show("🎤 Mic toggled", 1.5)
    end
end

-- Hyper+0: `meetctl new` is smart -- focuses the existing Meet tab if one
-- is open, otherwise launches Chrome (if needed) and creates a pre-muted
-- meeting. Works in every state, so this is just a thin wrapper that
-- picks the right alert based on what happened.
local function jumpOrLaunch()
    local r, err = meetctl("new")
    if err then
        hs.alert.show("⚠️ " .. err, 3)
        return
    end

    local action = type(r) == "table" and r.action or nil
    if action == "focused" then
        hs.alert.show("📍 Teleported to Meet", 1.5)
    elseif action == "launching" then
        hs.alert.show("🚀 Chrome launching… sign in if prompted", 3)
    elseif action == "created" then
        if r.url then
            hs.pasteboard.setContents(r.url)
            hs.alert.show("📋 URL Copied: " .. r.url, 2)
        else
            hs.alert.show("🚀 Meeting launched", 1.5)
        end
    else
        hs.alert.show("🚀 Meeting", 1.5)
    end
end

-- Screen-share window relocation + Chrome anchoring.
--
-- Screens are matched by name so ordering quirks in hs.screen.allScreens()
-- don't trip us up. Missing screens -> functions become no-ops.
--
-- Choreography:
--
--   Chrome launched         -> DELL (via the window filter below)
--   Share starts (Hyper+P)  -> Chrome -> BenQ, other windows on DELL ->
--                              BenQ, Alacritty stays put
--   Share stops (Hyper+P)   -> Chrome -> DELL (we don't move others back;
--                              that'd be annoying and requires state)
local SHARED_SCREEN_NAME = "DELL U3223QE"
local DEST_SCREEN_NAME   = "BenQ PD2700U"
local KEEP_ON_SHARED     = { Alacritty = true }

local function findScreenByName(name)
    for _, s in ipairs(hs.screen.allScreens()) do
        if s:name() == name then return s end
    end
    return nil
end

local function appName(win)
    local ok, name = pcall(function() return win:application():name() end)
    return ok and name or nil
end

-- Move every Chrome window to the named screen. Used to park Chrome on
-- DELL at launch / on stop-sharing, and on BenQ at start-sharing.
-- Doesn't require isStandard() -- Chrome's sharing-indicator window has a
-- non-standard role and we want to catch it too.
local function moveChromeToScreen(screenName)
    local dest = findScreenByName(screenName)
    if not dest then return end
    for _, w in ipairs(hs.window.allWindows()) do
        if appName(w) == "Google Chrome" and w:screen() ~= dest then
            w:moveToScreen(dest)
        end
    end
end

-- Move everything-but-keep-list off the shared screen to DEST.
local function relocateFromSharedScreen()
    local shared = findScreenByName(SHARED_SCREEN_NAME)
    local dest   = findScreenByName(DEST_SCREEN_NAME)
    if not shared or not dest or shared == dest then return end

    for _, w in ipairs(hs.window.allWindows()) do
        if w:isStandard() and w:screen() == shared then
            local name = appName(w)
            if name and not KEEP_ON_SHARED[name] then
                w:moveToScreen(dest)
            end
        end
    end
end

-- Whether Meet is currently sharing. Flipped by togglePresent() below.
-- New Chrome windows created while this is true (notably the sharing
-- indicator that Meet spawns mid-share) are routed to the BenQ and
-- maximized; new Chrome windows otherwise (e.g. at initial launch, or
-- popups) are routed to the DELL.
local _isPresenting = false

-- Anchor new Chrome windows. `allowRoles = "*"` so we catch Chrome's
-- sharing-indicator (non-standard floating window), not just regular
-- browser windows.
local _chromeWindowFilter = hs.window.filter.new(false)
    :setAppFilter("Google Chrome", { allowRoles = "*" })

_chromeWindowFilter:subscribe(hs.window.filter.windowCreated, function(w)
    local targetName = _isPresenting and DEST_SCREEN_NAME or SHARED_SCREEN_NAME
    local target = findScreenByName(targetName)
    if not target then return end

    if _isPresenting then
        -- maximize on the target screen. Using setFrame(screen:frame())
        -- is more reliable than :maximize() on Chrome's floating/utility
        -- windows, which ignore the standard maximize action.
        -- Slight delay so macOS has time to settle the window after Chrome
        -- creates it; without it setFrame sometimes races and snaps back.
        hs.timer.doAfter(0.15, function()
            if w and hs.window.get(w:id()) then
                w:setFrame(target:frame())
            end
        end)
    elseif w:screen() ~= target then
        w:moveToScreen(target)
    end
end)

-- Hyper+P: toggle screen sharing. Before STARTING a share, relocate non-
-- Alacritty windows off the screen we're about to share. Stopping a share
-- doesn't move anything.
local function togglePresent()
    -- Figure out whether this press will start or stop sharing. `meetctl
    -- status` is cheap (one CDP eval). If we can't read it, skip the
    -- relocation step and just fall through to the toggle.
    local status = meetctl("status")
    local willStart = not (type(status) == "table" and status.presenting)

    if willStart then
        -- Move Chrome off the shared screen first, then shuttle other
        -- non-keep-list windows away from DELL. Flip the presenting flag
        -- so the window filter routes subsequently-spawned Chrome windows
        -- (sharing indicator, etc.) to BenQ instead of DELL.
        _isPresenting = true
        moveChromeToScreen(DEST_SCREEN_NAME)
        relocateFromSharedScreen()
    end

    local r, err = meetctl("present-screen")
    if errIsNoTab(err) then
        hs.alert.show("📺 No Meet tab", 1.5)
        return
    end
    if err then
        hs.alert.show("⚠️ " .. err, 2)
        return
    end
    local action = type(r) == "table" and r.action or nil
    if action == "stopped" then
        _isPresenting = false
        moveChromeToScreen(SHARED_SCREEN_NAME)
        hs.alert.show("📺 Stopped sharing", 1.5)
    else
        hs.alert.show("📺 Sharing entire screen", 1.5)
    end
end

hs.hotkey.bind(kb.hyper, "9", toggleMic)
hs.hotkey.bind(kb.hyper, "0", jumpOrLaunch)
hs.hotkey.bind(kb.hyper, "p", togglePresent)
