local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Create Main Window
local Window = Rayfield:CreateWindow({
   Name = "🏔️ Mt. Seribu Auto Toggle",
   Icon = 0,
   LoadingTitle = "Mt. Seribu Controller",
   LoadingSubtitle = "by Canks",
   Theme = "Default",

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,

   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil, 
      FileName = "MtSeribu_Config"
   },

   Discord = {
      Enabled = false, 
      Invite = "noinvitelink", 
      RememberJoins = true 
   },

   KeySystem = false, 
})

-- Koordinat Mt. Seribu
local basePos = Vector3.new(873, 130, 232) -- Koordinat Base
local summitPos = Vector3.new(-3010, 1738, 385) -- Koordinat Summit

-- Config Variables
local delayTime = 5
local lastTick = tick()
local toBase = true
local HumanoidRootPart

-- Control Variables
local isRunning = false
local isPaused = false
local heartbeatConnection = nil

-- Function buat update HRP setelah respawn
local function updateHRP()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
end

-- Initial HRP
updateHRP()

-- Auto update kalau respawn
LocalPlayer.CharacterAdded:Connect(function()
    updateHRP()
end)

-- UI Elements
local MainTab = Window:CreateTab("🎮 Control")
local SettingsTab = Window:CreateTab("⚙️ Settings")

-- Status Display
local StatusLabel = MainTab:CreateLabel("📊 Status: Ready")
local CurrentPosLabel = MainTab:CreateLabel("📍 Current: Not Started")
local NextToggleLabel = MainTab:CreateLabel("⏱️ Next Toggle: -")

-- Update Status Function
local function updateStatus()
    if isRunning then
        if isPaused then
            StatusLabel:Set("📊 Status: ⏸️ Paused")
            NextToggleLabel:Set("⏱️ Next Toggle: Paused")
        else
            StatusLabel:Set("📊 Status: ▶️ Running")
            local timeLeft = delayTime - (tick() - lastTick)
            NextToggleLabel:Set("⏱️ Next Toggle: " .. math.ceil(math.max(0, timeLeft)) .. "s")
        end
        local currentLocation = toBase and "🏔️ Summit" or "🏠 Base"
        CurrentPosLabel:Set("📍 Next: " .. currentLocation)
    else
        StatusLabel:Set("📊 Status: ⏹️ Stopped")
        CurrentPosLabel:Set("📍 Current: Not Started")
        NextToggleLabel:Set("⏱️ Next Toggle: -")
    end
end

-- Start Auto Toggle Function
local function startAutoToggle()
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
    end
    
    lastTick = tick() -- Reset timer
    
    heartbeatConnection = RunService.Heartbeat:Connect(function()
        if not isPaused and isRunning and HumanoidRootPart and tick() - lastTick >= delayTime then
            if toBase then
                HumanoidRootPart.CFrame = CFrame.new(basePos)
                print("🏠 Teleported to Base")
            else
                HumanoidRootPart.CFrame = CFrame.new(summitPos)
                print("🏔️ Teleported to Summit")
            end
            toBase = not toBase
            lastTick = tick()
        end
        
        -- Update status every frame when running
        if isRunning then
            updateStatus()
        end
    end)
end

-- Stop Auto Toggle Function
local function stopAutoToggle()
    isRunning = false
    isPaused = false
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
    end
    updateStatus()
end

-- Control Section
local ControlSection = MainTab:CreateSection("🎮 Toggle Control")

-- Start Position Selection
local StartPositionDropdown = MainTab:CreateDropdown({
    Name = "🚀 Start From",
    Options = {
        "Current Position",
        "Base First", 
        "Summit First"
    },
    CurrentOption = {"Current Position"},
    MultipleOptions = false,
    Flag = "StartPositionFlag",
    Callback = function(Option)
        if not isRunning then
            if Option[1] == "Base First" then
                toBase = false -- Next teleport will go to base
                print("🏠 Will start by going to Base")
            elseif Option[1] == "Summit First" then
                toBase = true -- Next teleport will go to summit
                print("🏔️ Will start by going to Summit")
            else
                print("📍 Will start from current position")
            end
            updateStatus()
        else
            print("⚠️ Cannot change start position while running!")
        end
    end,
})

