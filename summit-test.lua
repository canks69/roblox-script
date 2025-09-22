-- Summit Test Script - Versi Uji Coba dengan Rayfield UI
-- Base -> CP 1 Movement Route

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera

-- ====== RAYFIELD UI LIBRARY ======
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ====== UI VARIABLES ======
local UISettings = {
    speed = 18,
    jumpHeight = 10,
    isPaused = false,
    isRunning = false
}

-- ====== CREATE UI WINDOW ======
local Window = Rayfield:CreateWindow({
    Name = "🏔️ Summit Test Controller",
    LoadingTitle = "Summit Auto Route",
    LoadingSubtitle = "by Roblox Script",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = nil,
        FileName = "SummitTest"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false,
    KeySettings = {
        Title = "Untitled",
        Subtitle = "Key System",
        Note = "No method of obtaining the key is provided",
        FileName = "Key",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"Hello"}
    }
})

-- ====== CREATE UI TABS ======
local MainTab = Window:CreateTab("🎮 Controls", "play")
local SettingsTab = Window:CreateTab("⚙️ Settings", "settings")
local InfoTab = Window:CreateTab("📊 Info", "info")

-- ====== MAIN CONTROLS ======
local MainSection = MainTab:CreateSection("🏔️ Summit Route Controls")

local PlayButton = MainTab:CreateButton({
    Name = "▶️ Start Summit Route",
    Callback = function()
        if not UISettings.isRunning then
            UISettings.isRunning = true
            UISettings.isPaused = false
            Rayfield:Notify({
                Title = "🎮 Route Started",
                Content = "Summit Base -> CP 1 route is running!",
                Duration = 3,
                Image = "play"
            })
            RunSummitTest()
        else
            Rayfield:Notify({
                Title = "⚠️ Already Running",
                Content = "Route is already in progress!",
                Duration = 2,
                Image = "alert-triangle"
            })
        end
    end,
})

local PauseButton = MainTab:CreateButton({
    Name = "⏸️ Pause Movement",
    Callback = function()
        UISettings.isPaused = true
        StopMovement()
        Rayfield:Notify({
            Title = "⏸️ Paused",
            Content = "Movement has been paused",
            Duration = 2,
            Image = "pause"
        })
    end,
})

local ResetButton = MainTab:CreateButton({
    Name = "🔄 Reset to Start",
    Callback = function()
        UISettings.isRunning = false
        UISettings.isPaused = false
        StopMovement()
        TeleportToStart()
        Rayfield:Notify({
            Title = "🔄 Reset Complete",
            Content = "Teleported to starting position",
            Duration = 2,
            Image = "refresh-ccw"
        })
    end,
})

local StopButton = MainTab:CreateButton({
    Name = "⏹️ Emergency Stop",
    Callback = function()
        UISettings.isRunning = false
        UISettings.isPaused = false
        StopMovement()
        Rayfield:Notify({
            Title = "⏹️ Emergency Stop",
            Content = "All movement stopped immediately",
            Duration = 2,
            Image = "square"
        })
    end,
})

-- ====== SETTINGS CONTROLS ======
local SettingsSection = SettingsTab:CreateSection("⚙️ Movement Settings")

local SpeedSlider = SettingsTab:CreateSlider({
    Name = "🏃 Running Speed",
    Range = {5, 30},
    Increment = 1,
    Suffix = " studs/s",
    CurrentValue = UISettings.speed,
    Flag = "RunSpeed",
    Callback = function(Value)
        UISettings.speed = Value
        MOVEMENT_CONFIG.lari.speed = Value
        Rayfield:Notify({
            Title = "🏃 Speed Updated",
            Content = "Running speed set to " .. Value,
            Duration = 1,
            Image = "zap"
        })
    end,
})

local JumpSlider = SettingsTab:CreateSlider({
    Name = "🦘 Jump Height",
    Range = {5, 20},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = UISettings.jumpHeight,
    Flag = "JumpHeight",
    Callback = function(Value)
        UISettings.jumpHeight = Value
        MOVEMENT_CONFIG.lompat.jumpHeight = Value
        Rayfield:Notify({
            Title = "🦘 Jump Updated",
            Content = "Jump height set to " .. Value,
            Duration = 1,
            Image = "arrow-up"
        })
    end,
})

