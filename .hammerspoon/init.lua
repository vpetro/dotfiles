screenCount = function()
    local count = 0
    for p in pairs(hs.screen.allScreens()) do
        count = count + 1
    end
    return count
end

bindHyper = function()
    if screenCount() > 1 then
        hyper = {"cmd", "alt"}
    else
        hyper = {"cmd", "ctrl"}
    end
    return hyper
end


hyper = bindHyper()

hs.hints.showTitleThresh = 0
hs.window.animationDuration = 0
hs.grid.setMargins{0, 0}
hs.grid.setGrid('100x100')

toggle_iterm_maximize = function(force)
    force = force or false
    iterm_window = hs.appfinder.appFromName("iTerm2"):mainWindow()
    if not (iterm_window:isStandard()) or force then
        iterm_window:focus()
        hs.eventtap.keyStroke({"cmd"}, "return")
    end
end

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

layouts = {
    left50={x=0, y=0, w=50, h=100},
    right50={x=50, y=0, w=50, h=100},
    maximized={x=0, y=0, w=100, h=100}
}

apply_layout = function(apps, grid_mapping, monitor_mapping)
    return function(eventName, params)
        if monitor_mapping == nil then
            monitor_mapping = {}
            for i, app in ipairs(apps) do
                table.insert(monitor_mapping, nil)
            end
        end

        for i, app in ipairs(apps) do
            if app == "iTerm2" then
                toggle_iterm_maximize()
            end
        end

        for i, app_name in ipairs(apps) do
            app = hs.appfinder.appFromName(app_name)
            if app ~= nil then
                cur_window = app:mainWindow()
                hs.grid.set(
                    cur_window,
                    grid_mapping[i],
                    monitor_mapping[i] or cur_window:screen()
                )
                cur_window:focus()
            end
        end

        for i, app in ipairs(apps) do
            if app == "iTerm2" and grid_mapping[i] == layouts.maximized then
                toggle_iterm_maximize(true)
            end
        end

    end
end

layout_work_with_browser = apply_layout(
    {"Firefox", "iTerm2"},
    {layouts.left50, layouts.right50}
)

layout_work_with_pdf = apply_layout(
    {"Skim", "iTerm2"},
    {layouts.left50, layouts.right50}
)

layout_work_with_chat = apply_layout(
    {"Flowdock", "iTerm2"},
    {layouts.left50, layouts.right50}
)

layout_work_chat_with_browser = apply_layout(
    {"Firefox", "Flowdock"},
    {layouts.left50, layouts.right50}
)

layout_default_single = apply_layout(
    {"Firefox", "Flowdock", "iTerm2"},
    {layouts.left50, layouts.right50, layouts.maximized}
)

layout_default_double = apply_layout(
    {"Firefox", "Flowdock", "iTerm2"},
    {layouts.left50, layouts.maximixed, layouts.maximized},
    {hs.screen.primaryScreen(), hs.screen.primaryScreen():toWest(), hs.screen.primaryScreen()}
)




-- apply this function when screen resolution or number of monitors changes
-- screenWatcher = function()
--     return function()
--         if screenCount() > 1 then
--             layout_default_double()
--         else
--             layout_default_single()
--         end
--         hs.reload()
--     end
-- end

webTest = function()
    style = {"closable", "titled", "borderless"}
    w = hs.webview.new({w=1024, h=800, x=200, y=200})
    w = w:url("http://localhost:9001")
    w = w:windowStyle(style)
    w = w:deleteOnClose(true)
    w = w:closeOnEscape(true)
    w = w:allowTextEntry(true)
    w = w:allowNavigationGestures(true)
    w = w:windowTitle("testwebview")
    w = w:show()
    w = w:asHSWindow()
    w:focus()
    w:raise()

    -- created = hs.window.filter("testwebview")
    -- while (created == nil) do
    --     created = hs.window.filter("testwebview")
    -- end
    -- created:raise()
end

-- hs.screen.watcher.new(screenWatcher()):start()

hs.hotkey.bind(hyper, 's', gridset(0, 0, 100, 100))
-- left half
hs.hotkey.bind(hyper, 'a', gridset(0, 0, 50, 100))
-- right half
hs.hotkey.bind(hyper, 'd', gridset(50, 0, 50, 100))

hs.hotkey.bind(hyper, 'q', gridset(0, 0, 33, 100))
hs.hotkey.bind(hyper, 'w', gridset(33, 0, 33, 100))
hs.hotkey.bind(hyper, 'e', gridset(66, 0, 34, 100))

hs.hotkey.bind(hyper, 'x', gridset(25, 0, 50, 100))

hs.hotkey.bind(hyper, "n", function() return hs.window.focusedWindow():moveOneScreenWest() end)
hs.hotkey.bind(hyper, "m", function() return hs.window.focusedWindow():moveOneScreenEast() end)

hs.hints.style = 'vimperator'
hs.hotkey.bind({'alt'}, 'space', hs.hints.windowHints)

hs.hotkey.bind(hyper, "r", function() hs.reload() end)
hs.hotkey.bind(hyper, "b", function() hs.application.launchOrFocus("Firefox") end)
hs.hotkey.bind(hyper, "i", function() hs.application.launchOrFocus("iTerm") end)
hs.hotkey.bind(hyper, "p", function() hs.application.launchOrFocus("VLC") end)
hs.hotkey.bind(hyper, "o", function() hs.application.launchOrFocus("Slack") end)
hs.hotkey.bind(hyper, ";", function() webTest() end)



hs.urlevent.bind("wb", layout_work_with_browser)
hs.urlevent.bind("wp", layout_work_with_pdf)
hs.urlevent.bind("wl", layout_work_with_chat)
hs.urlevent.bind("bl", layout_work_chat_with_browser)
hs.urlevent.bind("w", layout_default_single)


hs.alert.show("Config loaded")