-- Play/Pause Toggle
local PlayPauseToggle = MainTab:CreateToggle({
    Name = "▶️ Play / ⏸️ Pause",
    CurrentValue = false,
    Flag = "PlayPauseToggle",
    Callback = function(Value)
        if Value then
            if not isRunning then
                -- Start new run
                isRunning = true
                isPaused = false
                print("▶️ Starting Mt. Seribu auto toggle")
                startAutoToggle()
            else
                -- Resume from pause
                isPaused = false
                print("▶️ Resuming auto toggle")
            end
        else
            if isRunning then
                -- Pause
                isPaused = true
                print("⏸️ Auto toggle paused")
            end
        end
        updateStatus()
    end,
})

-- Store reference globally for access from other functions
_G.PlayPauseToggleSeribu = PlayPauseToggle

-- Stop Button
local StopButton = MainTab:CreateButton({
    Name = "⏹️ Stop",
    Callback = function()
        stopAutoToggle()
        if _G.PlayPauseToggleSeribu and _G.PlayPauseToggleSeribu.Set then
            _G.PlayPauseToggleSeribu:Set(false)
        end
        print("⏹️ Auto toggle stopped")
    end,
})

-- Reset Timer Button
local ResetTimerButton = MainTab:CreateButton({
    Name = "🔄 Reset Timer",
    Callback = function()
        if isRunning then
            lastTick = tick()
            print("🔄 Timer reset - next toggle in " .. delayTime .. " seconds")
        else
            print("⚠️ Start the toggle first!")
        end
    end,
})

-- Instant Toggle Buttons
local InstantSection = MainTab:CreateSection("⚡ Instant Teleport")

local TeleportBaseButton = MainTab:CreateButton({
    Name = "🏠 Instant Base",
    Callback = function()
        if HumanoidRootPart then
            HumanoidRootPart.CFrame = CFrame.new(basePos)
            print("🏠 Instantly teleported to Base")
            if isRunning then
                toBase = false -- Next auto toggle will go to summit
                lastTick = tick() -- Reset timer
            end
        end
    end,
})

local TeleportSummitButton = MainTab:CreateButton({
    Name = "🏔️ Instant Summit",
    Callback = function()
        if HumanoidRootPart then
            HumanoidRootPart.CFrame = CFrame.new(summitPos)
            print("🏔️ Instantly teleported to Summit")
            if isRunning then
                toBase = true -- Next auto toggle will go to base
                lastTick = tick() -- Reset timer
            end
        end
    end,
})

-- Settings Section
local ConfigSection = SettingsTab:CreateSection("⚙️ Toggle Settings")

-- Delay Time Slider
local DelaySlider = SettingsTab:CreateSlider({
    Name = "⏱️ Toggle Delay",
    Range = {1, 30},
    Increment = 0.5,
    Suffix = " seconds",
    CurrentValue = 5,
    Flag = "DelaySlider",
    Callback = function(Value)
        delayTime = Value
        print("⏱️ Toggle delay set to " .. Value .. " seconds")
    end,
})

-- Coordinate Settings
local CoordSection = SettingsTab:CreateSection("📍 Coordinates")

SettingsTab:CreateParagraph({
    Title = "🏠 Base Coordinates",
    Content = "X: " .. basePos.X .. "\nY: " .. basePos.Y .. "\nZ: " .. basePos.Z
})

SettingsTab:CreateParagraph({
    Title = "🏔️ Summit Coordinates", 
    Content = "X: " .. summitPos.X .. "\nY: " .. summitPos.Y .. "\nZ: " .. summitPos.Z
})

