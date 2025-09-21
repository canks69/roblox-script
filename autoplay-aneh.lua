local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Create Main Window
local Window = Rayfield:CreateWindow({
   Name = "🏔️ Mt. Aneh Auto Climb",
   Icon = 0,
   LoadingTitle = "Mt. Aneh Controller",
   LoadingSubtitle = "by RzkyO & mZZ4",
   Theme = "Default",

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,

   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil, 
      FileName = "MtAneh_Config"
   },

   Discord = {
      Enabled = false, 
      Invite = "noinvitelink", 
      RememberJoins = true 
   },

   KeySystem = false, 
})

-- Koordinat Mt. Aneh
local coordinates = {
    base = Vector3.new(892, 60, 875),
    cp1 = Vector3.new(725, 47, 682),
    cp2 = Vector3.new(825, 53, 499),
    cp3 = Vector3.new(801, 63, -133),
    cp4 = Vector3.new(418, 212, -381),
    cp5 = Vector3.new(434, 228, -236),
    cp6 = Vector3.new(264, 460, 56),
    cp7 = Vector3.new(193, 219, -367),
    cp8 = Vector3.new(-83, 322, -403),
    cp9 = Vector3.new(-445, 172, -511),
    cp10 = Vector3.new(-554, 420, -461),
    cp11 = Vector3.new(-1138, 940, 279),
    summit = Vector3.new(-989, 1348, 616),
}

local checkpointOrder = {
    "base","cp1","cp2","cp3","cp4","cp5","cp6",
    "cp7","cp8","cp9","cp10","cp11","summit"
}

-- Config Variables
local currentIndex = 1
local HumanoidRootPart
local moveSpeed = 80 -- stud per detik
local pausePerCheckpoint = 2 -- delay tiap checkpoint
local liftHeight = 120 -- seberapa tinggi naik ke atas sebelum teleport

-- Control Variables
local isRunning = false
local isPaused = false
local mainLoop = nil

-- Update HRP
local function updateHRP()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
end

updateHRP()
LocalPlayer.CharacterAdded:Connect(updateHRP)

-- UI Elements
local MainTab = Window:CreateTab("🎮 Control")
local SettingsTab = Window:CreateTab("⚙️ Settings")

-- Status Display
local StatusLabel = MainTab:CreateLabel("📊 Status: Ready")
local CurrentCPLabel = MainTab:CreateLabel("📍 Current: Not Started")

