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

-- Fungsi untuk smooth move
local function smoothMoveTo(targetPosition, movementType)
    local config = MOVEMENT_CONFIG[movementType]
    
    humanoid.WalkSpeed = config.speed
    
    local tweenInfo = TweenInfo.new(
        config.tweenTime,
        Enum.EasingStyle.Quart,
        Enum.EasingDirection.Out,
        0,
        false,
        0
    )
    
    local targetCFrame = CFrame.new(targetPosition)
    local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = targetCFrame})
    
    return tween
end

-- ====== JALAN ======
function Jalan(x, y, z)
    print("🚶 Jalan ke: " .. x .. ", " .. y .. ", " .. z)
    
    local targetPosition = Vector3.new(x, y, z)
    local tween = smoothMoveTo(targetPosition, "jalan")
    
    PlayAnim("Walk")
    
    tween:Play()
    tween.Completed:Connect(function()
        print("✅ Selesai jalan")
        humanoid.WalkSpeed = 16
        AnimTracks["Walk"]:Stop()
    end)
    
    return tween
end

-- ====== LOMPAT ======
function Lompat(x, y, z)
    print("🦘 Lompat ke: " .. x .. ", " .. y .. ", " .. z)
    
    local targetPosition = Vector3.new(x, y, z)
    
    humanoid.Jump = true
    humanoid.JumpPower = MOVEMENT_CONFIG.lompat.jumpPower
    
    PlayAnim("Jump")
    
    wait(0.2)
    local tween = smoothMoveTo(targetPosition, "lompat")
    tween:Play()
    
    tween.Completed:Connect(function()
        print("✅ Selesai lompat")
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50
        AnimTracks["Jump"]:Stop()
    end)
    
    return tween
end

-- ====== LARI ======
function Lari(x, y, z)
    print("🏃 Lari ke: " .. x .. ", " .. y .. ", " .. z)
    
    local targetPosition = Vector3.new(x, y, z)
    local tween = smoothMoveTo(targetPosition, "lari")
    
    humanoid.WalkSpeed = MOVEMENT_CONFIG.lari.speed
    
    PlayAnim("Run")
    
    tween:Play()
    tween.Completed:Connect(function()
        print("✅ Selesai lari")
        humanoid.WalkSpeed = 16
        AnimTracks["Run"]:Stop()
    end)
    
    return tween
end

-- ====== SEQUENCE ======
function RunMovementSequence()
    print("🎮 Starting sequence...")
    
    local jalankKe = {-25, 4, -60}
    local lompatKe = {-28, 4, -65}
    local lariKe = {-73, 4, -39}
    
    local jalanTween = Jalan(jalankKe[1], jalankKe[2], jalankKe[3])
    
    jalanTween.Completed:Connect(function()
        wait(1)
        local lompatTween = Lompat(lompatKe[1], lompatKe[2], lompatKe[3])
        
        lompatTween.Completed:Connect(function()
            wait(1)
            local lariTween = Lari(lariKe[1], lariKe[2], lariKe[3])
            
            lariTween.Completed:Connect(function()
                print("🎉 Sequence selesai!")
            end)
        end)
    end)
end

-- ====== RESET & STOP ======
function ResetPosition()
    print("🔄 Reset posisi...")
    local resetTween = Jalan(0, 8, 0)
    resetTween.Completed:Connect(function()
        print("✅ Reset selesai")
    end)
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