local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Create Main Window
local Window = Rayfield:CreateWindow({
   Name = "🏔️ Mt. Seravine Auto Climb",
   Icon = 0,
   LoadingTitle = "Mt. Seravine Controller",
   LoadingSubtitle = "by Canks",
   Theme = "Default",

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,

   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil, 
      FileName = "MtSeravine_Config"
   },

   Discord = {
      Enabled = false, 
      Invite = "noinvitelink", 
      RememberJoins = true 
   },

   KeySystem = false, 
})

-- Koordinat Mt. Seravine
local coordinates = {
    base = Vector3.new(-19, 20, 373),
    cp1 = Vector3.new(446, 279, 835),
    cp2 = Vector3.new(699, 312, 491),
    cp3 = Vector3.new(972, 308, 488),
    cp4 = Vector3.new(822, 448, 671),
    cp5 = Vector3.new(378, 860, -429),
    cp6 = Vector3.new(319, 1020, -456),
    cp7 = Vector3.new(320, 1172, -583),
    cp8 = Vector3.new(302, 1418, -138),
    cp9 = Vector3.new(726, 1495, -143),
    cp10 = Vector3.new(712, 1594, -346),
    summit = Vector3.new(733, 1800, -816),
    finish = Vector3.new(731, 1800, -920), -- Area lari setelah summit
}

local checkpointOrder = {
    "base","cp1","cp2","cp3","cp4","cp5","cp6",
    "cp7","cp8","cp9","cp10","summit","finish"
}

-- Config Variables
local currentIndex = 1
local HumanoidRootPart
local moveSpeed = 80 -- stud per detik
local walkSpeed = 50 -- walk speed for summit to finish
local pausePerCheckpoint = 2 -- delay tiap checkpoint
local liftHeight = 120 -- seberapa tinggi naik ke atas sebelum teleport
local circleRadius = 20 -- radius for circular walking at checkpoints
local circleDuration = 3 -- duration for circular walking in seconds

-- Control Variables
local isRunning = false
local isPaused = false
local mainLoop = nil

-- Feature Variables
local skipCheckpoints = false -- Skip to summit directly
local autoRespawn = false -- Auto respawn after summit
local infiniteLoop = false -- Infinite loop mode
local loopCount = 1 -- Number of loops
local currentLoop = 1 -- Current loop counter
local useInstantTeleport = true -- Use instant teleport by default

-- Function buat update HRP setelah respawn
local function updateHRP()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
end

updateHRP()
LocalPlayer.CharacterAdded:Connect(updateHRP)

-- Instant teleport function
local function instantTeleport(targetPos)
    if not HumanoidRootPart then return end
    
    HumanoidRootPart.CFrame = CFrame.new(targetPos)
end

-- Walking/Running function (for summit to finish)
local function walkToPosition(targetPos, walkSpeed)
    if not HumanoidRootPart then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    -- Set walk speed
    humanoid.WalkSpeed = walkSpeed or 16
    
    -- Use Humanoid:MoveTo for natural walking
    humanoid:MoveTo(targetPos)
    
    -- Wait until character reaches destination or gets close enough
    local startTime = tick()
    local timeout = 30 -- 30 seconds timeout
    
    while (HumanoidRootPart.Position - targetPos).Magnitude > 5 and (tick() - startTime) < timeout and isRunning do
        if isPaused then
            humanoid:MoveTo(HumanoidRootPart.Position) -- Stop moving when paused
            while isPaused and isRunning do
                task.wait(0.1)
            end
            if isRunning then
                humanoid:MoveTo(targetPos) -- Resume moving
            end
        end
        task.wait(0.1)
    end
    
    -- Reset walk speed to default
    humanoid.WalkSpeed = 16
end

