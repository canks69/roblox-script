-- Autoplay Script dengan Fungsi Movement + Animasi
-- Dibuat untuk Roblox dengan smooth movement

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera

-- ====== ANIMASI ======
local Animations = {
    Walk = "rbxassetid://913402848",   -- Ganti ID ini dengan animasi jalan lu
    Run  = "rbxassetid://913376220",   -- Ganti ID ini dengan animasi lari lu
    Jump = "rbxassetid://125750702",   -- Ganti ID ini dengan animasi lompat lu
}

local AnimTracks = {}

-- Load animasi sekali aja biar ga berat
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

-- Fungsi untuk mengatur orientasi karakter menghadap target
local function faceDirection(targetPos)
    local currentPos = rootPart.Position
    local direction = (targetPos - currentPos).Unit
    local lookDirection = Vector3.new(direction.X, 0, direction.Z).Unit
    
    if lookDirection.Magnitude > 0 then
        local targetCFrame = CFrame.lookAt(currentPos, currentPos + lookDirection)
        rootPart.CFrame = targetCFrame
    end
end

-- Fungsi untuk smooth camera follow player dengan user control
local function smoothCameraFollowPlayer(cameraOffset, enableUserControl)
    cameraOffset = cameraOffset or Vector3.new(0, 5, 8)
    enableUserControl = enableUserControl or true
    
    if enableUserControl then
        -- Gunakan Custom mode agar user bisa zoom/rotate
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = humanoid
        
        -- Set camera focus ke player tapi allow user control
        local connection
        connection = RunService.Heartbeat:Connect(function()
            if rootPart then
                -- Set camera subject agar mengikuti player
                if camera.CameraSubject ~= humanoid then
                    camera.CameraSubject = humanoid
                end
            end
        end)
        
        return connection
    else
        -- Mode scriptable untuk full control (no user input)
        camera.CameraType = Enum.CameraType.Scriptable
        
        local connection
        connection = RunService.Heartbeat:Connect(function()
            if rootPart then
                local playerPos = rootPart.Position
                local targetCameraPos = playerPos + cameraOffset
                camera.CFrame = CFrame.lookAt(targetCameraPos, playerPos)
            end
        end)
        
        return connection
    end
end

-- Variable untuk camera connection dan settings
local cameraConnection = nil
local cameraSettings = {
    enableUserControl = true,
    defaultOffset = Vector3.new(0, 5, 8)
}

-- Variable untuk movement connections
local currentMovementConnection = nil
local isMoving = false

-- Fungsi untuk stop current movement
local function stopCurrentMovement()
    if currentMovementConnection then
        currentMovementConnection:Disconnect()
        currentMovementConnection = nil
    end
    isMoving = false
end

-- ====== CONFIG MOVEMENT ======
local MOVEMENT_CONFIG = {
    jalan = {
        speed = 5,
        tweenTime = 2
    },
    lompat = {
        speed = 8,
        tweenTime = 1.5,
        jumpPower = 20
    },
    lari = {
        speed = 16,
        tweenTime = 1,
        runAnimation = true
    }
}

