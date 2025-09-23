local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Create Main Window (Mini Version)
local Window = Rayfield:CreateWindow({
   Name = "Mt. Pesona",
   LoadingTitle = "Mt. Pesona Controller",
   LoadingSubtitle = "By Canks",
   Theme = "Default",

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,

   ConfigurationSaving = {
      Enabled = false
   },

   Discord = {
      Enabled = false
   },

   KeySystem = false,
   Size = UDim2.fromOffset(320, 240), -- Small size
   Position = UDim2.fromScale(0.82, 0.05), -- Top right, out of way
})

-- Koordinat Mt. Pesona
local coordinates = {
    base = Vector3.new(-3406, 218, -754),
    cp1 = Vector3.new(-3334, 218, 692),
    cp2 = Vector3.new(-2809, 77, 691),
    cp3 = Vector3.new(-2518, 261, 590),
    cp4 = Vector3.new(-2341, 77, 690),
    cp5 = Vector3.new(-1706, 77, 694),
    cp6 = Vector3.new(-1211, 111, 645),
    cp7 = Vector3.new(-114, 72, 818),
    cp8 = Vector3.new(165, 285, -851),
    cp9 = Vector3.new(-374, 422, -5),
    cp10 = Vector3.new(-5, 659, -110),
    cp11 = Vector3.new(-3, 776, -304),
    cp12 = Vector3.new(1203, 784, -355),
    cp13 = Vector3.new(1521, 777, 274),
    cp14 = Vector3.new(1911, 828, 1007),
    cp15 = Vector3.new(1982, 939, 176),
    cp16 = Vector3.new(2169, 1048, 561),
    cp17 = Vector3.new(2515, 1071, 431),
    cp18 = Vector3.new(2526, 1371, 799),
    cp19 = Vector3.new(3063, 1375, 204),
    cp20 = Vector3.new(3141, 1576, 1124),
    cp21 = Vector3.new(3287, 1836, 753),
    summit = Vector3.new(3388, 2032, 705),
}

local checkpointOrder = {
    "base","cp1","cp2","cp3","cp4","cp5","cp6","cp7","cp8","cp9","cp10",
    "cp11","cp12","cp13","cp14","cp15","cp16","cp17","cp18","cp19","cp20","cp21","summit"
}

-- Config Variables
local currentIndex = 1
local HumanoidRootPart
local moveSpeed = 80 -- stud per detik
local pausePerCheckpoint = 2 -- delay tiap checkpoint
local teleportDelay = 1 -- delay untuk teleport (detik)
local liftHeight = 120 -- seberapa tinggi naik ke atas sebelum teleport

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

-- Instant teleport function with delay
local function instantTeleport(targetPos)
    if not HumanoidRootPart then return end
    
    task.wait(teleportDelay)
    HumanoidRootPart.CFrame = CFrame.new(targetPos)
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
            -- print("💀 Respawning player...")
            task.wait(5) -- Wait for respawn
            updateHRP() -- Update HRP after respawn
        end
    end
end

-- UI Elements (Mini Version with Teleport Tab)
local Tab = Window:CreateTab("Control", "play")
local TeleportTab = Window:CreateTab("Teleport", "map-pin")

-- Status Display (Compact)
local StatusLabel = Tab:CreateLabel("📊 Ready")
local CurrentCPLabel = Tab:CreateLabel("📍 Not Started")
local LoopLabel = Tab:CreateLabel("🔄 Not Started")

