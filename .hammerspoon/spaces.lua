-- InstantSpaceSwitcher for Hammerspoon
-- Switches macOS Spaces without animation by synthesizing Dock swipe gestures.
-- Based on https://github.com/jurplel/InstantSpaceSwitcher
--
-- Uses a bit-reinterpretation trick: since Hammerspoon's setProperty() always
-- calls CGEventSetIntegerValueField for arbitrary field IDs, we encode the
-- double's raw IEEE 754 bits as an int64. If CGEvent stores values as raw
-- 64-bit slots, the Dock reads them back as doubles correctly.

local log = hs.logger.new("spaces", "debug")

-- Reinterpret a double's bits as int64
local function doubleAsInt(d)
    return string.unpack("i8", string.pack("d", d))
end

-- Private CGEvent field IDs (undocumented)
local F = {
    CGSEventType       = 55,
    GestureHIDType     = 110,
    GestureScrollY     = 119,
    GestureSwipeMotion = 123,
    SwipeProgress      = 124,
    SwipeVelocityX     = 129,
    SwipeVelocityY     = 130,
    GesturePhase       = 132,
    ScrollFlagBits     = 135,
    GestureZoomDeltaX  = 139,
}

-- Constants
local CGS_EVENT_GESTURE      = 29
local CGS_EVENT_DOCK_CONTROL = 30
local IOHID_DOCK_SWIPE       = 23
local PHASE_BEGAN             = 1
local PHASE_ENDED             = 4
local MOTION_HORIZONTAL       = 1

-- Pre-computed double-as-int constants
local FLT_TRUE_MIN_BITS = doubleAsInt(2^-149)
local ZERO_BITS         = 0  -- IEEE 754: double 0.0 == int64 0

local function postSwitchGesture(direction)
    local isRight  = (direction == "right")
    local flagBits = isRight and 1 or 0
    local progress = doubleAsInt(isRight and 2.0 or -2.0)
    local velocity = doubleAsInt(isRight and 400.0 or -400.0)

    local newEvent = hs.eventtap.event.newEvent

    -- BEGIN phase
    local evA = newEvent()
    evA:setProperty(F.CGSEventType, CGS_EVENT_GESTURE)

    local evB = newEvent()
    evB:setProperty(F.CGSEventType,       CGS_EVENT_DOCK_CONTROL)
    evB:setProperty(F.GestureHIDType,     IOHID_DOCK_SWIPE)
    evB:setProperty(F.GesturePhase,       PHASE_BEGAN)
    evB:setProperty(F.ScrollFlagBits,     flagBits)
    evB:setProperty(F.GestureSwipeMotion, MOTION_HORIZONTAL)
    evB:setProperty(F.GestureZoomDeltaX,  FLT_TRUE_MIN_BITS)
    evB:setProperty(F.GestureScrollY,     ZERO_BITS)
    evB:setProperty(F.SwipeVelocityY,     ZERO_BITS)

    evB:post()
    evA:post()

    -- END phase
    local evA2 = newEvent()
    evA2:setProperty(F.CGSEventType, CGS_EVENT_GESTURE)

    local evB2 = newEvent()
    evB2:setProperty(F.CGSEventType,       CGS_EVENT_DOCK_CONTROL)
    evB2:setProperty(F.GestureHIDType,     IOHID_DOCK_SWIPE)
    evB2:setProperty(F.GesturePhase,       PHASE_ENDED)
    evB2:setProperty(F.ScrollFlagBits,     flagBits)
    evB2:setProperty(F.GestureSwipeMotion, MOTION_HORIZONTAL)
    evB2:setProperty(F.GestureZoomDeltaX,  FLT_TRUE_MIN_BITS)
    evB2:setProperty(F.GestureScrollY,     ZERO_BITS)
    evB2:setProperty(F.SwipeVelocityY,     ZERO_BITS)
    evB2:setProperty(F.SwipeProgress,      progress)
    evB2:setProperty(F.SwipeVelocityX,     velocity)

    evB2:post()
    evA2:post()
end

local function getScreenSpaces()
    local screen = hs.mouse.getCurrentScreen() or hs.screen.mainScreen()
    local spaces = hs.spaces.spacesForScreen(screen)
    if not spaces then return nil, nil, nil end

    -- Filter to user spaces only (exclude fullscreen app spaces)
    local userSpaces = {}
    for _, spaceId in ipairs(spaces) do
        if hs.spaces.spaceType(spaceId) == "user" then
            table.insert(userSpaces, spaceId)
        end
    end

    local currentSpace = hs.spaces.activeSpaceOnScreen(screen)
    local currentIndex = nil
    for i, spaceId in ipairs(userSpaces) do
        if spaceId == currentSpace then
            currentIndex = i
            break
        end
    end

    return userSpaces, currentIndex, screen
end

local function switchSpace(direction)
    local spaces, currentIndex, _ = getScreenSpaces()
    if not spaces or not currentIndex then
        log.w("Could not determine current space")
        return
    end

    local isRight = (direction == "right")
    if isRight and currentIndex >= #spaces then
        log.d("Already at rightmost space")
        return
    end
    if not isRight and currentIndex <= 1 then
        log.d("Already at leftmost space")
        return
    end

    postSwitchGesture(direction)
end

local function switchToIndex(targetIndex)
    local spaces, currentIndex, _ = getScreenSpaces()
    if not spaces or not currentIndex then
        log.w("Could not determine current space")
        return
    end

    if targetIndex < 1 or targetIndex > #spaces then
        log.d("Target space index " .. targetIndex .. " out of range (1-" .. #spaces .. ")")
        return
    end

    local diff = targetIndex - currentIndex
    if diff == 0 then return end

    local direction = diff > 0 and "right" or "left"
    for _ = 1, math.abs(diff) do
        postSwitchGesture(direction)
    end
end

local M = {}
M.switchSpace = switchSpace
M.switchToIndex = switchToIndex
return M
