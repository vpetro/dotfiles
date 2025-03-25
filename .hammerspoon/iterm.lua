M = {}

M.toggle_iterm_maximize = function(force)
    force = force or false
    local iterm_window = hs.appfinder.appFromName("iTerm2"):mainWindow()
    if not (iterm_window:isStandard()) or force then
        iterm_window:focus()
        hs.eventtap.keyStroke({"cmd"}, "return")
    end
end

return M
