-- Auto Teleport Timer Script
-- Teleport ke koordinat tertentu setiap 60 detik

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- ====== KONFIGURASI ======
local MOVEMENT_CONFIG = {
    startPosition = Vector3.new(-792, 804, 1788),  -- Teleport pertama
    waypoints = {
        Vector3.new(-794, 804, 1778),  -- Waypoint 1
        Vector3.new(-814, 804, 1765),  -- Waypoint 2
        Vector3.new(-845, 807, 1762),  -- Waypoint 3
        Vector3.new(-863, 808, 1769),  -- Waypoint 4
        Vector3.new(-857, 808, 1761),   -- Waypoint 5
        Vector3.new(-863, 806, 1787)   -- Final destination (base)
    },
    intervalSeconds = 180,
    enabled = false,
    lastRunTime = 0,
    currentWaypoint = 0,
    isRunning = false,
    walkSpeed = 16,
    runSpeed = 25,
    autoRespawn = true,  -- Respawn otomatis setelah mencapai base
    respawnDelay = 5,    -- Delay sebelum respawn (detik)
    showCountdown = true, -- Show/hide countdown popup
    countdownPosition = "TopCenter" -- Position of countdown popup
}

-- ====== VARIABLES ======
local character, humanoid, rootPart
local teleportConnection
local startTime = tick()

-- ====== COUNTDOWN POPUP VARIABLES ======
local countdownGui = nil
local countdownFrame = nil
local countdownLabel = nil
local countdownConnection = nil

-- ====== UTILITY FUNCTIONS ======
function InitializeCharacter()
    character = player.Character or player.CharacterAdded:Wait()
    humanoid = character:WaitForChild("Humanoid", 10)
    rootPart = character:WaitForChild("HumanoidRootPart", 10)
    
    return humanoid and rootPart
end

function TeleportToPosition(position)
    if not rootPart then
        if not InitializeCharacter() then
            return false
        end
    end
    
    local success, err = pcall(function()
        rootPart.CFrame = CFrame.new(position)
    end)
    
    if success then
        return true
    else
        return false
    end
end

function MoveToPosition(targetPosition)
    if not rootPart or not humanoid then
        if not InitializeCharacter() then
            return false
        end
    end
    
    -- Set movement speed
    humanoid.WalkSpeed = MOVEMENT_CONFIG.runSpeed
    
    -- Move to position
    local success, err = pcall(function()
        humanoid:MoveTo(targetPosition)
        humanoid.MoveToFinished:Wait()
    end)
    
    if success then
        return true
    else
        return false
    end
end

function FormatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d", mins, secs)
end

function GetNextSequenceIn()
    local elapsed = tick() - MOVEMENT_CONFIG.lastRunTime
    local remaining = MOVEMENT_CONFIG.intervalSeconds - elapsed
    return math.max(0, remaining)
end

-- Perform character respawn
function PerformRespawn()
    local success, err = pcall(function()
        if character and character.Parent then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                -- Method 1: Reset character health to 0
                humanoid.Health = 0
                return true
            end
        end
        
        -- Method 2: LoadCharacter (alternative method)
        if player then
            player:LoadCharacter()
            return true
        end
        
        return false
    end)
    
    return success
end

