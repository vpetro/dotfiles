-- Hammerspoon-as-macOS-default-browser: every http/https link in every app
-- ends up here via hs.urlevent.httpCallback (set in init.lua).
--
-- The handler routes URLs to different apps based on host:
--   meet.google.com   -> Chrome (dedicated Meet-only browser)
--   zoom.us links     -> Zoom.app
--   youtube / twitch  -> mpv (videos play outside the browser)
--   everything else   -> Firefox (default daily-driver browser)

local log = hs.logger.new("urlhandler", "info")

local DEFAULT_BROWSER = "/Applications/Firefox.app"
local CHROME_FOR_MEET = os.getenv("HOME") .. "/bin/chrome-for-meet"
local VIDEO_PLAYER    = "/Applications/mpv.app"
local ZOOM            = "/Applications/zoom.us.app"

local M = {}

-- Shell-quote a string for use inside `open -a '<app>' '<arg>'`.
local function q(s)
    return "'" .. s:gsub("'", [['\'']]) .. "'"
end

-- Open a URL in an app. `new_instance` starts a fresh window (-n) instead of
-- passing the URL to a running instance.
local function openIn(app, url, new_instance)
    local flag = new_instance and "-n " or ""
    hs.execute("open " .. flag .. "-a " .. q(app) .. " " .. q(url))
end

-- Routing table: { {pattern, handler}, ... }. First match wins.
-- Handler receives (url, host, scheme, params) and decides what to do.
local routes = {
    -- Zoom slack-callback URLs wrap the real meeting ID; unwrap and pass.
    {
        pattern = "applications%.zoom%.us",
        handle  = function(url)
            local meetingId = string.match(url, "callback/slack/(.*)%?") or
                              string.match(url, "callback/slack/(.*)$")
            if meetingId then
                log.i("zoom meeting id: " .. meetingId)
                openIn(ZOOM, "https://zoom.us/j/" .. meetingId)
            else
                log.w("couldn't parse zoom meeting id from: " .. url)
                openIn(ZOOM, url)
            end
        end,
    },
    { pattern = "zoom%.us",         handle = function(u) openIn(ZOOM, u) end },
    {
        -- Meet: launch via our wrapper so Chrome starts with the debugging
        -- port + auto-select-source flags. `meetctl` needs them.
        --
        -- The screen count is passed so the wrapper picks "Screen 2" when
        -- docked to an external monitor (assumed external = secondary).
        pattern = "meet%.google%.com",
        handle  = function(u)
            local n = #hs.screen.allScreens()
            hs.execute(string.format("%s --screens=%d %s",
                q(CHROME_FOR_MEET), n, q(u)))
        end,
    },
    { pattern = "youtube%.com",     handle = function(u) openIn(VIDEO_PLAYER, u, true) end },
    { pattern = "youtu%.be",        handle = function(u) openIn(VIDEO_PLAYER, u, true) end },
    { pattern = "twitch%.tv",       handle = function(u) openIn(VIDEO_PLAYER, u, true) end },
}

function M.handler(scheme, host, params, url)
    log.i("dispatch: " .. tostring(url))
    host = host or ""

    for _, route in ipairs(routes) do
        if host:find(route.pattern) then
            route.handle(url, host, scheme, params)
            return
        end
    end

    -- Fallback: default browser.
    openIn(DEFAULT_BROWSER, url)
end

-- hammerspoon://open-external?url=<encoded URL>
--
-- Bounces a URL back through our http(s) routing. Used by the Chrome-for-
-- Meet link-bouncer extension so links clicked inside Meet open in Firefox
-- (via the default-browser handler chain) instead of accumulating tabs in
-- Chrome-for-Meet.
hs.urlevent.bind("open-external", function(_event, params)
    -- Hammerspoon decodes query-string params before handing them to us,
    -- so params.url is already a usable URL string.
    local url = params and params.url
    if not url or url == "" then
        log.w("open-external: no url param")
        return
    end
    log.i("open-external: " .. url)
    local scheme, rest = url:match("^(%w+)://(.*)$")
    local host = rest and rest:match("^([^/?#]+)") or ""
    M.handler(scheme or "https", host, {}, url)
end)

return M