-- Update Status Function
local function updateStatus()
    if isRunning then
        if isPaused then
            StatusLabel:Set("📊 Status: ⏸️ Paused")
        else
            StatusLabel:Set("📊 Status: ▶️ Running")
        end
        local cpName = checkpointOrder[currentIndex] or "Unknown"
        CurrentCPLabel:Set("📍 Current: " .. string.upper(cpName) .. " (" .. currentIndex .. "/" .. #checkpointOrder .. ")")
    else
        StatusLabel:Set("📊 Status: ⏹️ Stopped")
        CurrentCPLabel:Set("📍 Current: Not Started")
    end
end

-- Control Section
local ControlSection = MainTab:CreateSection("🎮 Playback Control")

-- Start Position Selection
local StartPositionDropdown = MainTab:CreateDropdown({
    Name = "🚀 Start Position",
    Options = {
        "Base (Default)",
        "CP1 - Checkpoint 1", 
        "CP2 - Checkpoint 2",
        "CP3 - Checkpoint 3",
        "CP4 - Checkpoint 4",
        "CP5 - Checkpoint 5",
        "CP6 - Checkpoint 6",
        "CP7 - Checkpoint 7",
        "CP8 - Checkpoint 8",
        "CP9 - Checkpoint 9",
        "CP10 - Checkpoint 10",
        "CP11 - Checkpoint 11",
        "Summit - Final Point"
    },
    CurrentOption = {"Base (Default)"},
    MultipleOptions = false,
    Flag = "StartPositionFlag",
    Callback = function(Option)
        local positionMap = {
            ["Base (Default)"] = 1,
            ["CP1 - Checkpoint 1"] = 2,
            ["CP2 - Checkpoint 2"] = 3,
            ["CP3 - Checkpoint 3"] = 4,
            ["CP4 - Checkpoint 4"] = 5,
            ["CP5 - Checkpoint 5"] = 6,
            ["CP6 - Checkpoint 6"] = 7,
            ["CP7 - Checkpoint 7"] = 8,
            ["CP8 - Checkpoint 8"] = 9,
            ["CP9 - Checkpoint 9"] = 10,
            ["CP10 - Checkpoint 10"] = 11,
            ["CP11 - Checkpoint 11"] = 12,
            ["Summit - Final Point"] = 13
        }
        
        if not isRunning then
            currentIndex = positionMap[Option[1]] or 1
            print("🚀 Start position set to: " .. (checkpointOrder[currentIndex] or "unknown"))
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
                print("▶️ Starting Mt. Aneh auto climb from " .. string.upper(checkpointOrder[currentIndex] or "unknown"))
                startMainLoop()
            else
                -- Resume from pause
                isPaused = false
                print("▶️ Resuming auto climb")
            end
        else
            if isRunning then
                -- Pause
                isPaused = true
                print("⏸️ Auto climb paused")
            end
        end
        updateStatus()
    end,
})

-- Stop Button
local StopButton = MainTab:CreateButton({
    Name = "⏹️ Stop",
    Callback = function()
        stopMainLoop()
        if PlayPauseToggle then
            PlayPauseToggle:Set(false)
        end
        print("⏹️ Auto climb stopped")
    end,
})

-- Reset Button
local ResetButton = MainTab:CreateButton({
    Name = "🔄 Reset to Base",
    Callback = function()
        currentIndex = 1
        if not isRunning then
            updateStatus()
            print("🔄 Position reset to Base")
        else
            print("⚠️ Cannot reset while running! Stop first.")
        end
    end,
})

-- Settings Section
local ConfigSection = SettingsTab:CreateSection("⚙️ Movement Settings")

-- Speed Slider
local SpeedSlider = SettingsTab:CreateSlider({
    Name = "🏃‍♂️ Move Speed",
    Range = {20, 200},
    Increment = 10,
    Suffix = " studs/sec",
    CurrentValue = 80,
    Flag = "SpeedSlider",
    Callback = function(Value)
        moveSpeed = Value
        print("🏃‍♂️ Move speed set to " .. Value .. " studs/sec")
    end,
})

-- Pause Time Slider
local PauseSlider = SettingsTab:CreateSlider({
    Name = "⏱️ Pause Between Checkpoints",
    Range = {0.5, 10},
    Increment = 0.5,
    Suffix = " seconds",
    CurrentValue = 2,
    Flag = "PauseSlider",
    Callback = function(Value)
        pausePerCheckpoint = Value
        print("⏱️ Pause time set to " .. Value .. " seconds")
    end,
})

-- Lift Height Slider
local LiftSlider = SettingsTab:CreateSlider({
    Name = "✈️ Lift Height",
    Range = {50, 300},
    Increment = 10,
    Suffix = " studs",
    CurrentValue = 120,
    Flag = "LiftSlider",
    Callback = function(Value)
        liftHeight = Value
        print("✈️ Lift height set to " .. Value .. " studs")
    end,
})

-- Manual Teleport Section
local TeleportSection = SettingsTab:CreateSection("📍 Manual Teleport")

-- Quick teleport buttons for CP1 and CP11
local TeleportCP1Button = SettingsTab:CreateButton({
    Name = "📍 Teleport to CP1",
    Callback = function()
        if HumanoidRootPart then
            HumanoidRootPart.CFrame = CFrame.new(coordinates.cp1)
            print("📍 Teleported to CP1")
        end
    end,
})

local TeleportCP11Button = SettingsTab:CreateButton({
    Name = "📍 Teleport to CP11",
    Callback = function()
        if HumanoidRootPart then
            HumanoidRootPart.CFrame = CFrame.new(coordinates.cp11)
            print("📍 Teleported to CP11")
        end
    end,
})

local TeleportBaseButton = SettingsTab:CreateButton({
    Name = "🏠 Teleport to Base",
    Callback = function()
        if HumanoidRootPart then
            HumanoidRootPart.CFrame = CFrame.new(coordinates.base)
            print("🏠 Teleported to Base")
        end
    end,
})

local TeleportSummitButton = SettingsTab:CreateButton({
    Name = "🏔️ Teleport to Summit",
    Callback = function()
        if HumanoidRootPart then
            HumanoidRootPart.CFrame = CFrame.new(coordinates.summit)
            print("🏔️ Teleported to Summit")
        end
    end,
})

-- Smooth teleport
local function smoothTeleport(startPos, targetPos, speed)
    if not HumanoidRootPart then return end

    local distance = (targetPos - startPos).Magnitude
    local duration = distance / speed
    local startTime = tick()

    local connection
    connection = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        local alpha = math.clamp(elapsed / duration, 0, 1)
        local newPos = startPos:Lerp(targetPos, alpha)
        HumanoidRootPart.CFrame = CFrame.new(newPos)

        if alpha >= 1 then
            connection:Disconnect()
        end
    end)

    task.wait(duration + 0.05)