local CameraToggle = SettingsTab:CreateToggle({
    Name = "📷 Camera Follow",
    CurrentValue = true,
    Flag = "CameraFollow",
    Callback = function(Value)
        if Value then
            EnableCameraFollow()
            Rayfield:Notify({
                Title = "📷 Camera Follow ON",
                Content = "Camera will follow player",
                Duration = 1,
                Image = "camera"
            })
        else
            ResetCamera()
            Rayfield:Notify({
                Title = "📷 Camera Follow OFF",
                Content = "Camera reset to normal",
                Duration = 1,
                Image = "camera-off"
            })
        end
    end,
})

-- ====== INFO TAB ======
local InfoSection = InfoTab:CreateSection("📊 Route Information")

InfoTab:CreateParagraph({
    Title = "🗺️ Summit Route: Base -> CP 1",
    Content = "This route consists of 6 movement steps:\n\n1. Run to checkpoint (-878, 179, 851)\n2. Jump down to platform (-864, 171, 850)\n3. Run to middle area (-791, 171, 850)\n4. Jump to small platform (-783, 172, 851)\n5. Run to final area (-743, 172, 850)\n6. Final jump to CP 1 (-732, 178, 848)"
})

local StatusLabel = InfoTab:CreateLabel("Status: Ready")
local CoordinatesLabel = InfoTab:CreateLabel("Current Position: Waiting...")

-- Update labels periodically
spawn(function()
    while true do
        wait(1)
        if rootPart then
            local pos = rootPart.Position
            CoordinatesLabel:Set("Current Position: " .. 
                math.floor(pos.X) .. ", " .. 
                math.floor(pos.Y) .. ", " .. 
                math.floor(pos.Z))
            
            if UISettings.isRunning and not UISettings.isPaused then
                StatusLabel:Set("Status: 🏃 Running Route")
            elseif UISettings.isPaused then
                StatusLabel:Set("Status: ⏸️ Paused")
            else
                StatusLabel:Set("Status: ⭐ Ready")
            end
        end
    end
end)
local Animations = {
    Walk = "rbxassetid://913402848",
    Run  = "rbxassetid://913376220",
    Jump = "rbxassetid://125750702",
}

local AnimTracks = {}

-- Load animasi
for name, id in pairs(Animations) do
    local anim = Instance.new("Animation")
    anim.AnimationId = id
    AnimTracks[name] = humanoid:LoadAnimation(anim)
end

local function PlayAnim(name)
    for _, track in pairs(AnimTracks) do
        if track.IsPlaying then
            track:Stop()
        end
    end
    if AnimTracks[name] then
        AnimTracks[name]:Play()
    end
end

-- ====== ORIENTASI & KAMERA ======
local function faceDirection(targetPos)
    local currentPos = rootPart.Position
    local direction = (targetPos - currentPos).Unit
    local lookDirection = Vector3.new(direction.X, 0, direction.Z).Unit
    
    if lookDirection.Magnitude > 0 then
        local targetCFrame = CFrame.lookAt(currentPos, currentPos + lookDirection)
        rootPart.CFrame = targetCFrame
    end
end

local function smoothCameraFollowPlayer(cameraOffset, enableUserControl)
    cameraOffset = cameraOffset or Vector3.new(0, 5, 8)
    enableUserControl = enableUserControl or true
    
    if enableUserControl then
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = humanoid
        
        local connection
        connection = RunService.Heartbeat:Connect(function()
            if rootPart then
                if camera.CameraSubject ~= humanoid then
                    camera.CameraSubject = humanoid
                end
            end
        end)
        
        return connection
    end
end

-- ====== MOVEMENT VARIABLES ======
local cameraConnection = nil
local currentMovementConnection = nil
local isMoving = false

local function stopCurrentMovement()
    if currentMovementConnection then
        currentMovementConnection:Disconnect()
        currentMovementConnection = nil
    end
    isMoving = false
end

-- ====== CONFIG MOVEMENT ======
local MOVEMENT_CONFIG = {
    lari = {
        speed = 18,  -- Lebih cepat untuk summit
    },
    lompat = {
        speed = 12,
        jumpHeight = 10
    }
}

