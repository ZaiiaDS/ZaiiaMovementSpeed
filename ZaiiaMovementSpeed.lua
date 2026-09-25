--[[
    ZaiiaMovementSpeed.lua v4.5
    Requires ClassicAPI.dll (Turtle WoW 1.18.1 / API 1.12).

    Character pane shows the BASE forward run/swim speed:
        GetUnitSpeed 2nd return (runSpeed) on land,
        4th return (swimSpeed) while swimming.
        Reflects mount/buff modifiers regardless of current movement.

    Test frame shows the CURRENT movement speed:
        GetUnitSpeed 1st return (currentSpeed) -- the speed the engine
        applies to this frame's movement step. Zero while standing still.

    Uses ClassicAPI: GetUnitSpeed, C_Timer, IsSwimming, strtrim.
    Timer runs only while the main character tab is open, or while the test frame is on.
    /zms        - show saved coords
    /zms X,Y    - set coords
    /zms test   - toggle the current-speed frame
    Coords are persisted in SavedVariables.
--]]

---------------------------------------------------------------------
-- ClassicAPI presence check
---------------------------------------------------------------------
local function CheckClassicAPI()
    if not C_Timer or not C_Timer.NewTicker or not C_Timer.After then
        DEFAULT_CHAT_FRAME:AddMessage("ZaiiaMovementSpeed: ERROR - ClassicAPI (C_Timer) not found. Addon disabled.")
        return false
    end

    if type(GetUnitSpeed) ~= "function" or type(IsSwimming) ~= "function" or type(strtrim) ~= "function" then
        DEFAULT_CHAT_FRAME:AddMessage("ZaiiaMovementSpeed: ERROR - ClassicAPI (GetUnitSpeed/IsSwimming/strtrim) not found. Addon disabled.")
        return false
    end

    local _, runSpeed, _, swimSpeed = GetUnitSpeed("player")
    if not runSpeed or not swimSpeed then
        DEFAULT_CHAT_FRAME:AddMessage("ZaiiaMovementSpeed: ERROR - GetUnitSpeed does not return 4 values. Addon disabled.")
        return false
    end

    return true
end

if not CheckClassicAPI() then
    return
end

---------------------------------------------------------------------
-- Saved variables
---------------------------------------------------------------------
if not ZaiiaMovementSpeedSettings then
    ZaiiaMovementSpeedSettings = {}
end

if ZaiiaMovementSpeedSettings.offsetX == nil then
    ZaiiaMovementSpeedSettings.offsetX = 40
end
if ZaiiaMovementSpeedSettings.offsetY == nil then
    ZaiiaMovementSpeedSettings.offsetY = -240
end

---------------------------------------------------------------------
-- Locals
---------------------------------------------------------------------
local text = nil                    -- label inside the character pane
local parent = nil                  -- its container
local ticker = nil                  -- update timer handle

local testFrame = nil               -- current-speed frame
local testText = nil                -- current-speed frame label
local testFrameVisible = false      -- current-speed frame visibility

---------------------------------------------------------------------
-- Update the character pane label (base run/swim speed)
---------------------------------------------------------------------
local function UpdateSpeed()
    if not text or not PaperDollFrame or not PaperDollFrame:IsShown() then
        return
    end

    local _, runSpeed, _, swimSpeed = GetUnitSpeed("player")
    local speed = IsSwimming() and swimSpeed or runSpeed

    local percent = math.floor((speed / 7.0 * 100) * 10 + 0.5) / 10
    text:SetText(string.format("MSpeed: %.1f%%", percent))
end

---------------------------------------------------------------------
-- Update the current-speed frame (instantaneous movement, %)
---------------------------------------------------------------------
local function UpdateTestSpeed()
    if not testFrameVisible or not testText then
        return
    end

    local currentSpeed = GetUnitSpeed("player")
    local percent = math.floor((currentSpeed / 7.0 * 100) * 10 + 0.5) / 10
    testText:SetText(string.format("%.1f%%", percent))
end

---------------------------------------------------------------------
-- Create the label on the main character tab
---------------------------------------------------------------------
local function CreateDisplay()
    if text or not PaperDollFrame then
        return
    end

    local x = ZaiiaMovementSpeedSettings.offsetX or 40
    local y = ZaiiaMovementSpeedSettings.offsetY or -240

    -- Parented to PaperDollFrame -> visible only on the main tab
    parent = CreateFrame("Frame", nil, PaperDollFrame)
    parent:SetPoint("TOPLEFT", PaperDollFrame, "TOPLEFT", x, y)
    parent:SetSize(120, 30)

    text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER")
    text:SetText("MSpeed: N/A")

    UpdateSpeed()
end