-- Fungsi untuk smooth move dengan jump arc
local function smoothMoveJump(startPos, endPos, speed, jumpHeight)
    -- Stop movement sebelumnya jika ada
    stopCurrentMovement()
    
    local distance = (endPos - startPos).Magnitude
    local duration = distance / speed
    local startTime = tick()
    
    jumpHeight = jumpHeight or 10 -- Default jump height
    
    -- Set orientasi karakter menghadap target
    faceDirection(endPos)
    
    -- Start camera follow player dengan user control
    if cameraConnection then
        cameraConnection:Disconnect()
    end
    cameraConnection = smoothCameraFollowPlayer(cameraSettings.defaultOffset, cameraSettings.enableUserControl)
    
    isMoving = true
    currentMovementConnection = RunService.Heartbeat:Connect(function()
        if not isMoving then
            return
        end
        
        local elapsed = tick() - startTime
        local alpha = math.clamp(elapsed / duration, 0, 1)
        
        -- Linear interpolation untuk X dan Z
        local newPosXZ = Vector3.new(
            startPos.X + (endPos.X - startPos.X) * alpha,
            0,
            startPos.Z + (endPos.Z - startPos.Z) * alpha
        )
        
        -- Parabolic arc untuk Y (jump trajectory)
        local jumpY = startPos.Y + (endPos.Y - startPos.Y) * alpha + jumpHeight * math.sin(math.pi * alpha)
        local newPos = Vector3.new(newPosXZ.X, jumpY, newPosXZ.Z)
        
        if rootPart then
            -- Maintain character orientation while moving
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

    -- Reduced wait time untuk response yang lebih cepat
    task.wait(duration + 0.01)
end

-- Fungsi untuk smooth move menggunakan RunService.Heartbeat
local function smoothMove(startPos, endPos, speed)
    -- Stop movement sebelumnya jika ada
    stopCurrentMovement()
    
    local distance = (endPos - startPos).Magnitude
    local duration = distance / speed
    local startTime = tick()
    
    -- Set orientasi karakter menghadap target
    faceDirection(endPos)
    
    -- Start camera follow player dengan user control
    if cameraConnection then
        cameraConnection:Disconnect()
    end
    cameraConnection = smoothCameraFollowPlayer(cameraSettings.defaultOffset, cameraSettings.enableUserControl)
    
    isMoving = true
    currentMovementConnection = RunService.Heartbeat:Connect(function()
        if not isMoving then
            return
        end
        
        local elapsed = tick() - startTime
        local alpha = math.clamp(elapsed / duration, 0, 1)
        local newPos = startPos:Lerp(endPos, alpha)
        
        if rootPart then
            -- Maintain character orientation while moving
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

    -- Reduced wait time untuk response yang lebih cepat
    task.wait(duration + 0.01)
end

-- ====== JALAN ======
function Jalan(x, y, z)
    print("🚶 Jalan ke: " .. x .. ", " .. y .. ", " .. z)
    
    local startPos = rootPart.Position
    local targetPosition = Vector3.new(x, y, z)
    local speed = MOVEMENT_CONFIG.jalan.speed
    
    humanoid.WalkSpeed = speed
    PlayAnim("Walk")
    
    smoothMove(startPos, targetPosition, speed)
    
    print("✅ Selesai jalan")
    humanoid.WalkSpeed = 16
    AnimTracks["Walk"]:Stop()
end

-- ====== LOMPAT ======
function Lompat(x, y, z)
    print("🦘 Lompat ke: " .. x .. ", " .. y .. ", " .. z)
    
    local startPos = rootPart.Position
    local targetPosition = Vector3.new(x, y, z)
    local speed = MOVEMENT_CONFIG.lompat.speed
    local jumpHeight = 8 -- Tinggi lompatan
    
    humanoid.WalkSpeed = speed
    PlayAnim("Jump")
    
    -- Gunakan smoothMoveJump untuk trajektori melengkung
    smoothMoveJump(startPos, targetPosition, speed, jumpHeight)
    
    print("✅ Selesai lompat")
    humanoid.WalkSpeed = 16
    AnimTracks["Jump"]:Stop()
end

-- ====== LARI ======
function Lari(x, y, z)
    print("🏃 Lari ke: " .. x .. ", " .. y .. ", " .. z)
    
    local startPos = rootPart.Position
    local targetPosition = Vector3.new(x, y, z)
    local speed = MOVEMENT_CONFIG.lari.speed
    
    humanoid.WalkSpeed = speed
    PlayAnim("Run")
    
    smoothMove(startPos, targetPosition, speed)
    
    print("✅ Selesai lari")
    humanoid.WalkSpeed = 16
    AnimTracks["Run"]:Stop()
end

-- ====== SEQUENCE ======
function RunMovementSequence()
    print("🎮 Starting sequence...")
    
    local jalankKe = {-25, 4, -60}
    local lompatKe = {-28, 4, -65}
    local lariKe = {-73, 4, -39}
    
    -- Jalankan sequence berurutan TANPA delay
    Jalan(jalankKe[1], jalankKe[2], jalankKe[3])
    -- Langsung lanjut tanpa wait
    Lompat(lompatKe[1], lompatKe[2], lompatKe[3])
    -- Langsung lanjut tanpa wait
    Lari(lariKe[1], lariKe[2], lariKe[3])
    
    print("🎉 Sequence selesai!")
end

-- Fungsi sequence dengan instant transition (no waiting)
function RunInstantSequence()
    print("⚡ Starting instant sequence...")
    
    local movements = {
        {type = "Jalan", pos = {-25, 4, -60}},
        {type = "Lompat", pos = {-28, 4, -65}},
        {type = "Lari", pos = {-73, 4, -39}}
    }
    
    for i, movement in ipairs(movements) do
        print("🎯 " .. movement.type .. " ke: " .. table.concat(movement.pos, ", "))
        
        if movement.type == "Jalan" then
            Jalan(movement.pos[1], movement.pos[2], movement.pos[3])
        elseif movement.type == "Lompat" then
            Lompat(movement.pos[1], movement.pos[2], movement.pos[3])
        elseif movement.type == "Lari" then
            Lari(movement.pos[1], movement.pos[2], movement.pos[3])
        end
        
        -- Micro delay hanya untuk transisi animasi yang smooth
        if i < #movements then
            task.wait(0.1)
        end
    end
    
    print("⚡ Instant sequence selesai!")
end

-- ====== RESET & STOP ======
function ResetPosition()
    print("🔄 Reset posisi...")
    Jalan(0, 8, 0)
    print("✅ Reset selesai")
end

function StopMovement()
    -- Stop current movement
    stopCurrentMovement()
    
    humanoid.WalkSpeed = 0
    humanoid.Jump = false
    for _, track in pairs(AnimTracks) do
        if track.IsPlaying then
            track:Stop()
        end
    end
    
    -- Stop camera follow dan reset ke mode normal
    if cameraConnection then
        cameraConnection:Disconnect()
        cameraConnection = nil
    end
    camera.CameraType = Enum.CameraType.Custom
    camera.CameraSubject = humanoid
    
    print("⏹️ Movement stop")
end

-- Fungsi untuk reset kamera
function ResetCamera()
    if cameraConnection then
        cameraConnection:Disconnect()
        cameraConnection = nil
    end
    camera.CameraType = Enum.CameraType.Custom
    camera.CameraSubject = humanoid
    print("📷 Kamera direset ke mode normal")
end

-- Fungsi untuk enable camera follow manual dengan user control
function EnableCameraFollow()
    if cameraConnection then
        cameraConnection:Disconnect()
    end
    cameraConnection = smoothCameraFollowPlayer(cameraSettings.defaultOffset, cameraSettings.enableUserControl)
    print("📷 Camera follow diaktifkan (bisa zoom & rotate)")
end

-- Fungsi untuk toggle user control pada kamera
function ToggleCameraControl()
    cameraSettings.enableUserControl = not cameraSettings.enableUserControl
    
    if cameraSettings.enableUserControl then
        print("📱 User camera control ENABLED (bisa zoom & rotate)")
    else
        print("🔒 User camera control DISABLED (fixed view)")
    end
    
    -- Restart camera follow dengan setting baru
    if cameraConnection then
        cameraConnection:Disconnect()
        cameraConnection = smoothCameraFollowPlayer(cameraSettings.defaultOffset, cameraSettings.enableUserControl)
    end
end

-- Fungsi untuk set camera mode scriptable (full control, no user input)
function SetScriptableCamera()
    cameraSettings.enableUserControl = false
    if cameraConnection then
        cameraConnection:Disconnect()
    end
    cameraConnection = smoothCameraFollowPlayer(cameraSettings.defaultOffset, false)
    print("🎬 Camera mode: Scriptable (no user control)")
end

-- Fungsi untuk set camera mode custom (allow user input)
function SetCustomCamera()
    cameraSettings.enableUserControl = true
    if cameraConnection then
        cameraConnection:Disconnect()
    end
    cameraConnection = smoothCameraFollowPlayer(cameraSettings.defaultOffset, true)
    print("📱 Camera mode: Custom (user control enabled)")
end

-- Auto-run
print("🚀 Autoplay script loaded with NO DELAY Movement!")
print("📋 Available functions:")
print("   🚶 Movement:")
print("   - Jalan(x, y, z)")
print("   - Lompat(x, y, z)")
print("   - Lari(x, y, z)")
print("   - RunMovementSequence() -- Original dengan transisi")
print("   - RunInstantSequence() -- Instant, no delay!")
print("   - ResetPosition()")
print("   - StopMovement()")
print("   📷 Camera Control:")
print("   - ResetCamera()")
print("   - EnableCameraFollow()")
print("   - ToggleCameraControl()")
print("   - SetScriptableCamera()")
print("   - SetCustomCamera()")
print("   📱 User controls: Zoom & Rotate enabled by default!")
print("   ⚡ NO DELAY MODE: Movements transition instantly!")
wait(3)
RunInstantSequence()