require("hs.ipc")
hs.ipc.cliInstall()
hs.autoLaunch(true)

hs.accessibilityStateCallback = function()
  if hs.accessibilityState(false) then
    hs.timer.doAfter(1, function()
      hs.relaunch()
    end)
  end
end

if not hs.accessibilityState(false) then
  hs.accessibilityState(true)
end

local zedBundleID = "dev.zed.Zed"
local stateKey = "zedAgentPanelMode"
local validModes = {closed = true, open = true, fullscreen = true}
local mode = hs.settings.get(stateKey)

if not validModes[mode] then
  mode = "closed"
end

local function setMode(nextMode)
  mode = nextMode
  hs.settings.set(stateKey, mode)
end

local function zedIsFrontmost()
  local app = hs.application.frontmostApplication()
  return app and app:bundleID() == zedBundleID
end

local function press(keys, key)
  hs.eventtap.keyStroke(keys, key, 0)
end

local f2
local shiftEscape

local function sendZedF2()
  f2:disable()
  press({}, "F2")
  f2:enable()
end

local function sendZedShiftEscape()
  shiftEscape:disable()
  press({"shift"}, "escape")
  shiftEscape:enable()
end

f2 = hs.hotkey.bind({}, "F2", function()
  if not zedIsFrontmost() then
    sendZedF2()
    return
  end

  if mode == "closed" then
    sendZedF2()
    setMode("open")
  elseif mode == "open" then
    sendZedShiftEscape()
    setMode("fullscreen")
  else
    sendZedShiftEscape()
    hs.timer.doAfter(0.15, function()
      if zedIsFrontmost() then
        sendZedF2()
        setMode("closed")
      else
        setMode("open")
      end
    end)
  end
end)

shiftEscape = hs.hotkey.bind({"shift"}, "escape", function()
  if zedIsFrontmost() then
    if mode == "open" then
      setMode("fullscreen")
    elseif mode == "fullscreen" then
      setMode("open")
    end
  end

  sendZedShiftEscape()
end)

hs.hotkey.bind({"cmd", "alt"}, "F2", function()
  if zedIsFrontmost() then
    setMode("closed")
    hs.alert.show("Zed cycle reset: close Agent Panel before F2")
  end
end)
