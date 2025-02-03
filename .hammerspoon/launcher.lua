
c = hs.chooser.new()


-- hs.hotkey.bind(hyper, "c",
--   function()
--   -- app = hs.application.launchOrFocus("Safari")
--     zoomApp = hs.appfinder.windowFromWindowTitlePattern("Zoom Meeting.*")
--
--     safariResult = hs.osascript.applescript([[
--       set searchpat to "meet.google.com"
--       tell application "Safari"
--         set win to front window
--         set tablist to every tab of win
--         repeat with t in tablist
--           if searchpat is in (URL of t as string) then
--             set current tab of win to t
--             activate "Safari"
--             return true
--           end if
--         end repeat
--       end tell
--       return false
--     ]])

    -- if safariResult == true

    -- hs.eventtap.keyStroke(hyper, "a")
--     hs.eventtap.keyStroke({"cmd"}, "d")
--   end
-- )

-- choices = {
--  {
--   ["text"] = "test 1",
--   ["subText"] = "test 1",
--   ["uuid"] = "0001",
--   ["url"] = "url"
--  },
--  {
--   ["text"] = "test 2",
--   ["subText"] = "test 2",
--   ["uuid"] = "0002",
--   ["url"] = "url"
--  },
--  {
--   ["text"] = "test 3",
--   ["subText"] = "test 3",
--   ["uuid"] = "0003",
--   ["url"] = "url"
--  },
-- }
--
-- function chooser_selector(selection)
--   url = selection["url"]
--   hs.execute('open -a /Applications/Firefox.app ' .. "'" .. url .. "'")
-- end
--
-- function create_chooser()
--   chooser = hs.chooser.new(chooser_selector)
--   chooser:choices(choices)
--   chooser:rows(2)
--   chooser:width(20)
--   chooser:bgDark(true)
--   chooser:show()
-- end