-- ====== MAIN SEQUENCE MOVEMENT SYSTEM ======
function RunSequence()
    if MOVEMENT_CONFIG.isRunning then
        return false
    end
    
    MOVEMENT_CONFIG.isRunning = true
    MOVEMENT_CONFIG.currentWaypoint = 0
    
    -- Initialize character
    if not InitializeCharacter() then
        MOVEMENT_CONFIG.isRunning = false
        if Rayfield then
            Rayfield:Notify({
                Title = "❌ Error",
                Content = "Failed to initialize character!",
                Duration = 3,
                Image = 4483362458
            })
        end
        return false
    end
    
    -- Step 1: Teleport to start position
    if not TeleportToPosition(MOVEMENT_CONFIG.startPosition) then
        MOVEMENT_CONFIG.isRunning = false
        if Rayfield then
            Rayfield:Notify({
                Title = "❌ Teleport Failed",
                Content = "Could not teleport to start position!",
                Duration = 3,
                Image = 4483362458
            })
        end
        return false
    end
    
    if Rayfield then
        Rayfield:Notify({
            Title = "📍 Teleported",
            Content = "Starting movement sequence...",
            Duration = 2,
            Image = 4483362458
        })
    end
    
    task.wait(1) -- Wait 1 second after teleport
    
    -- Step 2: Move through all waypoints
    for i, waypoint in ipairs(MOVEMENT_CONFIG.waypoints) do
        if not MOVEMENT_CONFIG.enabled then
            break
        end
        
        MOVEMENT_CONFIG.currentWaypoint = i
        
        if not MoveToPosition(waypoint) then
            MOVEMENT_CONFIG.isRunning = false
            if Rayfield then
                Rayfield:Notify({
                    Title = "❌ Movement Failed",
                    Content = "Failed at waypoint " .. i,
                    Duration = 3,
                    Image = 4483362458
                })
            end
            return false
        end
        
        -- Check if this is the final waypoint (base)
        if i == #MOVEMENT_CONFIG.waypoints then
            if MOVEMENT_CONFIG.autoRespawn then
                if Rayfield then
                    Rayfield:Notify({
                        Title = "🏠 Reached Base",
                        Content = "Respawning in " .. MOVEMENT_CONFIG.respawnDelay .. " seconds...",
                        Duration = MOVEMENT_CONFIG.respawnDelay,
                        Image = 4483362458
                    })
                end
                
                task.wait(MOVEMENT_CONFIG.respawnDelay) -- Wait before respawn
                
                -- Perform respawn
                PerformRespawn()
                
                task.wait(3) -- Wait for respawn to complete and character to load
            else
                if Rayfield then
                    Rayfield:Notify({
                        Title = "🏠 Reached Base",
                        Content = "Auto respawn is disabled",
                        Duration = 2,
                        Image = 4483362458
                    })
                end
                task.wait(1) -- Small delay
            end
        else
            task.wait(0.5) -- Small delay between waypoints
        end
    end
    
    MOVEMENT_CONFIG.isRunning = false
    MOVEMENT_CONFIG.lastRunTime = tick()
    
    if Rayfield then
        Rayfield:Notify({
            Title = "✅ Sequence Complete",
            Content = "Respawned and ready for next cycle!",
            Duration = 2,
            Image = 4483362458
        })
    end
    
    return true
end

function StartAutoTeleport()
    if MOVEMENT_CONFIG.enabled then
        return
    end
    
    MOVEMENT_CONFIG.enabled = true
    MOVEMENT_CONFIG.lastRunTime = tick()
    startTime = tick()
    
    -- Connect to heartbeat for timer
    teleportConnection = RunService.Heartbeat:Connect(function()
        if not MOVEMENT_CONFIG.enabled then
            return
        end
        
        -- Check if it's time to run sequence
        local currentTime = tick()
        local timeSinceLastRun = currentTime - MOVEMENT_CONFIG.lastRunTime
        
        if timeSinceLastRun >= MOVEMENT_CONFIG.intervalSeconds and not MOVEMENT_CONFIG.isRunning then
            -- Reinitialize character if needed (respawn handling)
            if not rootPart or not rootPart.Parent then
                InitializeCharacter()
            end
            
            -- Run the full sequence
            task.spawn(function()
                if RunSequence() then
                    MOVEMENT_CONFIG.lastRunTime = currentTime
                end
            end)
        end
    end)
end

function StopAutoTeleport()
    MOVEMENT_CONFIG.enabled = false
    MOVEMENT_CONFIG.isRunning = false
    
    if teleportConnection then
        teleportConnection:Disconnect()
        teleportConnection = nil
    end
    
end

