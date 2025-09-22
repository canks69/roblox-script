local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Create Main Window
local Window = Rayfield:CreateWindow({
   Name = "♾️ Infinity Refresh",
   Icon = 0,
   LoadingTitle = "Infinity Refresh Controller",
   LoadingSubtitle = "by Canks",
   Theme = "Default",

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,

   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil, 
      FileName = "InfinityRefresh_Config"
   },

   Discord = {
      Enabled = false, 
      Invite = "noinvitelink", 
      RememberJoins = true 
   },

   KeySystem = false, 
})

-- Variables
local isRefreshing = false
local refreshInterval = 30 -- seconds
local refreshCount = 0
local refreshLoop = nil
local startTime = nil
local autoTeleport = true
local targetPosition = Vector3.new(-281, 543, 671)

-- Current Game Info
local gameId = game.PlaceId
local jobId = game.JobId

-- UI Elements
local MainTab = Window:CreateTab("♾️ Main")
local SettingsTab = Window:CreateTab("⚙️ Settings")
local InfoTab = Window:CreateTab("ℹ️ Info")

-- Status Display
local StatusLabel = MainTab:CreateLabel("📊 Status: Ready")
local RefreshCountLabel = MainTab:CreateLabel("🔄 Refreshes: 0")
local UptimeLabel = MainTab:CreateLabel("⏱️ Uptime: 00:00:00")
local PositionLabel = MainTab:CreateLabel("📍 Position: Checking...")

-- Update Status Function
local function updateStatus()
    if isRefreshing then
        StatusLabel:Set("📊 Status: ♾️ Auto Refreshing")
    else
        StatusLabel:Set("📊 Status: ⏹️ Stopped")
    end
    
    RefreshCountLabel:Set("🔄 Refreshes: " .. refreshCount)
    
    if startTime then
        local elapsed = math.floor(tick() - startTime)
        local hours = math.floor(elapsed / 3600)
        local minutes = math.floor((elapsed % 3600) / 60)
        local seconds = elapsed % 60
        UptimeLabel:Set(string.format("⏱️ Uptime: %02d:%02d:%02d", hours, minutes, seconds))
    else
        UptimeLabel:Set("⏱️ Uptime: 00:00:00")
    end
    
    -- Update position status
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local currentPos = LocalPlayer.Character.HumanoidRootPart.Position
        local distance = (currentPos - targetPosition).Magnitude
        if distance <= 5 then
            PositionLabel:Set("📍 Position: ✅ At Target")
        else
            PositionLabel:Set(string.format("📍 Position: ⚠️ %.1f studs away", distance))
        end
    else
        PositionLabel:Set("📍 Position: ❌ Character not found")
    end
end

-- Teleport to Position Function
local function teleportToPosition()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(targetPosition)
        print("📍 Teleported to position: " .. tostring(targetPosition))
        return true
    else
        print("⚠️ Character or HumanoidRootPart not found!")
        return false
    end
end

-- Check if player is at target position
local function isAtTargetPosition()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local currentPos = LocalPlayer.Character.HumanoidRootPart.Position
        local distance = (currentPos - targetPosition).Magnitude
        return distance <= 5 -- Within 5 studs tolerance
    end
    return false
end

-- Refresh Function
local function refreshServer()
    print("🔄 Preparing to refresh server...")
    
    -- Ensure player is at target position before refresh
    if autoTeleport then
        if not isAtTargetPosition() then
            print("📍 Moving to target position before refresh...")
            if not teleportToPosition() then
                print("⚠️ Failed to teleport, refreshing anyway...")
            else
                task.wait(1) -- Give a moment for position to stabilize
            end
        else
            print("✅ Already at target position")
        end
    end
    
    refreshCount = refreshCount + 1
    updateStatus()
    
    -- Attempt to rejoin the same server first
    if jobId and jobId ~= "" then
        print("📡 Attempting to rejoin current server...")
        local success, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(gameId, jobId, LocalPlayer)
        end)
        
        if not success then
            print("⚠️ Failed to rejoin same server, finding new server...")
            task.wait(2)
            TeleportService:Teleport(gameId, LocalPlayer)
        end
    else
        print("🌐 Finding new server...")
        TeleportService:Teleport(gameId, LocalPlayer)
    end
end

-- Start Refresh Loop
local function startRefreshLoop()
    if refreshLoop then
        task.cancel(refreshLoop)
    end
    
    isRefreshing = true
    startTime = tick()
    updateStatus()
    
    refreshLoop = task.spawn(function()
        while isRefreshing do
            print("⏳ Waiting " .. refreshInterval .. " seconds until next refresh...")
            
            for i = refreshInterval, 1, -1 do
                if not isRefreshing then break end
                updateStatus()
                task.wait(1)
            end
            
            if isRefreshing then
                refreshServer()
            end
        end
    end)
    
    print("♾️ Infinity refresh started! Interval: " .. refreshInterval .. " seconds")
end