-- ====== MOVEMENT FUNCTIONS ======
local function smoothMoveJump(startPos, endPos, speed, jumpHeight)
    stopCurrentMovement()
    
    local distance = (endPos - startPos).Magnitude
    local duration = distance / speed
    local startTime = tick()
    
    jumpHeight = jumpHeight or UISettings.jumpHeight
    
    faceDirection(endPos)
    
    if cameraConnection then
        cameraConnection:Disconnect()
    end
    cameraConnection = smoothCameraFollowPlayer(Vector3.new(0, 6, 10), true)
    
    isMoving = true
    currentMovementConnection = RunService.Heartbeat:Connect(function()
        -- Check if paused
        if UISettings.isPaused or not isMoving then
            return
        end
        
        local elapsed = tick() - startTime
        local alpha = math.clamp(elapsed / duration, 0, 1)
        
        local newPosXZ = Vector3.new(
            startPos.X + (endPos.X - startPos.X) * alpha,
            0,
            startPos.Z + (endPos.Z - startPos.Z) * alpha
        )
        
        local jumpY = startPos.Y + (endPos.Y - startPos.Y) * alpha + jumpHeight * math.sin(math.pi * alpha)
        local newPos = Vector3.new(newPosXZ.X, jumpY, newPosXZ.Z)
        
        if rootPart then
            local direction = (endPos - startPos).Unit
            local lookDirection = Vector3.new(direction.X, 0, direction.Z).Unit
            if lookDirection.Magnitude > 0 then
                rootPart.CFrame = CFrame.lookAt(newPos, newPos + lookDirection)
            else
                rootPart.CFrame = CFrame.new(newPos)
            end
        end
        if alpha >= 1 then
            currentMovementConnection:Disconnect()
            currentMovementConnection = nil
            isMoving = false
        end
    end)

    -- Wait with pause check
    local waitTime = 0
    while waitTime < (duration + 0.01) do
        if UISettings.isPaused then
            while UISettings.isPaused do
                task.wait(0.1)
            end
        end
        task.wait(0.1)
        waitTime = waitTime + 0.1
    end
end

local function smoothMove(startPos, endPos, speed)
    stopCurrentMovement()
    
    local distance = (endPos - startPos).Magnitude
    local duration = distance / speed
    local startTime = tick()
    
    faceDirection(endPos)
    
    if cameraConnection then
        cameraConnection:Disconnect()
    end
    cameraConnection = smoothCameraFollowPlayer(Vector3.new(0, 5, 8), true)
    
    isMoving = true
    currentMovementConnection = RunService.Heartbeat:Connect(function()
        -- Check if paused
        if UISettings.isPaused or not isMoving then
            return
        end
        
        local elapsed = tick() - startTime
        local alpha = math.clamp(elapsed / duration, 0, 1)
        local newPos = startPos:Lerp(endPos, alpha)
        
        if rootPart then
            local direction = (endPos - startPos).Unit
            local lookDirection = Vector3.new(direction.X, 0, direction.Z).Unit
            if lookDirection.Magnitude > 0 then
                rootPart.CFrame = CFrame.lookAt(newPos, newPos + lookDirection)
            else
                rootPart.CFrame = CFrame.new(newPos)
            end
        end
        if alpha >= 1 then
            currentMovementConnection:Disconnect()
            currentMovementConnection = nil
            isMoving = false
        end
    end)

    -- Wait with pause check
    local waitTime = 0
    while waitTime < (duration + 0.01) do
        if UISettings.isPaused then
            while UISettings.isPaused do
                task.wait(0.1)
            end
        end
        task.wait(0.1)
        waitTime = waitTime + 0.1
    end
end

-- ====== SUMMIT MOVEMENT FUNCTIONS ======
function Lari(x, y, z)
    print("🏃 Berlari ke: " .. x .. ", " .. y .. ", " .. z)
    
    local startPos = rootPart.Position
    local targetPosition = Vector3.new(x, y, z)
    local speed = UISettings.speed  -- Use UI speed setting
    
    humanoid.WalkSpeed = speed
    PlayAnim("Run")
    
    smoothMove(startPos, targetPosition, speed)
    
    print("✅ Selesai berlari")
    humanoid.WalkSpeed = 16
    AnimTracks["Run"]:Stop()
end

function Lompat(x, y, z)
    print("🦘 Melompat ke: " .. x .. ", " .. y .. ", " .. z)
    
    local startPos = rootPart.Position
    local targetPosition = Vector3.new(x, y, z)
    local speed = MOVEMENT_CONFIG.lompat.speed
    local jumpHeight = UISettings.jumpHeight  -- Use UI jump height setting
    
    humanoid.WalkSpeed = speed
    PlayAnim("Jump")
    
    smoothMoveJump(startPos, targetPosition, speed, jumpHeight)
    
    print("✅ Selesai melompat")
    humanoid.WalkSpeed = 16
    AnimTracks["Jump"]:Stop()
