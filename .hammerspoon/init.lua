
local hyper = {"cmd", "alt"}

-- if #(hs.screen.allScreens()) then hyper = {"cmd", "ctrl"} end

hs.hints.showTitleThresh = 0
hs.window.animationDuration = 0
hs.grid.setMargins{0, 0}
hs.grid.setGrid('100x100')

local gridset = function(x, y, w, h)
    return function()
        cur_window = hs.window.focusedWindow()
        hs.grid.set(
            cur_window,
            {x=x, y=y, w=w, h=h},
            cur_window:screen()
        )
    end
end

hs.hotkey.bind(hyper, 's', gridset(0, 0, 100, 100))
-- left half
hs.hotkey.bind(hyper, 'a', gridset(0, 0, 50, 100))
-- right half
hs.hotkey.bind(hyper, 'd', gridset(50, 0, 50, 100))

hs.hotkey.bind(hyper, 'w', gridset(25, 0, 50, 100))

hs.hotkey.bind(hyper, "n", function() return hs.window.focusedWindow():moveOneScreenWest() end)
hs.hotkey.bind(hyper, "m", function() return hs.window.focusedWindow():moveOneScreenEast() end)

hs.hints.style = 'vimperator'
hs.hotkey.bind({'alt'}, 'space', hs.hints.windowHints)

hs.hotkey.bind(hyper, "r", function() hs.reload() end)

hs.alert.show("Config loaded")
