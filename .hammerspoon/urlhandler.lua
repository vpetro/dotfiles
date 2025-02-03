
local defaultBrowser = "org.qt-project.Qt.QtWebEngineCore"
local workBrowser = "/Applications/LibreWolf.app"
local videoPlayer = "/Applications/mpv.app"

local function q(str)
  return "'" .. str .. "'"
end

M = {}


function M.handler(scheme, host, param, url)
  local qurl = q(url)
  log.i("dispatching url: " .. qurl)
  if string.find(host, "reddit.com") then
    hs.urlevent.openURLWithBundle(url, defaultBrowser)
  elseif string.find(host, 'applications.zoom.us') then
    local meetingId = string.match(url, 'https://applications.zoom.us/event/callback/slack/(.*)?.*')
    log.i('opening with zoom with meeting id: ' .. meetingId)
    if meetingId then
      hs.execute('open -a /Applications/zoom.us.app \'https://zoom.us/j/' .. meetingId .. '\'')
    end
  elseif string.find(host, "zoom.us") then
    hs.execute('open -a /Applications/zoom.us.app ' .. qurl)
  elseif string.find(host, "drive.google.com") then
    hs.execute('open -a ' .. workBrowser .. ' ' .. qurl)
  elseif string.find(host, "docs.google.com") then
    hs.execute('open -a ' .. workBrowser .. ' ' .. qurl)
  elseif string.find(host, "notion.so") then
    hs.execute('open -a ' .. workBrowser .. ' ' .. qurl)
  elseif string.find(host, "coda.io") then
    hs.execute('open -a ' .. workBrowser .. ' ' .. qurl)
  elseif string.find(host, "whimsical.com") then
    hs.execute('open -a ' .. workBrowser .. ' ' .. qurl)
  elseif string.find(host, "shortcut.com") then
    hs.execute('open -a ' .. workBrowser .. ' ' .. qurl)
  elseif string.find(host, "twitch.tv") then
    hs.execute('open -a ' .. videoPlayer .. ' ' .. qurl)
  elseif string.find(host, "youtube.com") then
    hs.execute('open -a ' .. videoPlayer .. ' ' .. qurl)
  else
    hs.urlevent.openURLWithBundle(url, defaultBrowser)
  end
end


return M
