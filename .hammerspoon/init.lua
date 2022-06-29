hs = hs

hasExternalKeyboad = function()
    for _,v in pairs(hs.usb.attachedDevices()) do
        for k1, v1 in pairs(v) do
            if k1 == "productName" and v1 == "Kinesis Keyboard Hub" then
                return true
            end
            if k1 == "productName" and v1 == "Advantage2 Keyboard" then
                return true
            end
        end
    end
    return false
end


bindHyper = function()
    if hasExternalKeyboad() then
        hyper = {"cmd", "alt"}
    else
        hyper = {"cmd", "ctrl"}
    end
    return hyper
end

findZoomWindow = function()
    previousTitle = hs.application.frontmostApplication():focusedWindow():title()
    hs.appfinder.windowFromWindowTitlePattern("Zoom Meeting.*"):focus()
    hs.eventtap.keyStroke(hyper, "a")
    hs.eventtap.keyStroke({"cmd", "shift"}, "a")
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
    maximized={x=0, y=0, w=100, h=100},
    topright={x=50,y=0,w=50,h=50},
    bottomright={x=50,y=50,w=50,h=50}
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
    {"qutebrowser", "iTerm2"},
    {layouts.left50, layouts.right50},
    {hs.screen.primaryScreen(), hs.screen.primaryScreen()}
)

layout_work_with_pdf = apply_layout(
    {"Skim", "iTerm2"},
    {layouts.left50, layouts.right50}
)

layout_work_with_zoom = apply_layout(
    {"zoom.us", "iTerm2"},
    {layouts.left50, layouts.right50}
)

layout_work_with_chat = apply_layout(
    {"Slack", "iTerm2"},
    {layouts.left50, layouts.right50}
)

layout_work_chat_with_browser = apply_layout(
    {"qutebrowser", "Slack"},
    {layouts.left50, layouts.right50}
)

layout_default_single = apply_layout(
    {"qutebrowser", "Slack", "iTerm2"},
    {layouts.left50, layouts.right50, layouts.maximized}
)

layout_default_double = apply_layout(
    {"qutebrowser", "Slack", "iTerm2"},
    {layouts.left50, layouts.maximixed, layouts.maximized},
    {hs.screen.primaryScreen(), hs.screen.primaryScreen():toWest(), hs.screen.primaryScreen()}
)

layout_double_zoom = apply_layout(
    {"qutebrowser", "zoom.us", "iTerm2", "Slack", "Firefox"},
    {layouts.left50, layouts.topright, layouts.bottomright, layouts.left50, layouts.right50},
    {hs.screen.primaryScreen(), hs.screen.primaryScreen(), hs.screen.primaryScreen(), hs.screen.primaryScreen():toEast(), hs.screen.primaryScreen():toEast()}
)

local char_to_hex = function(c)
  return string.format("%%%02X", string.byte(c))
end

local function urlencode(url)
  if url == nil then
    return
  end
  url = url:gsub("\n", "\r\n")
  -- url = url:gsub(url, "([^%w _ %- . ~])", char_to_hex)
  url = string.gsub(url, "([^%w _%%%-%.~])", char_to_hex)

  -- url = url:gsub("([^%w ])", char_to_hex)
  url = url:gsub(" ", "+")
  return url
end

local hex_to_char = function(x)
  return string.char(tonumber(x, 16))
end

local urldecode = function(url)
  if url == nil then
    return
  end
  url = url:gsub("+", " ")
  url = url:gsub("%%(%x%x)", hex_to_char)
  return url
end

webTest = function()
    style = {"closable", "titled"} -- , "borderless"}
    w = hs.webview.new({w=1024, h=800, x=200, y=200})
    w = w:url("file:///tmp/output.html")
    w = w:windowStyle(style)
    w = w:deleteOnClose(true)
    w = w:closeOnEscape(true)
    w = w:allowTextEntry(true)
    w = w:allowNavigationGestures(true)
    w = w:windowTitle("testwebview")
    w = w:show()
    w = w:hswindow()
    w:raise()
    w:focus()

end


function zoomMuteToggle()
  local mic = hs.audiodevice.defaultInputDevice()
  local zoom = hs.application("Zoom")

  local muted = zoom:findMenuItem("Unmute Audio")

  if muted then
    zoom:selectMenuItem("Unmute Audio")
    muted = false
  else
    zoom:selectMenuItem("Mute Audio")
    muted = true
  end

end

