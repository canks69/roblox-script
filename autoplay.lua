-- Autoplay Script dengan Fungsi Movement + Animasi
-- Dibuat untuk Roblox dengan smooth movement

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

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

-- Fungsi untuk smooth move menggunakan RunService.Heartbeat
local function smoothMove(startPos, endPos, speed)
    local distance = (endPos - startPos).Magnitude
    local duration = distance / speed
    local startTime = tick()

    local connection
    connection = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        local alpha = math.clamp(elapsed / duration, 0, 1)
        local newPos = startPos:Lerp(endPos, alpha)
        if rootPart then
            rootPart.CFrame = CFrame.new(newPos)
        end
        if alpha >= 1 then
            connection:Disconnect()
        end
    end)

    task.wait(duration + 0.05)
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
    
    local targetPosition = Vector3.new(x, y, z)
    local speed = MOVEMENT_CONFIG.lompat.speed
    
    humanoid.Jump = true
    humanoid.JumpPower = MOVEMENT_CONFIG.lompat.jumpPower
    humanoid.WalkSpeed = speed
    
    PlayAnim("Jump")
    
    wait(0.2)
    local startPos = rootPart.Position  -- Get position after jump delay
    smoothMove(startPos, targetPosition, speed)
    
    print("✅ Selesai lompat")
    humanoid.WalkSpeed = 16
    humanoid.JumpPower = 50
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
    
    -- Jalankan sequence berurutan
    Jalan(jalankKe[1], jalankKe[2], jalankKe[3])
    wait(1)
    
    Lompat(lompatKe[1], lompatKe[2], lompatKe[3])
    wait(1)
    
    Lari(lariKe[1], lariKe[2], lariKe[3])
    
    print("🎉 Sequence selesai!")
end

-- ====== RESET & STOP ======
function ResetPosition()
    print("🔄 Reset posisi...")
    Jalan(0, 8, 0)
    print("✅ Reset selesai")
end

function StopMovement()
    humanoid.WalkSpeed = 0
    humanoid.Jump = false
    for _, track in pairs(AnimTracks) do
        if track.IsPlaying then
            track:Stop()
        end
    end
    print("⏹️ Movement stop")
end

-- Auto-run
print("🚀 Autoplay script loaded with Animations!")
wait(3)
RunMovementSequence()