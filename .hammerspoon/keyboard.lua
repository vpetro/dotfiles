local function hasExternalKeyboard()
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

local function bindHyper()
  if hasExternalKeyboard() then
    return {"cmd", "alt"}
  else
    return {"cmd", "ctrl"}
  end
end

M = {}

M.hyper = bindHyper()

return M