function zoomGalleryViewToggle()
  local zoom = hs.application("Zoom")

  local inSpeakerView = zoom:findMenuItem("Gallery View")

  if inSpeakerView then
    zoom:selectMenuItem("Gallery View")
    inGalleryView = true
  else
    zoom:selectMenuItem("Speaker View")
    inGalleryView = false
  end
end

function tableLength(tbl)
  local count = 0
  for _ in pairs(tbl) do
    count = count + 1
  end
  return count
end

function zoomWindowWatcher(element, event, watcher)

  function getNumberofZoomWindows()
    local zoom = hs.application('zoom.us')
    local numWindows = 0
    if zoom then
      numWindows = tableLength(zoom:allWindows())
    end
    return numWindows
  end

  function isConnectedPredicate()
    local zoom = hs.application('zoom.us')
    if zoom and zoom:findMenuItem("Gallery View") then
      return true
    else 
      return false
    end
  end

  function toggleGalleryViewAction(timer)
    log.i('TOGGLING the gallery view')
    zoomGalleryViewToggle()
    log.i('STOPPING the timer')
    timer:stop()
  end


  local timer = nil

  log.i("number of zoom windows: " .. tostring(getNumberofZoomWindows()))

  if getNumberofZoomWindows() == 2 and event == hs.uielement.watcher.windowCreated then
    log.i('starting the timer')
    timer = hs.timer.waitUntil(isConnectedPredicate, toggleGalleryViewAction)
    timer:start()
    log.i('started the timer')
  end

  if getNumberofZoomWindows() == 1 and event == hs.uielement.watcher.elementDestroyed then
    log.i("STOPPING the watcher, only parent window is avalaible")
    watcher.stop()
  end
end

function tf()
  local zoomAppWatcher = hs.application.watcher.new(zoomApplicationWatcher)
  zoomAppWatcher:start()

  -- local zoom = hs.application("zoom.us")
  -- local z = zoom:newWatcher(zoomWindowWatcher)
  -- z:start({hs.uielement.watcher.windowCreated})
end

zww = nil

function zoomApplicationWatcher(name, eventType, app)
  if name == "zoom.us" then
    log.i('got event from zoom')


    if eventType == hs.application.watcher.activated then
      log.i(name .. " application activated")
    end

    if eventType == hs.application.watcher.deactivated then
      log.i(name .. " application deactivated")
    end

    if eventType == hs.application.watcher.hidden then
      log.i(name .. " application hidden")
    end

    if eventType == hs.application.watcher.launching then
      log.i(name .. " application launching")
    end

    if eventType == hs.application.watcher.unhidden then
      log.i(name .. " application unhidden")
    end

    if eventType == hs.application.watcher.launched then
      log.i('zoom event is application launched')
      zww = app:newWatcher(zoomWindowWatcher)
      -- watching windowCreated events
      zww:start({hs.uielement.watcher.windowCreated, hs.uielement.watcher.elementDestroyed})
      log.i('started watching zoom application with the window watcher')
    end

    -- dont need to check if zww globak is enabled, we can just list the applications
    if zww and event == hs.application.watcher.terminated then
      -- TODO: have to figure out if zoom is still running and turn off the watcher
      log.i('zoom application terminated')
      zww:stop()
    end
  end

end


log = hs.logger.new('petro', 'debug')


function urlHandler(scheme, host, param, fullURL)
  log.i("dispatching url: '" .. fullURL .. "'")
  if string.find(host, "reddit.com") then
    log.i('opening with qutebrowser')
    hs.urlevent.openURLWithBundle(fullURL, "org.qt-project.Qt.QtWebEngineCore")
  elseif string.find(host, 'applications.zoom.us') then
    local meetingId = string.match(fullURL, 'https://applications.zoom.us/event/callback/slack/(.*)?.*')
    log.i('opening with zoom with meeting id: ' .. meetingId)
    if meetingId then
      hs.execute('open -a /Applications/zoom.us.app \'https://zoom.us/j/' .. meetingId .. '\'')
    end
  elseif string.find(host, "zoom.us") then
    log.i('opening with zoom')
    hs.execute('open -a /Applications/zoom.us.app ' .. "'" .. fullURL .. "'")
  elseif string.find(host, "drive.google.com") then
    log.i('opening with Firefox')
    hs.execute('open -a /Applications/Firefox.app ' .. "'" .. fullURL .. "'")
  elseif string.find(host, "docs.google.com") then
    log.i('opening with Firefox')
    hs.execute('open -a /Applications/Firefox.app ' .. "'" .. fullURL .. "'")
  elseif string.find(host, "notion.so") then
    log.i('opening with Firefox')
    hs.execute('open -a /Applications/Firefox.app ' .. "'" .. fullURL .. "'")
  elseif string.find(host, "coda.io") then
    log.i('opening with Firefox')
    hs.execute('open -a /Applications/Firefox.app ' .. "'" .. fullURL .. "'")
  elseif string.find(host, "twitch.tv") then
    log.i("opening with mpv")
    hs.execute("open -a /Applications/mpv.app " .. "'" .. fullURL .. "'")
  elseif string.find(host, "youtube.com") then
    log.i("opening with mpv")
    hs.execute("open -a /Applications/mpv.app " .. "'" .. fullURL .. "'")
  else
    log.i('opening with qutebrowser')
    hs.urlevent.openURLWithBundle(fullURL, "org.qt-project.Qt.QtWebEngineCore")
  end