-- Circular walking function for checkpoints
local function walkInCircle(centerPos, radius, duration)
    if not HumanoidRootPart then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    -- Set walk speed for circular movement
    humanoid.WalkSpeed = 50
    
    -- Calculate circular movement
    local startTime = tick()
    local angleStep = 0
    
    while (tick() - startTime) < duration and isRunning do
        if isPaused then
            humanoid:MoveTo(HumanoidRootPart.Position) -- Stop moving when paused
            while isPaused and isRunning do
                task.wait(0.1)
            end
            if not isRunning then break end
        end
        
        -- Calculate position on circle
        local angle = angleStep * math.rad(36) -- 36 degrees per step (10 points on circle)
        local x = centerPos.X + radius * math.cos(angle)
        local z = centerPos.Z + radius * math.sin(angle)
        local circlePos = Vector3.new(x, centerPos.Y, z)
        
        -- Move to circle position
        humanoid:MoveTo(circlePos)
        
        -- Wait a bit before next position
        task.wait(0.3)
        angleStep = angleStep + 1
        
        -- Complete circle after 10 steps
        if angleStep >= 10 then
            break
        end
    end
    
    -- Reset walk speed to default
    humanoid.WalkSpeed = 16
end

-- Smooth teleport (kept for optional use)
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

-- Teleport via atas (now using instant teleport)
local function teleportViaAir(targetPos)
    if not HumanoidRootPart then return end

    if useInstantTeleport then
        -- Direct instant teleport to target
        instantTeleport(targetPos)
    else
        -- Original smooth teleport via air
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

-- Respawn Function
local function respawnPlayer()
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Health = 0
            task.wait(5) -- Wait for respawn
            updateHRP() -- Update HRP after respawn
        end
    end
end

-- UI Elements
local MainTab = Window:CreateTab("🎮 Control")
local SettingsTab = Window:CreateTab("⚙️ Settings")
local TeleportTab = Window:CreateTab("📍 Teleport")

-- Status Display
local StatusLabel = MainTab:CreateLabel("📊 Status: Ready")
local CurrentCPLabel = MainTab:CreateLabel("📍 Current: Not Started")
local LoopLabel = MainTab:CreateLabel("🔄 Loop: Not Started")

