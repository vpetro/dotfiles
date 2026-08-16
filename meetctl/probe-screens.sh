#!/bin/bash
# Dump Hammerspoon's view of all connected screens: index, name, resolution,
# position in the macOS coordinate space, whether it's the primary.
#
# Useful when mapping Chrome's "Screen N" naming (used by
# --auto-select-desktop-capture-source) to the Hammerspoon screen object we
# want to move windows off of.

hs -c '
local out = ""
for i, s in ipairs(hs.screen.allScreens()) do
    local f = s:frame()
    local primary = (s == hs.screen.primaryScreen()) and " [primary]" or ""
    out = out .. string.format(
        "[%d] name=%q  %dx%d  origin=(%d,%d)%s\n",
        i, s:name(), f.w, f.h, f.x, f.y, primary)
end
return out'