-- Update Status Function (Compact)
local function updateStatus()
    if isRunning then
        if isPaused then
            StatusLabel:Set("📊 ⏸️ Paused")
        else
            StatusLabel:Set("📊 ▶️ Running")
        end
        
        if skipCheckpoints then
            CurrentCPLabel:Set("📍 Skip Mode")
        else
            local cpName = checkpointOrder[currentIndex] or "Unknown"
            CurrentCPLabel:Set("📍 " .. string.upper(cpName) .. " (" .. currentIndex .. "/" .. #checkpointOrder .. ")")
        end
        
        if infiniteLoop then
            LoopLabel:Set("🔄 " .. currentLoop .. " (∞)")
        else
            LoopLabel:Set("🔄 " .. currentLoop .. "/" .. loopCount)
        end
    else
        StatusLabel:Set("📊 ⏹️ Stopped")
        CurrentCPLabel:Set("📍 Not Started")
        LoopLabel:Set("🔄 Not Started")
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
                -- print("🎉 All loops completed!")
                break
            end
            
            -- print("🔄 Starting loop " .. currentLoop .. (infiniteLoop and " (∞)" or "/" .. loopCount))
            updateStatus()
            
            -- Wait if paused
            while isPaused and isRunning do
                updateStatus()
                task.wait(0.1)
            end
            
            if not isRunning then break end
            
            if HumanoidRootPart then
                if skipCheckpoints then
                    -- Skip directly to summit
                    -- print("⚡ Skipping checkpoints - direct to summit!")
                    local summitPos = coordinates.summit
                    if summitPos then
                        updateStatus()
                        -- print("▶️ Instant teleport ke SUMMIT")
                        instantTeleport(summitPos)
                        -- print("✅ Sampai di SUMMIT")
                        
                        if not safeWait(pausePerCheckpoint) then break end
                        
                        -- Handle auto respawn or return to base
                        if autoRespawn then
                            -- print("💀 Auto respawning...")
                            respawnPlayer()
                            if not safeWait(3) then break end -- Wait after respawn
                        else
                            -- print("⚡ Instant teleport kembali ke base")
                            if HumanoidRootPart then
                                instantTeleport(coordinates.base)
                            end
                            -- print("✅ Kembali di base")
                        end
                        
                        -- Move to next loop
                        currentLoop = currentLoop + 1
                        updateStatus()
                        if not safeWait(5) then break end -- Extra delay between loops
                    else
                        -- print("❌ Summit coordinates not found!")
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
                            if cp == "summit" and currentIndex == #checkpointOrder then
                                -- print("▶️ " .. (useInstantTeleport and "Instant teleport" or "Teleport via udara") .. " ke " .. string.upper(cp))
                                if useInstantTeleport then
                                    instantTeleport(target)
                                else
                                    teleportViaAir(target)
                                end
                                -- print("✅ Sampai di " .. string.upper(cp))
                                
                                if not safeWait(pausePerCheckpoint) then break end
                                
                                -- Handle auto respawn or return to base
                                if autoRespawn then
                                    -- print("💀 Auto respawning...")
                                    respawnPlayer()
                                    if not safeWait(3) then break end -- Wait after respawn
                                else
                                    -- print("⚡ Instant teleport kembali ke base")
                                    if HumanoidRootPart then
                                        instantTeleport(coordinates.base)
                                    end
                                    -- print("✅ Kembali di base")
                                end
                                
                                -- Move to next loop
                                currentLoop = currentLoop + 1
                                currentIndex = 1
                                updateStatus()
                                if not safeWait(5) then break end -- Extra delay between loops
                                break -- Break inner loop to start next cycle
                            else
                                -- print("▶️ " .. (useInstantTeleport and "Instant teleport" or "Teleport via udara") .. " ke " .. string.upper(cp))
                                if useInstantTeleport then
                                    instantTeleport(target)
                                else
                                    teleportViaAir(target)
                                end
                                -- print("✅ Sampai di " .. string.upper(cp))

                                if not safeWait(pausePerCheckpoint) then break end

                                currentIndex += 1
                            end
                            
                            updateStatus()
                        else
                            -- print("❌ Invalid checkpoint: " .. tostring(cp))
                            break
                        end
                    end
                end
            else
                -- print("❌ HumanoidRootPart not found!")
                break
            end
            
            task.wait(0.1) -- Small delay to prevent lag
        end
        
        -- Cleanup when loop ends
        isRunning = false
        isPaused = false
        if _G.PlayPauseTogglePesona and _G.PlayPauseTogglePesona.Set then
            _G.PlayPauseTogglePesona:Set(false)
        end
        updateStatus()
        -- print("⏹️ Main loop ended")
    end)
end

-- Mini Control Section
-- Play/Pause Button
local PlayPauseButton = Tab:CreateButton({
    Name = "▶️ Start",
    Callback = function()
        if not isRunning then
            -- Start new run
            isRunning = true
            isPaused = false
            currentLoop = 1
            -- print("▶️ Starting Mt. Pesona auto climb from " .. string.upper(checkpointOrder[currentIndex] or "unknown"))
            startMainLoop()
        elseif isPaused then
            -- Resume from pause
            isPaused = false
            -- print("▶️ Resuming auto climb")
        else
            -- Pause
            isPaused = true
            -- print("⏸️ Auto climb paused")
        end
        updateStatus()
    end,
})

-- Stop Button
local StopButton = Tab:CreateButton({
    Name = "⏹️ Stop",
    Callback = function()
        stopMainLoop()
        -- print("⏹️ Auto climb stopped")
    end,
})

-- Reset Button
local ResetButton = Tab:CreateButton({
    Name = "🔄 Reset",
    Callback = function()
        currentIndex = 1
        currentLoop = 1
        if not isRunning then
            updateStatus()
            -- print("🔄 Position reset to Base")
        else
            -- print("⚠️ Cannot reset while running! Stop first.")
        end
    end,
})

-- Mini Settings
-- Skip Toggle
local SkipToggle = Tab:CreateToggle({
    Name = "⚡ Skip to Summit",
    CurrentValue = false,
    Flag = "SkipToggle",
    Callback = function(Value)
        skipCheckpoints = Value
        updateStatus()
    end,
})

