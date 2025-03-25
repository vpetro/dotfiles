local function setup()
  hs.hints.showTitleThresh = 0
  hs.window.animationDuration = 0
  hs.grid.setMargins{0, 0}
  hs.grid.setGrid('100x100')
end

M = {}

M.browser = "qutebrowser"
M.terminal = "Alacritty"

setup()

return M