function GetStatus()
    if not MOVEMENT_CONFIG.enabled then
        return "⏹️ Stopped"
    end
    
    if MOVEMENT_CONFIG.isRunning then
        return string.format("🏃 Running Sequence | Waypoint: %d/%d", 
                            MOVEMENT_CONFIG.currentWaypoint, #MOVEMENT_CONFIG.waypoints)
    end
    
    local nextIn = GetNextSequenceIn()
    local totalTime = tick() - startTime
    
    return string.format("▶️ Waiting | Next in: %s | Total time: %s", 
                        FormatTime(math.ceil(nextIn)), 
                        FormatTime(math.floor(totalTime)))
end

-- Run sequence immediately
function RunSequenceNow()
    RunSequence()
end

-- Teleport to start position immediately
function TeleportNow()
    if TeleportToPosition(MOVEMENT_CONFIG.startPosition) then
        print("🚀 Teleported to start position")
        return true
    else
        warn("❌ Failed to teleport to start position")
        return false
    end
end

-- Set start position
function SetStartPosition(x, y, z)
    MOVEMENT_CONFIG.startPosition = Vector3.new(x, y, z)
    print("📍 Start position updated to: " .. tostring(MOVEMENT_CONFIG.startPosition))
end

-- ====== COUNTDOWN POPUP FUNCTIONS ======
function CreateCountdownGUI()
    -- Remove existing GUI if it exists
    if countdownGui then
        countdownGui:Destroy()
    end
    
    -- Create ScreenGui
    countdownGui = Instance.new("ScreenGui")
    countdownGui.Name = "CountdownGUI"
    countdownGui.ResetOnSpawn = false
    countdownGui.Parent = player:WaitForChild("PlayerGui")
    
    -- Create main frame
    countdownFrame = Instance.new("Frame")
    countdownFrame.Name = "CountdownFrame"
    countdownFrame.Size = UDim2.new(0, 200, 0, 80)
    countdownFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    countdownFrame.BackgroundTransparency = 0.1
    countdownFrame.BorderSizePixel = 0
    countdownFrame.Parent = countdownGui
    
    -- Position based on config
    if MOVEMENT_CONFIG.countdownPosition == "TopCenter" then
        countdownFrame.Position = UDim2.new(0.5, -100, 0, 10)
    elseif MOVEMENT_CONFIG.countdownPosition == "TopLeft" then
        countdownFrame.Position = UDim2.new(0, 10, 0, 10)
    elseif MOVEMENT_CONFIG.countdownPosition == "TopRight" then
        countdownFrame.Position = UDim2.new(1, -210, 0, 10)
    elseif MOVEMENT_CONFIG.countdownPosition == "Center" then
        countdownFrame.Position = UDim2.new(0.5, -100, 0.5, -40)
    else
        countdownFrame.Position = UDim2.new(0.5, -100, 0, 10)
    end
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = countdownFrame
    
    -- Add stroke/border
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 162, 255)
    stroke.Thickness = 2
    stroke.Parent = countdownFrame
    
    -- Title label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -25, 0, 20)
    titleLabel.Position = UDim2.new(0, 5, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🚀 Auto Movement"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = countdownFrame
    
    -- Countdown label (main display)
    countdownLabel = Instance.new("TextLabel")
    countdownLabel.Name = "CountdownLabel"
    countdownLabel.Size = UDim2.new(1, -10, 0, 30)
    countdownLabel.Position = UDim2.new(0, 5, 0, 20)
    countdownLabel.BackgroundTransparency = 1
    countdownLabel.Text = "Next: 00:00"
    countdownLabel.TextColor3 = Color3.fromRGB(0, 255, 127)
    countdownLabel.TextScaled = true
    countdownLabel.Font = Enum.Font.GothamBold
    countdownLabel.Parent = countdownFrame
    
    -- Progress bar background
    local progressBg = Instance.new("Frame")
    progressBg.Name = "ProgressBackground"
    progressBg.Size = UDim2.new(1, -20, 0, 3)
    progressBg.Position = UDim2.new(0, 10, 0, 55)
    progressBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    progressBg.BorderSizePixel = 0
    progressBg.Parent = countdownFrame
    
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 2)
    progressCorner.Parent = progressBg
    
    -- Progress bar fill
    local progressFill = Instance.new("Frame")
    progressFill.Name = "ProgressFill"
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.Position = UDim2.new(0, 0, 0, 0)
    progressFill.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
    progressFill.BorderSizePixel = 0
    progressFill.Parent = progressBg
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 2)
    fillCorner.Parent = progressFill
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 15, 0, 15)
    closeButton.Position = UDim2.new(1, -18, 0, 3)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
    closeButton.Text = "×"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = countdownFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeButton
    
    -- Close button functionality
    closeButton.MouseButton1Click:Connect(function()
        HideCountdownPopup()
    end)
    
    -- Make frame draggable
    local dragToggle = nil
    local dragSpeed = 0.25
    local dragStart = nil
    local startPos = nil
    
    local function updateInput(input)
        local delta = input.Position - dragStart
        local position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        game:GetService('TweenService'):Create(countdownFrame, TweenInfo.new(dragSpeed), {Position = position}):Play()
    end
    
    countdownFrame.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragToggle = true
            dragStart = input.Position
            startPos = countdownFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragToggle = false
                end
            end)
        end
    end)
    
    countdownFrame.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            if dragToggle then
                updateInput(input)
            end
        end
    end)
    
    return statusLabel, progressFill
