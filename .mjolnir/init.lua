local application = require "mjolnir.application"
local window = require "mjolnir.window"
local screen = require "mjolnir.screen"
local fnutils = require "mjolnir.fnutils"
local hotkey = require "mjolnir.hotkey"
local appfinder = require "mjolnir.cmsj.appfinder"
local alert = require "mjolnir.alert"
local grid = require "mjolnir.sd.grid"
local mjomatic = require "mjolnir.7bits.mjomatic"

local hyper = {"cmd", "alt", "ctrl", "shift"}
local mover = {"cmd", "ctrl"}

local gridset = function(x, y, w, h)
    return function()
        grid.set(
            window.focusedwindow(),
            {x=x, y=y, w=w, h=h},
            screen.mainscreen()
        )
    end
end

grid.GRIDWIDTH = 4
grid.MARGINX = 0
grid.MARGINY = 0

hotkey.bind(hyper, 'c', mjolnir.openconsole)
hotkey.bind(hyper, 'r', mjolnir.reload)

-- window positions
-- maximize
hotkey.bind(hyper, 's', gridset(0, 0, 4, 2))
-- left half
hotkey.bind(hyper, 'a', gridset(0, 0, 2, 2))
-- right half
hotkey.bind(hyper, 'd', gridset(2, 0, 2, 2))

-- window movement
hotkey.bind(mover, "h", function() window.focusedwindow():focuswindow_west() end)
hotkey.bind(mover, "l", function() window.focusedwindow():focuswindow_east() end)
hotkey.bind(mover, "j", function() window.focusedwindow():focuswindow_south() end)
hotkey.bind(mover, "k", function() window.focusedwindow():focuswindow_north() end)

-- layouts
function with_firefox()
    mjomatic.go(
    {
        "FFFFFFFFFFFFFiiiiiiiiiii",
        "FFFFFFFFFFFFFiiiiiiiiiii",
        "FFFFFFFFFFFFFiiiiiiiiiii",
        "FFFFFFFFFFFFFiiiiiiiiiii",
        "FFFFFFFFFFFFFiiiiiiiiiii",
        "",
        "F Firefox",
        "i iTerm"
    })
end

hotkey.bind(hyper, '1', with_firefox)
