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

-- ====== RAYFIELD UI LIBRARY ==-- ====== AUTO START ======
print("🏔️ Summit Control UI Loaded!")
print("📱 Compact interface ready")
print("📍 Position: -958, 171, 875")

-- Show initial notification
Rayfield:Notify({
    Title = "🏔️ Ready!",
    Content = "Compact UI loaded",
    Duration = 2,
    Image = "mountain"
})= loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ====== UI VARIABLES ======
local UISettings = {
    speed = 18,
    jumpHeight = 10,
    isPaused = false,
    isRunning = false
}

-- ====== CREATE UI WINDOW ======
local Window = Rayfield:CreateWindow({
    Name = "🏔️ Summit Control",
    LoadingTitle = "Summit Auto",
    LoadingSubtitle = "Compact UI",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = nil,
        FileName = "SummitTest"
    },
    Discord = {
        Enabled = false,
    },
    KeySystem = false,
    Size = UDim2.fromOffset(260, 260), -- Smaller window size
    Position = UDim2.fromScale(0.5, 0.5), -- Center position
    MinimizeKey = Enum.KeyCode.LeftControl, -- Minimize with Ctrl
})

-- ====== CREATE UI TABS ======
local MainTab = Window:CreateTab("🎮 Control", "play")
local SettingsTab = Window:CreateTab("⚙️ Config", "settings")

-- ====== MAIN CONTROLS (COMPACT) ======
local ControlSection = MainTab:CreateSection("Route Controls")

local PlayButton = MainTab:CreateButton({
    Name = "▶️ Start Route",
    Callback = function()
        if not UISettings.isRunning then
            UISettings.isRunning = true
            UISettings.isPaused = false
            Rayfield:Notify({
                Title = "▶️ Started",
                Content = "Route running!",
                Duration = 2,
                Image = "play"
            })
            RunSummitTest()
        else
            Rayfield:Notify({
                Title = "⚠️ Running",
                Content = "Already in progress!",
                Duration = 1,
                Image = "alert-triangle"
            })
        end
    end,
})

local PauseButton = MainTab:CreateButton({
    Name = "⏸️ Pause",
    Callback = function()
        UISettings.isPaused = true
        StopMovement()
        Rayfield:Notify({
            Title = "⏸️ Paused",
            Content = "Movement paused",
            Duration = 1,
            Image = "pause"
        })
    end,
})

local ResetButton = MainTab:CreateButton({
    Name = "🔄 Reset",
    Callback = function()
        UISettings.isRunning = false
        UISettings.isPaused = false
        StopMovement()
        TeleportToStart()
        Rayfield:Notify({
            Title = "🔄 Reset",
            Content = "Back to start",
            Duration = 1,
            Image = "refresh-ccw"
        })
    end,
})

-- ====== COMPACT STATUS ======
local StatusSection = MainTab:CreateSection("Status")
local StatusLabel = MainTab:CreateLabel("Status: Ready")
local PosLabel = MainTab:CreateLabel("Position: Waiting...")

-- ====== COMPACT SETTINGS ======
local ConfigSection = SettingsTab:CreateSection("Movement Config")

local SpeedSlider = SettingsTab:CreateSlider({
    Name = "🏃 Speed",
    Range = {8, 25},
    Increment = 1,
    Suffix = "",
    CurrentValue = UISettings.speed,
    Flag = "RunSpeed",
    Callback = function(Value)
        UISettings.speed = Value
        MOVEMENT_CONFIG.lari.speed = Value
    end,
})

local JumpSlider = SettingsTab:CreateSlider({
    Name = "🦘 Jump",
    Range = {6, 15},
    Increment = 1,
    Suffix = "",
    CurrentValue = UISettings.jumpHeight,
    Flag = "JumpHeight",
    Callback = function(Value)
        UISettings.jumpHeight = Value
        MOVEMENT_CONFIG.lompat.jumpHeight = Value
    end,
})

local CameraToggle = SettingsTab:CreateToggle({
    Name = "📷 Camera Follow",
    CurrentValue = true,
    Flag = "CameraFollow",
    Callback = function(Value)
        if Value then
            EnableCameraFollow()
        else
            ResetCamera()
        end
    end,
})

-- ====== COMPACT INFO ======
SettingsTab:CreateParagraph({
    Title = "� Route Info",
    Content = "Base -> CP 1 (6 steps)\nStart: -958, 171, 875\nEnd: -732, 178, 848"
})

-- ====== COMPACT STATUS UPDATER ======
spawn(function()
    while true do
        wait(1)
        if rootPart then
            local pos = rootPart.Position
            PosLabel:Set("Pos: " .. 
                math.floor(pos.X) .. ", " .. 
                math.floor(pos.Y) .. ", " .. 
                math.floor(pos.Z))
            
            if UISettings.isRunning and not UISettings.isPaused then
                StatusLabel:Set("Status: 🏃 Running")
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
        speed = 25,  -- Lebih cepat untuk summit
    },
    lompat = {
        speed = 20,
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