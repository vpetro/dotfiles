-- Hammerspoon entry point.
--
-- Load order matters: mappings.lua binds hyper+1..9 for space switching,
-- then meet.lua reclaims hyper+9. Fine as long as you have <=8 spaces.

require("settings")       -- window animation + grid tweaks
require("mappings")       -- hotkeys: window layout, app launch, space switching
require("meet")           -- hyper+9/0/p: Google Meet mute/jump/present
-- Firefox tab/history search and the Slack jumper live in Alfred workflows
-- now (alfred-workflows/), not here.

local urlhandler = require("urlhandler")
hs.urlevent.httpCallback = urlhandler.handler

hs.alert.show("Config loaded")