-- Update Status Function
local function updateStatus()
    if isRunning then
        if isPaused then
            StatusLabel:Set("📊 Status: ⏸️ Paused")
        else
            StatusLabel:Set("📊 Status: ▶️ Running")
        end
        
        if skipCheckpoints then
            CurrentCPLabel:Set("📍 Mode: Skip to Summit")
        else
            local cpName = checkpointOrder[currentIndex] or "Unknown"
            CurrentCPLabel:Set("📍 Current: " .. string.upper(cpName) .. " (" .. currentIndex .. "/" .. #checkpointOrder .. ")")
        end
        
        if infiniteLoop then
            LoopLabel:Set("🔄 Loop: " .. currentLoop .. " (∞)")
        else
            LoopLabel:Set("🔄 Loop: " .. currentLoop .. "/" .. loopCount)
        end
    else
        StatusLabel:Set("📊 Status: ⏹️ Stopped")
        CurrentCPLabel:Set("📍 Current: Not Started")
        LoopLabel:Set("🔄 Loop: Not Started")
    end
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
    currentLoop = 1
    updateStatus()
end

-- Start Main Loop Function
local function startMainLoop()
    if mainLoop then
        task.cancel(mainLoop)
    end
    
    mainLoop = task.spawn(function()
        while isRunning do
            -- Check if we should continue looping
            if not infiniteLoop and currentLoop > loopCount then
                break
            end
            
            updateStatus()
            
            -- Wait if paused
            while isPaused and isRunning do
                updateStatus()
                task.wait(0.1)
            end
            
            if not isRunning then break end
            
            if HumanoidRootPart then
                if skipCheckpoints then
                    -- Skip directly to summit then to finish
                    local summitPos = coordinates.summit
                    local finishPos = coordinates.finish
                    if summitPos and finishPos then
                        updateStatus()
                        instantTeleport(summitPos)
                        
                        -- Do circular walking at summit
                        walkInCircle(summitPos, circleRadius, circleDuration)
                        
                        -- Direct walk to finish without delay
                        walkToPosition(finishPos, walkSpeed) -- Walk/run with configured speed
                        
                        if not safeWait(pausePerCheckpoint) then break end
                        
                        -- Handle auto respawn or return to base
                        if autoRespawn then
                            respawnPlayer()
                            if not safeWait(3) then break end -- Wait after respawn
                        else
                            if HumanoidRootPart then
                                instantTeleport(coordinates.base)
                            end
                        end
                        
                        -- Move to next loop
                        currentLoop = currentLoop + 1
                        updateStatus()
                        if not safeWait(5) then break end -- Extra delay between loops
                    else
                        break
                    end
                else
                    -- Normal checkpoint progression
                    currentIndex = 1
                    while isRunning and currentIndex <= #checkpointOrder do
                        -- Wait if paused
                        while isPaused and isRunning do
                            updateStatus()
                            task.wait(0.1)
                        end
                        
                        if not isRunning then break end
                        
                        local cp = checkpointOrder[currentIndex]
                        local target = coordinates[cp]

                        if target then
                            updateStatus()
                            
                            -- Check if this is summit
                            if cp == "summit" then
                                if useInstantTeleport then
                                    instantTeleport(target)
                                else
                                    teleportViaAir(target)
                                end
                                
                                -- Do circular walking at summit
                                walkInCircle(target, circleRadius, circleDuration)
                                
                                -- No delay, immediately proceed to finish
                                currentIndex += 1
                            -- Check if this is finish
                            elseif cp == "finish" and currentIndex == #checkpointOrder then
                                -- Direct walk to finish without delay
                                walkToPosition(target, walkSpeed) -- Walk/run with configured speed
                                
                                if not safeWait(pausePerCheckpoint) then break end
                                
                                -- Handle auto respawn or return to base
                                if autoRespawn then
                                    respawnPlayer()
                                    if not safeWait(3) then break end -- Wait after respawn
                                else
                                    if HumanoidRootPart then
                                        instantTeleport(coordinates.base)
                                    end
                                end
                                
                                -- Move to next loop
                                currentLoop = currentLoop + 1
                                currentIndex = 1
                                updateStatus()
                                if not safeWait(5) then break end -- Extra delay between loops
                                break -- Break inner loop to start next cycle
                            else
                                -- Regular checkpoint (base, cp1-cp10)
                                if useInstantTeleport then
                                    instantTeleport(target)
                                else
                                    teleportViaAir(target)
                                end
                                
                                -- Do circular walking at each checkpoint
                                if cp ~= "base" then -- Don't do circular walking at base
                                    walkInCircle(target, circleRadius, circleDuration)
                                end

                                if not safeWait(pausePerCheckpoint) then break end

                                currentIndex += 1
                            end
                            
                            updateStatus()
                        else
                            break
                        end
                    end
                end
            else
                break
            end
            
            task.wait(0.1) -- Small delay to prevent lag
        end
        
        -- Cleanup when loop ends
        isRunning = false
        isPaused = false
        if _G.PlayPauseToggleSeravine and _G.PlayPauseToggleSeravine.Set then
            _G.PlayPauseToggleSeravine:Set(false)
        end
        updateStatus()
    end)
end

-- Control Section
local ControlSection = MainTab:CreateSection("🎮 Playback Control")

-- Start Position Selection
local StartPositionDropdown = MainTab:CreateDropdown({
    Name = "🚀 Start Position",
    Options = {
        "Base (Default)",
        "CP1 - Checkpoint 1", "CP2 - Checkpoint 2", "CP3 - Checkpoint 3",
        "CP4 - Checkpoint 4", "CP5 - Checkpoint 5", "CP6 - Checkpoint 6",
        "CP7 - Checkpoint 7", "CP8 - Checkpoint 8", "CP9 - Checkpoint 9",
        "CP10 - Checkpoint 10", "Summit - Peak Point", "Finish - Final Area"
    },
    CurrentOption = {"Base (Default)"},
    MultipleOptions = false,
    Flag = "StartPositionFlag",
    Callback = function(Option)
        local positionMap = {
            ["Base (Default)"] = 1,
            ["CP1 - Checkpoint 1"] = 2, ["CP2 - Checkpoint 2"] = 3, ["CP3 - Checkpoint 3"] = 4,
            ["CP4 - Checkpoint 4"] = 5, ["CP5 - Checkpoint 5"] = 6, ["CP6 - Checkpoint 6"] = 7,
            ["CP7 - Checkpoint 7"] = 8, ["CP8 - Checkpoint 8"] = 9, ["CP9 - Checkpoint 9"] = 10,
            ["CP10 - Checkpoint 10"] = 11, ["Summit - Peak Point"] = 12, ["Finish - Final Area"] = 13
        }
        
        if not isRunning then
            currentIndex = positionMap[Option[1]] or 1
            updateStatus()
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
                currentLoop = 1
                startMainLoop()
            else
                -- Resume from pause
                isPaused = false
            end
        else
            if isRunning then
                -- Pause
                isPaused = true
            end
        end
        updateStatus()
    end,
})

-- Store reference globally for access from other functions
_G.PlayPauseToggleSeravine = PlayPauseToggle

-- Stop Button
local StopButton = MainTab:CreateButton({
    Name = "⏹️ Stop",
    Callback = function()
        stopMainLoop()
        if _G.PlayPauseToggleSeravine and _G.PlayPauseToggleSeravine.Set then
            _G.PlayPauseToggleSeravine:Set(false)
        end
    end,
})

-- Reset Button
local ResetButton = MainTab:CreateButton({
    Name = "🔄 Reset to Base",
    Callback = function()
        if not isRunning then
            -- Reset all variables
            currentIndex = 1
            currentLoop = 1
            
            -- Teleport player to base
            if HumanoidRootPart and coordinates.base then
                instantTeleport(coordinates.base)
            end
            
            -- Update status display
            updateStatus()
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
    end,
})

-- Walk Speed Slider for Summit to Finish
local WalkSpeedSlider = SettingsTab:CreateSlider({
    Name = "🚶‍♂️ Walk Speed (Summit→Finish)",
    Range = {16, 100},
    Increment = 2,
    Suffix = " walkspeed",
    CurrentValue = 50,
    Flag = "WalkSpeedSlider",
    Callback = function(Value)
        walkSpeed = Value
    end,
})

-- Circle Radius Slider
local CircleRadiusSlider = SettingsTab:CreateSlider({
    Name = "🔄 Circle Radius",
    Range = {10, 50},
    Increment = 5,
    Suffix = " studs",
    CurrentValue = 20,
    Flag = "CircleRadiusSlider",
    Callback = function(Value)
        circleRadius = Value
    end,
})

-- Circle Duration Slider
local CircleDurationSlider = SettingsTab:CreateSlider({
    Name = "⏱️ Circle Duration",
    Range = {1, 10},
    Increment = 0.5,
    Suffix = " seconds",
    CurrentValue = 3,
    Flag = "CircleDurationSlider",
    Callback = function(Value)
        circleDuration = Value
    end,
})

-- Pause Time Slider
local PauseSlider = SettingsTab:CreateSlider({
    Name = "⏱️ Pause Between Checkpoints",
    Range = {5, 60},
    Increment = 0.5,
    Suffix = " seconds",
    CurrentValue = 2,
    Flag = "PauseSlider",
    Callback = function(Value)
        pausePerCheckpoint = Value
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
    end,
})

-- Skip Options Section
local SkipSection = SettingsTab:CreateSection("⚡ Skip Options")

-- Skip Checkpoints Toggle
local SkipToggle = SettingsTab:CreateToggle({
    Name = "⚡ Skip Checkpoints (Direct to Summit)",
    CurrentValue = false,
    Flag = "SkipCheckpointsToggle",
    Callback = function(Value)
        skipCheckpoints = Value
        updateStatus()
    end,
})

-- Teleport Mode Section
local TeleportModeSection = SettingsTab:CreateSection("🚀 Teleport Mode")

-- Instant Teleport Toggle
local InstantTeleportToggle = SettingsTab:CreateToggle({
    Name = "⚡ Instant Teleport (Recommended)",
    CurrentValue = true,
    Flag = "InstantTeleportToggle",
    Callback = function(Value)
        useInstantTeleport = Value
    end,
})

-- Auto Respawn Section
local RespawnSection = SettingsTab:CreateSection("💀 Respawn Options")

-- Auto Respawn Toggle
local RespawnToggle = SettingsTab:CreateToggle({
    Name = "💀 Auto Respawn at Finish",
    CurrentValue = false,
    Flag = "AutoRespawnToggle",
    Callback = function(Value)
        autoRespawn = Value
    end,
})

-- Loop Section
local LoopSection = SettingsTab:CreateSection("🔄 Loop Options")

-- Infinite Loop Toggle
local InfiniteToggle = SettingsTab:CreateToggle({
    Name = "♾️ Infinite Loop",
    CurrentValue = false,
    Flag = "InfiniteLoopToggle",
    Callback = function(Value)
        infiniteLoop = Value
        updateStatus()
    end,
})

-- Loop Count Slider
local LoopSlider = SettingsTab:CreateSlider({
    Name = "🔢 Number of Loops",
    Range = {1, 100},
    Increment = 1,
    Suffix = " loops",
    CurrentValue = 1,
    Flag = "LoopCountSlider",
    Callback = function(Value)
        loopCount = Value
        updateStatus()
    end,
})

-- Teleport Tab Content
local BaseSection = TeleportTab:CreateSection("🏠 Base & Finish")

-- Base and Summit
local TeleportBaseButton = TeleportTab:CreateButton({
    Name = "🏠 Teleport to Base",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.base)
        end
    end,
})