end

function UpdateCountdownDisplay()
    if not countdownGui or not countdownLabel or not MOVEMENT_CONFIG.showCountdown then
        return
    end
    
    local progressFill = countdownGui.CountdownFrame.ProgressBackground:FindFirstChild("ProgressFill")
    
    if MOVEMENT_CONFIG.isRunning then
        countdownLabel.Text = string.format("Running %d/%d", MOVEMENT_CONFIG.currentWaypoint, #MOVEMENT_CONFIG.waypoints)
        countdownLabel.TextColor3 = Color3.fromRGB(255, 165, 0) -- Orange
        progressFill.Size = UDim2.new(1, 0, 1, 0)
        progressFill.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
    elseif not MOVEMENT_CONFIG.enabled then
        countdownLabel.Text = "Stopped"
        countdownLabel.TextColor3 = Color3.fromRGB(255, 85, 85) -- Red
        progressFill.Size = UDim2.new(0, 0, 1, 0)
    else
        local nextIn = GetNextSequenceIn()
        local progress = 1 - (nextIn / MOVEMENT_CONFIG.intervalSeconds)
        
        countdownLabel.Text = string.format("Next: %s", FormatTime(math.ceil(nextIn)))
        countdownLabel.TextColor3 = Color3.fromRGB(0, 255, 127) -- Green
        
        -- Animate progress bar
        game:GetService('TweenService'):Create(progressFill, TweenInfo.new(0.5), {
            Size = UDim2.new(math.max(0, progress), 0, 1, 0)
        }):Play()
        
        -- Change color as countdown gets closer
        if nextIn <= 10 then
            countdownLabel.TextColor3 = Color3.fromRGB(255, 85, 85) -- Red
            progressFill.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
        elseif nextIn <= 30 then
            countdownLabel.TextColor3 = Color3.fromRGB(255, 165, 0) -- Orange
            progressFill.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
        else
            countdownLabel.TextColor3 = Color3.fromRGB(0, 255, 127) -- Green
            progressFill.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
        end
    end
end

function ShowCountdownPopup()
    MOVEMENT_CONFIG.showCountdown = true
    if not countdownGui then
        CreateCountdownGUI()
    else
        countdownGui.Enabled = true
    end
    
    -- Start update loop
    if countdownConnection then
        countdownConnection:Disconnect()
    end
    
    countdownConnection = RunService.Heartbeat:Connect(function()
        if MOVEMENT_CONFIG.showCountdown then
            UpdateCountdownDisplay()
        end
    end)
end

function HideCountdownPopup()
    MOVEMENT_CONFIG.showCountdown = false
    if countdownGui then
        countdownGui.Enabled = false
    end
    
    if countdownConnection then
        countdownConnection:Disconnect()
        countdownConnection = nil
    end
end

function ToggleCountdownPopup()
    if MOVEMENT_CONFIG.showCountdown then
        HideCountdownPopup()
    else
        ShowCountdownPopup()
    end
end

function SetCountdownPosition(position)
    MOVEMENT_CONFIG.countdownPosition = position
    if countdownGui and countdownFrame then
        if position == "TopCenter" then
            countdownFrame.Position = UDim2.new(0.5, -150, 0, 10)
        elseif position == "TopLeft" then
            countdownFrame.Position = UDim2.new(0, 10, 0, 10)
        elseif position == "TopRight" then
            countdownFrame.Position = UDim2.new(1, -310, 0, 10)
        elseif position == "Center" then
            countdownFrame.Position = UDim2.new(0.5, -150, 0.5, -60)
        end
    end
end

-- Add waypoint
function AddWaypoint(x, y, z)
    local waypoint = Vector3.new(x, y, z)
    table.insert(MOVEMENT_CONFIG.waypoints, waypoint)
    print("➕ Added waypoint " .. #MOVEMENT_CONFIG.waypoints .. ": " .. tostring(waypoint))
end

-- Clear all waypoints
function ClearWaypoints()
    local count = #MOVEMENT_CONFIG.waypoints
    MOVEMENT_CONFIG.waypoints = {}
    print("�️ Cleared " .. count .. " waypoints")
end

-- ====== CONFIGURATION FUNCTIONS ======
function SetInterval(seconds)
    if seconds < 1 or seconds > 3600 then
        warn("❌ Invalid interval: " .. tostring(seconds) .. " (must be 1-3600 seconds)")
        return false
    end
    
    MOVEMENT_CONFIG.intervalSeconds = seconds
    print("⏰ Interval updated to: " .. seconds .. " seconds")
    return true
end

-- ====== CHARACTER RESPAWN HANDLING ======
player.CharacterAdded:Connect(function(newCharacter)
    task.wait(2) -- Wait for character to fully load
    InitializeCharacter()
end)

-- ====== RAYFIELD UI ======
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "🚀 Auto Sequence Movement",
    LoadingTitle = "Movement Script",
    LoadingSubtitle = "by Canks",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "SequenceMovement",
        FileName = "Config"
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = true
    },
    KeySystem = false
})

