-- Hotkey bindings.
--
-- Layout: hyper+<letter> for window sizing / app launching / space switching.
-- NOTE: hyper+9 is intentionally reclaimed by meet.lua after this file loads,
-- which is fine as long as you have <=8 spaces.

local kb     = require("keyboard")
local spaces = require("spaces")

-- Wrap a function that needs the focused window. Bindings fired on an empty
-- space (or while a non-window app is frontmost) would otherwise index nil.
local function withFocused(fn)
    return function()
        local win = hs.window.focusedWindow()
        if not win then return end
        fn(win)
    end
end

-- Build a window-grid setter.
local function gridset(x, y, w, h)
    return withFocused(function(win)
        hs.grid.set(win, { x = x, y = y, w = w, h = h }, win:screen())
    end)
end

-- Window-region bindings: hyper+<key>  -> set focused window to {x,y,w,h}.
local region_bindings = {
    s = { 0,  0, 100, 100 },  -- full screen
    a = { 0,  0,  50, 100 },  -- left half
    d = { 50, 0,  50, 100 },  -- right half
    q = { 0,  0,  33, 100 },  -- left third
    w = { 33, 0,  33, 100 },  -- middle third
    e = { 66, 0,  34, 100 },  -- right third
    x = { 25, 0,  50, 100 },  -- centered half
}
for key, rect in pairs(region_bindings) do
    hs.hotkey.bind(kb.hyper, key, gridset(table.unpack(rect)))
end

-- Cross-monitor window movement.
hs.hotkey.bind(kb.hyper, "n", withFocused(function(w) w:moveOneScreenWest() end))
hs.hotkey.bind(kb.hyper, "m", withFocused(function(w) w:moveOneScreenEast() end))

-- Window minimize.
hs.hotkey.bind(kb.hyper, "h",  withFocused(function(w) w:minimize() end))
hs.hotkey.bind(kb.hyper, "\\", function()
    local win = hs.window.frontmostWindow()
    if win then win:minimize() end
end)

-- Reload Hammerspoon config.
hs.hotkey.bind(kb.hyper, "r", hs.reload)

-- App launchers: hyper+<key> -> launchOrFocus(app).
-- (hyper+p is claimed by meet.lua for Meet screen-sharing toggle.)
local app_bindings = {
    k = "Firefox",
    j = "Alacritty",
    l = "Slack",
    v = "mpv",
}
for key, app in pairs(app_bindings) do
    hs.hotkey.bind(kb.hyper, key, function() hs.application.launchOrFocus(app) end)
end

-- Instant space switching (no animation; see spaces.lua).
hs.hotkey.bind({ "ctrl" }, "left",  function() spaces.switchSpace("left")  end)
hs.hotkey.bind({ "ctrl" }, "right", function() spaces.switchSpace("right") end)

-- Jump to space by number: hyper+1..9 (9 gets overridden by meet.lua).
for i = 1, 9 do
    hs.hotkey.bind(kb.hyper, tostring(i), function() spaces.switchToIndex(i) end)
end