end

-- ====== SUMMIT TEST ROUTE ======
function RunSummitTest()
    print("🏔️ Starting Summit Test Route: Base -> CP 1")
    print("📍 Starting position should be around: -958, 171, 875")
    
    UISettings.isRunning = true
    UISettings.isPaused = false
    
    -- Summit Route: Base -> CP 1
    local route = {
        {type = "Lari", pos = {-878, 179, 851}, desc = "Berlari ke checkpoint pertama"},
        {type = "Lompat", pos = {-864, 171, 850}, desc = "Lompat turun ke platform"},
        {type = "Lari", pos = {-791, 171, 850}, desc = "Berlari ke area tengah"},
        {type = "Lompat", pos = {-783, 172, 851}, desc = "Lompat ke platform kecil"},
        {type = "Lari", pos = {-743, 172, 850}, desc = "Berlari ke area akhir"},
        {type = "Lompat", pos = {-732, 178, 848}, desc = "Lompat final ke CP 1"}
    }
    
    print("🎯 Route memiliki " .. #route .. " tahapan movement")
    
    for i, step in ipairs(route) do
        -- Check if stopped or paused
        while UISettings.isPaused and UISettings.isRunning do
            task.wait(0.1)
        end
        
        if not UISettings.isRunning then
            print("⏹️ Route dihentikan oleh user")
            break
        end
        
        print("📍 Step " .. i .. ": " .. step.desc)
        print("   Koordinat: " .. table.concat(step.pos, ", "))
        
        if step.type == "Lari" then
            Lari(step.pos[1], step.pos[2], step.pos[3])
        elseif step.type == "Lompat" then
            Lompat(step.pos[1], step.pos[2], step.pos[3])
        end
        
        -- Mini delay untuk smooth transition
        if i < #route and UISettings.isRunning then
            task.wait(0.1)
        end
    end
    
    if UISettings.isRunning then
        print("🎉 Summit Test Route Completed!")
        print("🏁 Seharusnya sudah sampai di CP 1")
        Rayfield:Notify({
            Title = "🎉 Route Complete!",
            Content = "Successfully reached CP 1!",
            Duration = 3,
            Image = "check-circle"
        })
    end
    
    UISettings.isRunning = false
end

-- ====== UTILITY FUNCTIONS ======
function TeleportToStart()
    print("📍 Teleport ke posisi start: -958, 171, 875")
    rootPart.CFrame = CFrame.new(-958, 171, 875)
    print("✅ Teleport selesai!")
end

function StopMovement()
    stopCurrentMovement()
    
    humanoid.WalkSpeed = 0
    humanoid.Jump = false
    for _, track in pairs(AnimTracks) do
        if track.IsPlaying then
            track:Stop()
        end
    end
    
    if cameraConnection then
        cameraConnection:Disconnect()
        cameraConnection = nil
    end
    camera.CameraType = Enum.CameraType.Custom
    camera.CameraSubject = humanoid
    
    print("⏹️ Movement dihentikan")
end

function ResetCamera()
    if cameraConnection then
        cameraConnection:Disconnect()
        cameraConnection = nil
    end
    camera.CameraType = Enum.CameraType.Custom
    camera.CameraSubject = humanoid
    print("📷 Kamera direset")
end

function EnableCameraFollow()
    if cameraConnection then
        cameraConnection:Disconnect()
    end
    cameraConnection = smoothCameraFollowPlayer(Vector3.new(0, 5, 8), true)
    print("📷 Camera follow diaktifkan")
end

-- ====== AUTO START ======
print("🏔️ Summit Test Script Loaded with Rayfield UI!")
print("📋 UI Controls:")
print("   ▶️ Play Button - Start summit route")
print("   ⏸️ Pause Button - Pause movement")
print("   � Reset Button - Teleport to start")
print("   ⏹️ Stop Button - Emergency stop")
print("   ⚙️ Settings Tab - Adjust speed & jump height")
print("   📊 Info Tab - Route info & live status")
print("")
print("🎮 UI loaded! Use the interface to control the script.")
print("📍 Make sure you're near position: -958, 171, 875")

-- Show initial notification
Rayfield:Notify({
    Title = "🏔️ Summit Test Ready!",
    Content = "UI loaded successfully. Use controls to start route.",
    Duration = 4,
    Image = "mountain"
})