end

hs.urlevent.httpCallback = urlHandler

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

hs.hotkey.bind(hyper, "h", function() return hs.window.focusedWindow():minimize() end)

hs.hints.style = 'vimperator'
hs.hotkey.bind({'alt'}, 'space', hs.hints.windowHints)

hs.hotkey.bind(hyper, "r", function() hs.reload() end)
hs.hotkey.bind(hyper, "i", function() hs.application.launchOrFocus("iTerm") end)
hs.hotkey.bind(hyper, "j", function() hs.application.launchOrFocus("qutebrowser") end)
hs.hotkey.bind(hyper, "k", function() hs.application.launchOrFocus("Firefox") end)
hs.hotkey.bind(hyper, "l", function() hs.application.launchOrFocus("Slack") end)
hs.hotkey.bind(hyper, "p", function() hs.application.launchOrFocus("Skim") end)
hs.hotkey.bind(hyper, "v", function() hs.application.launchOrFocus("mpv") end)
--hs.hotkey.bind(hyper, "c", function() hs.appfinder.windowFromWindowTitlePattern("Zoom Meeting.*"):focus() end)

hs.hotkey.bind(hyper, "`", function() hs.application.launchOrFocus("mpv") end)
-- hs.hotkey.bind(hyper, "q", function() hs.application.launchOrFocus("IntelliJ IDEA CE") end)

-- hs.hotkey.bind(hyper, ".", function() findZoomWindow() end)
hs.hotkey.bind(hyper, "'", function() hs.window.find("presentation.pdf"):focus() end)

hs.hotkey.bind(hyper, "\\", function() hs.window.frontmostWindow():minimize() end)


hs.urlevent.bind("wb", layout_work_with_browser)
hs.urlevent.bind("wp", layout_work_with_pdf)
hs.urlevent.bind("wl", layout_work_with_chat)
hs.urlevent.bind("z", layout_work_with_zoom)
hs.urlevent.bind("bl", layout_work_chat_with_browser)
hs.urlevent.bind("w", layout_default_single)
hs.urlevent.bind("zz", layout_double_zoom)


-- actionFunction = function(table)
-- end
-- c = hs.chooser.new()


hs.hotkey.bind(hyper, "c",
  function()
  -- app = hs.application.launchOrFocus("Safari")
    zoomApp = hs.appfinder.windowFromWindowTitlePattern("Zoom Meeting.*")

    safariResult = hs.osascript.applescript([[
      set searchpat to "meet.google.com"
      tell application "Safari"
        set win to front window
        set tablist to every tab of win
        repeat with t in tablist
          if searchpat is in (URL of t as string) then
            set current tab of win to t
            activate "Safari"
            return true
          end if
        end repeat
      end tell
      return false
    ]])

    -- if safariResult == true

    -- hs.eventtap.keyStroke(hyper, "a")
    hs.eventtap.keyStroke({"cmd"}, "d")
  end
)

choices = {
 {
  ["text"] = "test 1",
  ["subText"] = "test 1",
  ["uuid"] = "0001",
  ["url"] = "url"
 },
 {
  ["text"] = "test 2",
  ["subText"] = "test 2",
  ["uuid"] = "0002",
  ["url"] = "url"
 },
 {
  ["text"] = "test 3",
  ["subText"] = "test 3",
  ["uuid"] = "0003",
  ["url"] = "url"
 },
}

function chooser_selector(selection)
  url = selection["url"]
  hs.execute('open -a /Applications/Firefox.app ' .. "'" .. url .. "'")
end

function create_chooser()
  chooser = hs.chooser.new(chooser_selector)
  chooser:choices(choices)
  chooser:rows(2)
  chooser:width(20)
  chooser:bgDark(true)
  chooser:show()
end

hs.alert.show("Config loaded")


