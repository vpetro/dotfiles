local hs = hs
local kb = require("keyboard")

local gridset = function(x, y, w, h)
    return function()
        win = hs.window.focusedWindow()
        hs.grid.set(
            win,
            {x=x, y=y, w=w, h=h},
            win:screen()
        )
    end
end

local function move_windows()
  hs.hotkey.bind(kb.hyper, 's', gridset(0, 0, 100, 100))
  -- left half
  hs.hotkey.bind(kb.hyper, 'a', gridset(0, 0, 50, 100))
  -- right half
  hs.hotkey.bind(kb.hyper, 'd', gridset(50, 0, 50, 100))

  hs.hotkey.bind(kb.hyper, 'q', gridset(0, 0, 33, 100))
  hs.hotkey.bind(kb.hyper, 'w', gridset(33, 0, 33, 100))
  hs.hotkey.bind(kb.hyper, 'e', gridset(66, 0, 34, 100))

  hs.hotkey.bind(kb.hyper, 'x', gridset(25, 0, 50, 100))
end

local function move_monitors()
  hs.hotkey.bind(kb.hyper, "n", function() return hs.window.focusedWindow():moveOneScreenWest() end)
  hs.hotkey.bind(kb.hyper, "m", function() return hs.window.focusedWindow():moveOneScreenEast() end)
end

local function setup()

  move_windows()
  move_monitors()

  hs.hotkey.bind(kb.hyper, "h", function() return hs.window.focusedWindow():minimize() end)

  -- moving applications
  hs.hotkey.bind(kb.hyper, "r", function() hs.reload() end)
  hs.hotkey.bind(kb.hyper, "k", function() hs.application.launchOrFocus("LibreWolf") end)
  -- hs.hotkey.bind(kb.hyper, "i", function() hs.application.launchOrFocus("qutebrowser") end)
  hs.hotkey.bind(kb.hyper, "j", function() hs.application.launchOrFocus("Alacritty") end)
  hs.hotkey.bind(kb.hyper, "l", function() hs.application.launchOrFocus("Slack") end)
  hs.hotkey.bind(kb.hyper, "p", function() hs.application.launchOrFocus("Skim") end)
  hs.hotkey.bind(kb.hyper, "v", function() hs.application.launchOrFocus("mpv") end)

  hs.hotkey.bind(kb.hyper, "`", function() hs.application.launchOrFocus("mpv") end)

  -- hs.hotkey.bind(kb.hyper, ".", function() findZoomWindow() end)
  -- hs.hotkey.bind(kb.hyper, "'", function() hs.window.find("presentation.pdf"):focus() end)

  hs.hotkey.bind(kb.hyper, "\\", function() hs.window.frontmostWindow():minimize() end)
end

M = {}

setup()

return M