local TeleportSummitButton = TeleportTab:CreateButton({
    Name = "🏔️ Teleport to Summit",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.summit)
        end
    end,
})

local TeleportFinishButton = TeleportTab:CreateButton({
    Name = "🏁 Teleport to Finish",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.finish)
        end
    end,
})

-- Checkpoints Section 1 (CP1-CP5)
local CP1to5Section = TeleportTab:CreateSection("📍 Checkpoints 1-5")

local TeleportCP1Button = TeleportTab:CreateButton({
    Name = "📍 Teleport to CP1",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.cp1)
        end
    end,
})

local TeleportCP2Button = TeleportTab:CreateButton({
    Name = "📍 Teleport to CP2",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.cp2)
        end
    end,
})

local TeleportCP3Button = TeleportTab:CreateButton({
    Name = "📍 Teleport to CP3",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.cp3)
        end
    end,
})

local TeleportCP4Button = TeleportTab:CreateButton({
    Name = "📍 Teleport to CP4",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.cp4)
        end
    end,
})

local TeleportCP5Button = TeleportTab:CreateButton({
    Name = "📍 Teleport to CP5",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.cp5)
        end
    end,
})

-- Checkpoints Section 2 (CP6-CP10)
local CP6to10Section = TeleportTab:CreateSection("📍 Checkpoints 6-10")