-- Stop Refresh Loop
local function stopRefreshLoop()
    isRefreshing = false
    if refreshLoop then
        task.cancel(refreshLoop)
        refreshLoop = nil
    end
    updateStatus()
    print("⏹️ Infinity refresh stopped")
end

-- Control Section
local ControlSection = MainTab:CreateSection("🎮 Refresh Control")

-- Teleport to Position Button
local TeleportButton = MainTab:CreateButton({
    Name = "📍 Teleport to Position",
    Callback = function()
        teleportToPosition()
    end,
})

-- Start/Stop Toggle
local RefreshToggle = MainTab:CreateToggle({
    Name = "♾️ Start Infinity Refresh",
    CurrentValue = false,
    Flag = "RefreshToggle",
    Callback = function(Value)
        if Value then
            startRefreshLoop()
        else
            stopRefreshLoop()
        end
    end,
})

-- Manual Refresh Button
local ManualRefreshButton = MainTab:CreateButton({
    Name = "🔄 Manual Refresh Now",
    Callback = function()
        refreshServer()
    end,
})

-- Reset Counter Button
local ResetButton = MainTab:CreateButton({
    Name = "🔄 Reset Counter",
    Callback = function()
        refreshCount = 0
        startTime = tick()
        updateStatus()
        print("🔄 Counter reset")
    end,
})

-- Settings Section
local ConfigSection = SettingsTab:CreateSection("⚙️ Refresh Settings")

-- Refresh Interval Slider
local IntervalSlider = SettingsTab:CreateSlider({
    Name = "⏱️ Refresh Interval",
    Range = {5, 300},
    Increment = 5,
    Suffix = " seconds",
    CurrentValue = 30,
    Flag = "IntervalSlider",
    Callback = function(Value)
        refreshInterval = Value
        print("⏱️ Refresh interval set to " .. Value .. " seconds")
    end,
})

-- Quick Interval Buttons
local QuickSection = SettingsTab:CreateSection("⚡ Quick Intervals")

local Interval30Button = SettingsTab:CreateButton({
    Name = "🕐 30 Seconds",
    Callback = function()
        refreshInterval = 30
        IntervalSlider:Set(30)
        print("⏱️ Interval set to 30 seconds")
    end,
})

local Interval60Button = SettingsTab:CreateButton({
    Name = "🕑 1 Minute",
    Callback = function()
        refreshInterval = 60
        IntervalSlider:Set(60)
        print("⏱️ Interval set to 1 minute")
    end,
})

local Interval300Button = SettingsTab:CreateButton({
    Name = "🕕 5 Minutes",
    Callback = function()
        refreshInterval = 300
        IntervalSlider:Set(300)
        print("⏱️ Interval set to 5 minutes")
    end,
})

-- Advanced Options
local AdvancedSection = SettingsTab:CreateSection("🔧 Advanced Options")

-- Auto Teleport Toggle
local AutoTeleportToggle = SettingsTab:CreateToggle({
    Name = "📍 Auto Teleport Before Refresh",
    CurrentValue = true,
    Flag = "AutoTeleportToggle",
    Callback = function(Value)
        autoTeleport = Value
        if Value then
            print("📍 Auto teleport enabled")
        else
            print("📍 Auto teleport disabled")
        end
    end,
})

-- Position Display
local PositionSection = SettingsTab:CreateSection("📍 Target Position")
local TargetPosLabel = SettingsTab:CreateLabel("🎯 Target: (-281, 543, 671)")

-- Position Input Fields
local XInput = SettingsTab:CreateInput({
    Name = "📍 X Coordinate",
    PlaceholderText = "-281",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local newX = tonumber(Text)
        if newX then
            targetPosition = Vector3.new(newX, targetPosition.Y, targetPosition.Z)
            TargetPosLabel:Set(string.format("🎯 Target: (%.0f, %.0f, %.0f)", targetPosition.X, targetPosition.Y, targetPosition.Z))
            print("📍 X coordinate set to: " .. newX)
        else
            print("⚠️ Invalid X coordinate!")
        end
    end,
})

local YInput = SettingsTab:CreateInput({
    Name = "📍 Y Coordinate",
    PlaceholderText = "543",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local newY = tonumber(Text)
        if newY then
            targetPosition = Vector3.new(targetPosition.X, newY, targetPosition.Z)
            TargetPosLabel:Set(string.format("🎯 Target: (%.0f, %.0f, %.0f)", targetPosition.X, targetPosition.Y, targetPosition.Z))
            print("📍 Y coordinate set to: " .. newY)
        else
            print("⚠️ Invalid Y coordinate!")
        end
    end,
})

local ZInput = SettingsTab:CreateInput({
    Name = "📍 Z Coordinate",
    PlaceholderText = "671",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local newZ = tonumber(Text)
        if newZ then
            targetPosition = Vector3.new(targetPosition.X, targetPosition.Y, newZ)
            TargetPosLabel:Set(string.format("🎯 Target: (%.0f, %.0f, %.0f)", targetPosition.X, targetPosition.Y, targetPosition.Z))
            print("📍 Z coordinate set to: " .. newZ)
        else
            print("⚠️ Invalid Z coordinate!")
        end
    end,
})