-- Custom Coordinate Input (Advanced)
local CustomSection = SettingsTab:CreateSection("🔧 Custom Coordinates")

local BaseXInput = SettingsTab:CreateInput({
    Name = "🏠 Base X",
    PlaceholderText = tostring(basePos.X),
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local newX = tonumber(Text)
        if newX then
            basePos = Vector3.new(newX, basePos.Y, basePos.Z)
            print("🏠 Base X set to: " .. newX)
        end
    end,
})

local BaseYInput = SettingsTab:CreateInput({
    Name = "🏠 Base Y",
    PlaceholderText = tostring(basePos.Y),
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local newY = tonumber(Text)
        if newY then
            basePos = Vector3.new(basePos.X, newY, basePos.Z)
            print("🏠 Base Y set to: " .. newY)
        end
    end,
})

local BaseZInput = SettingsTab:CreateInput({
    Name = "🏠 Base Z",
    PlaceholderText = tostring(basePos.Z),
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local newZ = tonumber(Text)
        if newZ then
            basePos = Vector3.new(basePos.X, basePos.Y, newZ)
            print("🏠 Base Z set to: " .. newZ)
        end
    end,
})

local SummitXInput = SettingsTab:CreateInput({
    Name = "🏔️ Summit X",
    PlaceholderText = tostring(summitPos.X),
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local newX = tonumber(Text)
        if newX then
            summitPos = Vector3.new(newX, summitPos.Y, summitPos.Z)
            print("🏔️ Summit X set to: " .. newX)
        end
    end,
})

local SummitYInput = SettingsTab:CreateInput({
    Name = "🏔️ Summit Y",
    PlaceholderText = tostring(summitPos.Y),
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local newY = tonumber(Text)
        if newY then
            summitPos = Vector3.new(summitPos.X, newY, summitPos.Z)
            print("🏔️ Summit Y set to: " .. newY)
        end
    end,
})

local SummitZInput = SettingsTab:CreateInput({
    Name = "🏔️ Summit Z",
    PlaceholderText = tostring(summitPos.Z),
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local newZ = tonumber(Text)
        if newZ then
            summitPos = Vector3.new(summitPos.X, summitPos.Y, newZ)
            print("🏔️ Summit Z set to: " .. newZ)
        end
    end,
})

-- Info Tab
local InfoTab = Window:CreateTab("ℹ️ Info")
local InfoSection = InfoTab:CreateSection("📖 Instructions")

InfoTab:CreateParagraph({
    Title = "🎮 How to Use",
    Content = "1. Choose start position (Base/Summit/Current)\n2. Set toggle delay in Settings\n3. Click Play to start auto toggling\n4. Use Pause to temporarily stop\n5. Use Stop to completely halt"
})

InfoTab:CreateParagraph({
    Title = "⚡ Instant Controls",
    Content = "• Instant Base: Teleport to base immediately\n• Instant Summit: Teleport to summit immediately\n• Reset Timer: Reset countdown to next toggle\n• Both instant buttons also reset the auto timer"
})

InfoTab:CreateParagraph({
    Title = "⚙️ Settings Guide",
    Content = "• Toggle Delay: Time between base/summit switches\n• Custom Coordinates: Modify base/summit positions\n• Start Position: Choose first teleport destination"
})

InfoTab:CreateParagraph({
    Title = "📊 Status Information",
    Content = "• Status: Shows if running/paused/stopped\n• Next: Shows next teleport destination\n• Timer: Countdown to next auto toggle"
})

-- Initialize
updateStatus()

-- Cleanup on player leave
LocalPlayer.AncestryChanged:Connect(function()
    if not LocalPlayer.Parent then
        stopAutoToggle()
    end
end)

-- Load Configuration
Rayfield:LoadConfiguration()

print("🏔️ Mt. Seribu Auto Toggle loaded successfully!")
print("🎮 Use the GUI to control your toggle!")