-- Auto Respawn Toggle
local RespawnToggle = Tab:CreateToggle({
    Name = "💀 Auto Respawn",
    CurrentValue = false,
    Flag = "RespawnToggle",
    Callback = function(Value)
        autoRespawn = Value
    end,
})

-- Infinite Loop Toggle
local InfiniteToggle = Tab:CreateToggle({
    Name = "♾️ Infinite Loop",
    CurrentValue = false,
    Flag = "InfiniteToggle",
    Callback = function(Value)
        infiniteLoop = Value
        updateStatus()
    end,
})

-- Speed Slider (Compact)
local SpeedSlider = Tab:CreateSlider({
    Name = "Speed",
    Range = {20, 200},
    Increment = 10,
    Suffix = " s/s",
    CurrentValue = 80,
    Flag = "SpeedSlider",
    Callback = function(Value)
        moveSpeed = Value
    end,
})

-- Teleport Delay Slider
local DelaySlider = Tab:CreateSlider({
    Name = "TP Delay",
    Range = {0, 60},
    Increment = 0.5,
    Suffix = " sec",
    CurrentValue = 1,
    Flag = "DelaySlider",
    Callback = function(Value)
        teleportDelay = Value
    end,
})

-- Loop Count Slider (Compact)
local LoopSlider = Tab:CreateSlider({
    Name = "Loops",
    Range = {1, 50},
    Increment = 1,
    Suffix = "x",
    CurrentValue = 1,
    Flag = "LoopSlider",
    Callback = function(Value)
        loopCount = Value
        updateStatus()
    end,
})

-- Quick Teleport Buttons
local TeleportBaseButton = Tab:CreateButton({
    Name = "🏠 Base",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.base)
            -- print("🏠 Teleported to Base")
        end
    end,
})

local TeleportSummitButton = Tab:CreateButton({
    Name = "🏔️ Summit",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.summit)
            -- print("🏔️ Teleported to Summit")
        end
    end,
})

-- Teleport Tab Content
-- Base & Summit Section
TeleportTab:CreateButton({
    Name = "🏠 Base",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.base)
        end
    end,
})

-- Checkpoints 1-7
TeleportTab:CreateButton({
    Name = "📍 CP1",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.cp1)
        end
    end,
})

TeleportTab:CreateButton({
    Name = "📍 CP2", 
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.cp2)
        end
    end,
})

TeleportTab:CreateButton({
    Name = "📍 CP3",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.cp3)
        end
    end,
})

TeleportTab:CreateButton({
    Name = "📍 CP4",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.cp4)
        end
    end,
})

TeleportTab:CreateButton({
    Name = "📍 CP5",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.cp5)
        end
    end,
})

TeleportTab:CreateButton({
    Name = "📍 CP6",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.cp6)
        end
    end,
})

TeleportTab:CreateButton({
    Name = "📍 CP7",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.cp7)
        end
    end,
})

-- Checkpoints 8-14
TeleportTab:CreateButton({
    Name = "📍 CP8",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.cp8)
        end
    end,
})

TeleportTab:CreateButton({
    Name = "📍 CP9",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.cp9)
        end
    end,
})

TeleportTab:CreateButton({
    Name = "📍 CP10",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.cp10)
        end
    end,
})

TeleportTab:CreateButton({
    Name = "📍 CP11",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.cp11)
        end
    end,
})

TeleportTab:CreateButton({
    Name = "📍 CP12",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.cp12)
        end
    end,
})

TeleportTab:CreateButton({
    Name = "📍 CP13",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.cp13)
        end
    end,
})

TeleportTab:CreateButton({
    Name = "📍 CP14",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.cp14)
        end
    end,
})

-- Checkpoints 15-21
TeleportTab:CreateButton({
    Name = "📍 CP15",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.cp15)
        end
    end,
})

TeleportTab:CreateButton({
    Name = "📍 CP16",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.cp16)
        end
    end,
})

TeleportTab:CreateButton({
    Name = "📍 CP17",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.cp17)
        end
    end,
})

TeleportTab:CreateButton({
    Name = "📍 CP18",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.cp18)
        end
    end,
})

TeleportTab:CreateButton({
    Name = "📍 CP19",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.cp19)
        end
    end,
})

TeleportTab:CreateButton({
    Name = "📍 CP20",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.cp20)
        end
    end,
})

TeleportTab:CreateButton({
    Name = "📍 CP21",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.cp21)
        end
    end,
})

-- Summit
TeleportTab:CreateButton({
    Name = "🏔️ Summit",
    Callback = function()
        if HumanoidRootPart then
            instantTeleport(coordinates.summit)
        end
    end,
})

-- Initialize
updateStatus()

-- Cleanup on player leave
LocalPlayer.AncestryChanged:Connect(function()
    if not LocalPlayer.Parent then
        stopMainLoop()
    end
end)

-- print("🏔️ Mt. Pesona Mini UI loaded!")
-- print("📍 23 checkpoints available")
-- print("🎮 Ultra compact interface!")