-- Quick Position Presets
local PresetsSection = SettingsTab:CreateSection("⚡ Position Presets")

local DefaultPosButton = SettingsTab:CreateButton({
    Name = "🏔️ Default Position",
    Callback = function()
        targetPosition = Vector3.new(-281, 543, 671)
        TargetPosLabel:Set("🎯 Target: (-281, 543, 671)")
        XInput:Set("-281")
        YInput:Set("543")
        ZInput:Set("671")
        print("📍 Position reset to default: (-281, 543, 671)")
    end,
})

local CurrentPosButton = SettingsTab:CreateButton({
    Name = "📍 Use Current Position",
    Callback = function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local currentPos = LocalPlayer.Character.HumanoidRootPart.Position
            targetPosition = Vector3.new(
                math.floor(currentPos.X + 0.5),
                math.floor(currentPos.Y + 0.5),
                math.floor(currentPos.Z + 0.5)
            )
            TargetPosLabel:Set(string.format("🎯 Target: (%.0f, %.0f, %.0f)", targetPosition.X, targetPosition.Y, targetPosition.Z))
            XInput:Set(tostring(targetPosition.X))
            YInput:Set(tostring(targetPosition.Y))
            ZInput:Set(tostring(targetPosition.Z))
            print("📍 Target position set to current position: " .. tostring(targetPosition))
        else
            print("⚠️ Character not found!")
        end
    end,
})

-- Server Info Display
local ServerInfoLabel = SettingsTab:CreateLabel("🌐 Server: " .. (jobId or "Unknown"))
local PlaceInfoLabel = SettingsTab:CreateLabel("🎮 Place ID: " .. gameId)

-- Copy Server Info Button
local CopyServerButton = SettingsTab:CreateButton({
    Name = "📋 Copy Server Info",
    Callback = function()
        local serverInfo = "Place ID: " .. gameId .. "\nJob ID: " .. (jobId or "Unknown")
        if setclipboard then
            setclipboard(serverInfo)
            print("📋 Server info copied to clipboard!")
        else
            print("📋 Clipboard not available")
            print(serverInfo)
        end
    end,
})

-- Emergency Stop
local EmergencySection = SettingsTab:CreateSection("🚨 Emergency")

local EmergencyStopButton = SettingsTab:CreateButton({
    Name = "🚨 Emergency Stop",
    Callback = function()
        stopRefreshLoop()
        if RefreshToggle and RefreshToggle.Set then
            RefreshToggle:Set(false)
        end
        print("🚨 Emergency stop activated!")
    end,
})

-- Info Tab
local InfoSection = InfoTab:CreateSection("📖 Instructions")

InfoTab:CreateParagraph({
    Title = "🎮 How to Use",
    Content = "1. Set your desired refresh interval\n2. Customize target position using X, Y, Z inputs\n3. Enable/disable auto teleport as needed\n4. Click 'Start Infinity Refresh'\n5. Script will teleport to your target position before each refresh\n6. Use 'Stop' to pause or 'Emergency Stop' for immediate halt"
})

InfoTab:CreateParagraph({
    Title = "⚙️ Settings Guide",
    Content = "• Refresh Interval: Time between automatic refreshes\n• Position Inputs: Set custom X, Y, Z coordinates\n• Position Presets: Quick buttons for common positions\n• Auto Teleport: Moves to target position before refresh\n• Manual Refresh: Instant server refresh\n• Reset Counter: Reset refresh count and uptime"
})

InfoTab:CreateParagraph({
    Title = "🔧 Advanced Features",
    Content = "• Custom Positioning: Edit coordinates directly in GUI\n• Current Position: Use your current location as target\n• Position Monitoring: Shows distance from target\n• Server Rejoin: Attempts to rejoin same server first\n• Fallback: Finds new server if rejoin fails\n• Uptime Tracking: Shows how long script has been running"
})

InfoTab:CreateParagraph({
    Title = "⚠️ Important Notes",
    Content = "• Default position: (-281, 543, 671)\n• Enter valid numbers for coordinates\n• Use 'Current Position' to capture your location\n• 'Default Position' resets to original coordinates\n• Use reasonable intervals to avoid being flagged\n• Script saves your settings automatically"
})

-- Update loop for uptime
local updateLoop = RunService.Heartbeat:Connect(function()
    if isRefreshing and startTime then
        updateStatus()
    end
end)

-- Cleanup on player leave
LocalPlayer.AncestryChanged:Connect(function()
    if not LocalPlayer.Parent then
        stopRefreshLoop()
        if updateLoop then
            updateLoop:Disconnect()
        end
    end
end)

-- Initialize
updateStatus()

-- Load Configuration
Rayfield:LoadConfiguration()

print("♾️ Infinity Refresh loaded successfully!")
print("🎮 Current Place ID: " .. gameId)
print("🌐 Current Job ID: " .. (jobId or "Unknown"))
print("⚙️ Use the GUI to control auto refresh!")
