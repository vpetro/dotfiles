local kb = require("keyboard")

M = {}

function M.findZoomWindow()
    -- local previousTitle = hs.application.frontmostApplication():focusedWindow():title()
    hs.appfinder.windowFromWindowTitlePattern("Zoom Meeting.*"):focus()
    hs.eventtap.keyStroke(kb.hyper, "a")
    hs.eventtap.keyStroke({"cmd", "shift"}, "a")
end

return M