local MainTab = Window:CreateTab("🎯 Main Controls", 4483362458)
local ConfigTab = Window:CreateTab("⚙️ Configuration", 4483362458)
local InfoTab = Window:CreateTab("📊 Information", 4483362458)

-- ====== MAIN CONTROLS TAB ======
local StatusLabel = MainTab:CreateLabel("Status: ⏹️ Stopped")

MainTab:CreateButton({
    Name = "▶️ Start Auto Sequence",
    Callback = function()
        StartAutoTeleport()
        Rayfield:Notify({
            Title = "✅ Started",
            Content = "Auto sequence movement started!",
            Duration = 3,
            Image = 4483362458
        })
    end,
})

MainTab:CreateButton({
    Name = "⏹️ Stop Auto Sequence",
    Callback = function()
        StopAutoTeleport()
        Rayfield:Notify({
            Title = "🛑 Stopped",
            Content = "Auto sequence movement stopped!",
            Duration = 3,
            Image = 4483362458
        })
    end,
})

MainTab:CreateButton({
    Name = "🏃 Run Sequence Now",
    Callback = function()
        RunSequenceNow()
        Rayfield:Notify({
            Title = "🚀 Running",
            Content = "Executing movement sequence now!",
            Duration = 3,
            Image = 4483362458
        })
    end,
})

MainTab:CreateButton({
    Name = "📍 Teleport to Start Only",
    Callback = function()
        TeleportNow()
        Rayfield:Notify({
            Title = "📍 Teleported",
            Content = "Teleported to start position!",
            Duration = 2,
            Image = 4483362458
        })
    end,
})

MainTab:CreateButton({
    Name = "🔄 Manual Respawn",
    Callback = function()
        PerformRespawn()
        Rayfield:Notify({
            Title = "🔄 Respawning",
            Content = "Character respawn initiated!",
            Duration = 3,
            Image = 4483362458
        })
    end,
})

MainTab:CreateToggle({
    Name = "📊 Show Countdown Popup",
    CurrentValue = MOVEMENT_CONFIG.showCountdown,
    Flag = "CountdownToggle",
    Callback = function(Value)
        if Value then
            ShowCountdownPopup()
            Rayfield:Notify({
                Title = "📊 Popup Shown",
                Content = "Countdown popup is now visible!",
                Duration = 2,
                Image = 4483362458
            })
        else
            HideCountdownPopup()
            Rayfield:Notify({
                Title = "📊 Popup Hidden",
                Content = "Countdown popup is now hidden!",
                Duration = 2,
                Image = 4483362458
            })
        end
    end,
})

-- ====== CONFIGURATION TAB ======
ConfigTab:CreateSlider({
    Name = "⏰ Sequence Interval (seconds)",
    Range = {10, 300},
    Increment = 5,
    Suffix = "s",
    CurrentValue = MOVEMENT_CONFIG.intervalSeconds,
    Flag = "IntervalSlider",
    Callback = function(Value)
        SetInterval(Value)
        Rayfield:Notify({
            Title = "⏰ Interval Updated",
            Content = "Sequence interval set to " .. Value .. " seconds",
            Duration = 2,
            Image = 4483362458
        })
    end,
})

ConfigTab:CreateSlider({
    Name = "🏃 Movement Speed",
    Range = {16, 50},
    Increment = 1,
    Suffix = " studs/s",
    CurrentValue = MOVEMENT_CONFIG.runSpeed,
    Flag = "SpeedSlider",
    Callback = function(Value)
        MOVEMENT_CONFIG.runSpeed = Value
        Rayfield:Notify({
            Title = "🏃 Speed Updated",
            Content = "Movement speed set to " .. Value,
            Duration = 2,
            Image = 4483362458
        })
    end,
})