end

-- Teleport via atas
local function teleportViaAir(targetPos)
    if not HumanoidRootPart then return end

    local currentPos = HumanoidRootPart.Position
    local upPos = currentPos + Vector3.new(0, liftHeight, 0)
    local downPos = targetPos + Vector3.new(0, liftHeight, 0)

    -- Step 1: Naik dulu
    smoothTeleport(currentPos, upPos, moveSpeed * 2)

    -- Step 2: Pindah horizontal (masih di atas)
    smoothTeleport(upPos, downPos, moveSpeed * 3)

    -- Step 3: Turun ke target
    smoothTeleport(downPos, targetPos, moveSpeed * 2)
end

-- Safe Wait Function (respects pause state)
local function safeWait(seconds)
    local elapsed = 0
    while elapsed < seconds and isRunning do
        if not isPaused then
            elapsed = elapsed + task.wait(0.1)
        else
            task.wait(0.1) -- Still wait but don't increment elapsed while paused
        end
    end
    return isRunning
end

-- Stop Main Loop Function
local function stopMainLoop()
    isRunning = false
    isPaused = false
    if mainLoop then
        task.cancel(mainLoop)
        mainLoop = nil
    end
    currentIndex = 1
    updateStatus()
end

-- Start Main Loop Function
local function startMainLoop()
    if mainLoop then
        task.cancel(mainLoop)
    end
    
    mainLoop = task.spawn(function()
        while isRunning do
            -- Wait if paused
            while isPaused and isRunning do
                updateStatus()
                task.wait(0.1)
            end
            
            if not isRunning then break end
            
            if HumanoidRootPart then
                local cp = checkpointOrder[currentIndex]
                local target = coordinates[cp]

                if target then
                    updateStatus()
                    
                    -- Cek apakah ini summit dan akan kembali ke base
                    if cp == "summit" and currentIndex == #checkpointOrder then
                        print("▶️ Teleport via udara ke " .. string.upper(cp))
                        teleportViaAir(target)
                        print("✅ Sampai di " .. string.upper(cp))
                        
                        if not safeWait(pausePerCheckpoint) then break end
                        
                        -- Instant teleport ke base
                        print("⚡ Instant teleport kembali ke base")
                        if HumanoidRootPart then
                            HumanoidRootPart.CFrame = CFrame.new(coordinates.base)
                        end
                        print("✅ Kembali di base")
                        
                        currentIndex = 1
                        if not safeWait(5) then break end -- extra delay tiap cycle
                    else
                        print("▶️ Teleport via udara ke " .. string.upper(cp))
                        teleportViaAir(target)
                        print("✅ Sampai di " .. string.upper(cp))

                        if not safeWait(pausePerCheckpoint) then break end

                        currentIndex += 1
                    end
                    
                    updateStatus()
                else
                    print("❌ Invalid checkpoint: " .. tostring(cp))
                    break
                end
            else
                print("❌ HumanoidRootPart not found!")
                break
            end
            
            task.wait(0.1) -- Small delay to prevent lag
        end
        
        -- Cleanup when loop ends
        isRunning = false
        isPaused = false
        if PlayPauseToggle then
            PlayPauseToggle:Set(false)
        end
        updateStatus()
        print("⏹️ Main loop ended")
    end)
end

-- Info Tab
local InfoTab = Window:CreateTab("ℹ️ Info")
local InfoSection = InfoTab:CreateSection("📖 Instructions")

InfoTab:CreateParagraph({
    Title = "🎮 How to Use",
    Content = "1. Select start position from dropdown\n2. Adjust settings if needed\n3. Click Play to start auto climb\n4. Use Pause to temporarily stop\n5. Use Stop to completely halt"
})

InfoTab:CreateParagraph({
    Title = "📍 Quick Start Options",
    Content = "• Base: Start from beginning\n• CP1: Start from checkpoint 1\n• CP11: Start from checkpoint 11\n• Summit: Start from summit (will return to base)"
})

InfoTab:CreateParagraph({
    Title = "⚙️ Settings Guide",
    Content = "• Move Speed: How fast teleportation occurs\n• Pause Time: Delay between each checkpoint\n• Lift Height: How high to fly before moving"
})

-- Initialize
updateStatus()

-- Cleanup on player leave
LocalPlayer.AncestryChanged:Connect(function()
    if not LocalPlayer.Parent then
        stopMainLoop()
    end
end)

-- Load Configuration
Rayfield:LoadConfiguration()

print("🏔️ Mt. Aneh Auto Climb loaded successfully!")
print("🎮 Use the GUI to control your climb!")