local TeleportCP6Button = TeleportTab:CreateButton({
    Name = "📍 Teleport to CP6",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.cp6)
        end
    end,
})

local TeleportCP7Button = TeleportTab:CreateButton({
    Name = "📍 Teleport to CP7",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.cp7)
        end
    end,
})

local TeleportCP8Button = TeleportTab:CreateButton({
    Name = "📍 Teleport to CP8",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.cp8)
        end
    end,
})

local TeleportCP9Button = TeleportTab:CreateButton({
    Name = "📍 Teleport to CP9",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.cp9)
        end
    end,
})

local TeleportCP10Button = TeleportTab:CreateButton({
    Name = "📍 Teleport to CP10",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.cp10)
        end
    end,
})

-- Advanced Teleport Features
local AdvancedSection = TeleportTab:CreateSection("⚡ Advanced Teleport")

-- Sequential Teleport (Go through checkpoints one by one manually)
local SequentialTeleportButton = TeleportTab:CreateButton({
    Name = "🔄 Next Checkpoint",
    Callback = function()
        if HumanoidRootPart then
            local nextIndex = currentIndex + 1
            if nextIndex > #checkpointOrder then
                nextIndex = 1
            end
            local nextCP = checkpointOrder[nextIndex]
            local nextPos = coordinates[nextCP]
            if nextPos then
                instantTeleport(nextPos)
                currentIndex = nextIndex
                updateStatus()
            end
        end
    end,
})