ConfigTab:CreateToggle({
    Name = "🔄 Auto Respawn at Base",
    CurrentValue = MOVEMENT_CONFIG.autoRespawn,
    Flag = "AutoRespawnToggle",
    Callback = function(Value)
        MOVEMENT_CONFIG.autoRespawn = Value
        local status = Value and "enabled" or "disabled"
        Rayfield:Notify({
            Title = "🔄 Respawn " .. (Value and "Enabled" or "Disabled"),
            Content = "Auto respawn at base " .. status,
            Duration = 2,
            Image = 4483362458
        })
    end,
})

ConfigTab:CreateSlider({
    Name = "⏱️ Respawn Delay (seconds)",
    Range = {1, 15},
    Increment = 1,
    Suffix = "s",
    CurrentValue = MOVEMENT_CONFIG.respawnDelay,
    Flag = "RespawnDelaySlider",
    Callback = function(Value)
        MOVEMENT_CONFIG.respawnDelay = Value
        Rayfield:Notify({
            Title = "⏱️ Delay Updated",
            Content = "Respawn delay set to " .. Value .. " seconds",
            Duration = 2,
            Image = 4483362458
        })
    end,
})

ConfigTab:CreateDropdown({
    Name = "📍 Countdown Popup Position",
    Options = {"TopCenter", "TopLeft", "TopRight", "Center"},
    CurrentOption = MOVEMENT_CONFIG.countdownPosition,
    Flag = "CountdownPositionDropdown",
    Callback = function(Option)
        SetCountdownPosition(Option)
        Rayfield:Notify({
            Title = "📍 Position Updated",
            Content = "Countdown popup moved to " .. Option,
            Duration = 2,
            Image = 4483362458
        })
    end,
})

ConfigTab:CreateButton({
    Name = "🗑️ Clear All Waypoints",
    Callback = function()
        ClearWaypoints()
        Rayfield:Notify({
            Title = "🗑️ Cleared",
            Content = "All waypoints have been cleared!",
            Duration = 2,
            Image = 4483362458
        })
    end,
})

-- ====== INFORMATION TAB ======
InfoTab:CreateLabel("📍 Start Position: (-792, 804, 1788)")
InfoTab:CreateLabel("🎯 Total Waypoints: " .. #MOVEMENT_CONFIG.waypoints)
InfoTab:CreateLabel("⏰ Default Interval: " .. MOVEMENT_CONFIG.intervalSeconds .. " seconds")
InfoTab:CreateLabel("🔄 Auto Respawn: " .. (MOVEMENT_CONFIG.autoRespawn and "Enabled" or "Disabled"))
InfoTab:CreateLabel("⏱️ Respawn Delay: " .. MOVEMENT_CONFIG.respawnDelay .. " seconds")

local WaypointsList = InfoTab:CreateLabel("📋 Waypoints:")
for i, waypoint in ipairs(MOVEMENT_CONFIG.waypoints) do
    InfoTab:CreateLabel(string.format("   %d. (%.0f, %.0f, %.0f)", i, waypoint.X, waypoint.Y, waypoint.Z))
end

-- ====== STATUS UPDATE ======
function CreateSimpleGUI()
    -- Update status label every second
    task.spawn(function()
        while true do
            local status = GetStatus()
            StatusLabel:Set("Status: " .. status)
            task.wait(1)
        end
    end)
end

-- ====== GLOBAL FUNCTIONS (for console use) ======
_G.SequenceMovement = {
    start = StartAutoTeleport,
    stop = StopAutoTeleport,
    runNow = RunSequenceNow,
    teleportToStart = TeleportNow,
    setInterval = SetInterval,
    setStartPosition = SetStartPosition,
    addWaypoint = AddWaypoint,
    clearWaypoints = ClearWaypoints,
    getStatus = GetStatus,
    createGUI = CreateSimpleGUI,
    showCountdown = ShowCountdownPopup,
    hideCountdown = HideCountdownPopup,
    toggleCountdown = ToggleCountdownPopup,
    setCountdownPosition = SetCountdownPosition
}

CreateSimpleGUI()

-- Initialize countdown popup
task.wait(1)
if MOVEMENT_CONFIG.showCountdown then
    ShowCountdownPopup()
end

-- Auto start (optional - remove if you want manual start)
task.wait(2)
StartAutoTeleport()