---------------------------------------------------------------------
-- Create the movable current-speed frame
---------------------------------------------------------------------
local function CreateTestFrame()
    if testFrame then
        return
    end

    testFrame = CreateFrame("Frame", nil, UIParent)
    testFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    testFrame:SetSize(100, 50)
    testFrame:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true,
        tileSize = 16,
        edgeSize = 16,
        insets   = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    testFrame:SetBackdropColor(0, 0, 0, 0.5)
    testFrame:SetBackdropBorderColor(1, 1, 1, 1)
    testFrame:Hide()

    testFrame:SetMovable(true)
    testFrame:EnableMouse(true)
    testFrame:SetClampedToScreen(true)

    testFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self:StartMoving()
        end
    end)
    testFrame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            self:StopMovingOrSizing()
        end
    end)

    testText = testFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    testText:SetPoint("CENTER", testFrame, "CENTER", 0, 0)
    testText:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
    testText:SetText("0.0%")
end

---------------------------------------------------------------------
-- Timer state
---------------------------------------------------------------------
local function IsTickerNeeded()
    return (PaperDollFrame and PaperDollFrame:IsShown()) or testFrameVisible
end

local function UpdateTickerState()
    if IsTickerNeeded() then
        if not ticker then
            ticker = C_Timer.NewTicker(0.5, function()
                if text then
                    UpdateSpeed()
                end
                if testFrameVisible then
                    UpdateTestSpeed()
                end
            end)
        end
    elseif ticker then
        ticker:Cancel()
        ticker = nil
    end
end

local function OnCharacterPanelShown()
    if text then
        UpdateSpeed()
    end
    UpdateTickerState()
end

local function OnCharacterPanelHidden()
    UpdateTickerState()
end

-- PaperDollFrame exists before addons load (FrameXML loads first).
PaperDollFrame:HookScript("OnShow", OnCharacterPanelShown)
PaperDollFrame:HookScript("OnHide", OnCharacterPanelHidden)

-- In case the character tab is already open during load.
C_Timer.After(0.1, function()
    if PaperDollFrame:IsShown() then
        OnCharacterPanelShown()
    end
end)

---------------------------------------------------------------------
-- Event handling
---------------------------------------------------------------------
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

-- Positional handler args require SetModernScriptArgs (ON by default in ClassicAPI).
frame:SetScript("OnEvent", function(self, event, arg1, ...)
    if event == "ADDON_LOADED" and arg1 == "ZaiiaMovementSpeed" then
        CreateDisplay()
        CreateTestFrame()
        UpdateTickerState()
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        if not text then
            CreateDisplay()
        else
            UpdateSpeed()
        end
        if testFrameVisible then
            UpdateTestSpeed()
        end
        UpdateTickerState()
    end
end)

---------------------------------------------------------------------
-- Slash command: /zms
---------------------------------------------------------------------
local function HandleZMS(msg)
    local trimmed = msg and strtrim(msg) or ""

    if trimmed == "" then
        local x = ZaiiaMovementSpeedSettings.offsetX or 40
        local y = ZaiiaMovementSpeedSettings.offsetY or -240
        print(string.format("ZaiiaMovementSpeed coords: %.1f, %.1f", x, y))
        return
    end

    local args = {}
    for token in string.gmatch(trimmed, "[^%s]+") do
        table.insert(args, token)
    end

    if args[1]:lower() == "test" then
        testFrameVisible = not testFrameVisible
        if testFrameVisible then
            if not testFrame then
                CreateTestFrame()
            end
            testFrame:Show()
            UpdateTestSpeed()
            print("ZaiiaMovementSpeed test frame enabled.")
        else
            if testFrame then
                testFrame:Hide()
            end
            print("ZaiiaMovementSpeed test frame disabled.")
        end
        UpdateTickerState()
        return
    end

    local coordStr = table.concat(args, " ")
    local xStr, yStr = coordStr:match("^([^%s,]+)%s*,?%s*([^%s,]+)$")
    if not xStr then
        print("Usage: /zms offsetX, offsetY  (e.g. /zms 100,-40)  or /zms test")
        return
    end

    local newX = tonumber(xStr)
    local newY = tonumber(yStr)
    if not newX or not newY then
        print("Invalid numbers. Usage: /zms offsetX, offsetY (e.g. /zms 100,-40)")
        return
    end

    ZaiiaMovementSpeedSettings.offsetX = newX
    ZaiiaMovementSpeedSettings.offsetY = newY

    if parent then
        parent:ClearAllPoints()
        parent:SetPoint("TOPLEFT", PaperDollFrame, "TOPLEFT", newX, newY)
        UpdateSpeed()
    else
        CreateDisplay()
    end

    print(string.format("ZaiiaMovementSpeed coords updated to: %.1f, %.1f", newX, newY))
end

SLASH_ZMS1 = "/zms"
SlashCmdList["ZMS"] = HandleZMS