-- Previous Checkpoint
local PreviousTeleportButton = TeleportTab:CreateButton({
    Name = "⏮️ Previous Checkpoint",
    Callback = function()
        if HumanoidRootPart then
            local prevIndex = currentIndex - 1
            if prevIndex < 1 then
                prevIndex = #checkpointOrder
            end
            local prevCP = checkpointOrder[prevIndex]
            local prevPos = coordinates[prevCP]
            if prevPos then
                instantTeleport(prevPos)
                currentIndex = prevIndex
                updateStatus()
            end
        end
    end,
})

-- Random Teleport
local RandomTeleportButton = TeleportTab:CreateButton({
    Name = "🎲 Random Checkpoint",
    Callback = function()
        if HumanoidRootPart then
            local randomIndex = math.random(1, #checkpointOrder)
            local randomCP = checkpointOrder[randomIndex]
            local randomPos = coordinates[randomCP]
            if randomPos then
                instantTeleport(randomPos)
            end
        end
    end,
})

-- Teleport to Current Position (for testing)
local CurrentPositionButton = TeleportTab:CreateButton({
    Name = "📌 Get Current Position",
    Callback = function()
        if HumanoidRootPart then
            local pos = HumanoidRootPart.Position
            -- Copy to clipboard if possible
            if setclipboard then
                setclipboard("Vector3.new(" .. math.floor(pos.X) .. ", " .. math.floor(pos.Y) .. ", " .. math.floor(pos.Z) .. ")")
            end
        end
    end,
})

-- Info Tab
local InfoTab = Window:CreateTab("ℹ️ Info")
local InfoSection = InfoTab:CreateSection("📖 Instructions")

InfoTab:CreateParagraph({
    Title = "🎮 How to Use",
    Content = "1. Select start position and features\n2. Configure movement settings\n3. Choose loop options (finite/infinite)\n4. Click Play to start climbing\n5. Monitor progress and use controls"
})

InfoTab:CreateParagraph({
    Title = "✨ Special Features",
    Content = "• Skip Checkpoints: Direct teleport to summit then finish\n• Circular Walking: Walk in circles at each checkpoint\n• Auto Respawn: Respawn after reaching finish area\n• Infinite Loop: Run forever until stopped\n• Finite Loop: Set specific number of runs\n• Instant Teleport: Immediate teleportation (default)\n• Smooth Teleport: Animated movement (optional)"
})

InfoTab:CreateParagraph({
    Title = "⚙️ Settings Guide",
    Content = "• Move Speed: Teleportation speed\n• Walk Speed: Walking speed from Summit to Finish\n• Circle Radius: Radius for circular walking at checkpoints\n• Circle Duration: Time spent walking in circles\n• Pause Time: Delay between checkpoints\n• Lift Height: Flying height for teleports\n• Loop Count: Number of complete runs"
})

InfoTab:CreateParagraph({
    Title = "📊 Mt. Seravine Route",
    Content = "Base → CP1-10 → Summit → Finish\nTotal: 13 checkpoints\nSkip mode: Base → Summit → Finish (3 points only)\nSpecial: Circular walking at each checkpoint\nSummit→Finish: Direct walk without delay"
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
