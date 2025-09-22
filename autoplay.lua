-- Autoplay Script dengan Fungsi Movement
-- Dibuat untuk Roblox dengan smooth movement

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Konfigurasi Movement
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

-- Fungsi untuk membuat smooth movement menggunakan TweenService
local function smoothMoveTo(targetPosition, movementType)
    local config = MOVEMENT_CONFIG[movementType]
    
    -- Set walking speed
    humanoid.WalkSpeed = config.speed
    
    -- Create tween info
    local tweenInfo = TweenInfo.new(
        config.tweenTime,
        Enum.EasingStyle.Quart,
        Enum.EasingDirection.Out,
        0,
        false,
        0
    )
    
    -- Create CFrame tween
    local targetCFrame = CFrame.new(targetPosition)
    local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = targetCFrame})
    
    return tween
end

-- Fungsi Jalan - Movement dengan kecepatan normal
function Jalan(x, y, z)
    print("🚶 Berjalan ke koordinat: " .. x .. ", " .. y .. ", " .. z)
    
    local targetPosition = Vector3.new(x, y, z)
    local tween = smoothMoveTo(targetPosition, "jalan")
    
    -- Play walking animation
    humanoid.WalkSpeed = MOVEMENT_CONFIG.jalan.speed
    
    tween:Play()
    
    tween.Completed:Connect(function()
        print("✅ Selesai berjalan ke posisi target")
        humanoid.WalkSpeed = 16 -- Reset ke speed normal
    end)
    
    return tween
end

-- Fungsi Lompat - Movement dengan lompatan
function Lompat(x, y, z)
    print("🦘 Melompat ke koordinat: " .. x .. ", " .. y .. ", " .. z)
    
    local targetPosition = Vector3.new(x, y, z)
    
    -- Trigger jump
    humanoid.Jump = true
    humanoid.JumpPower = MOVEMENT_CONFIG.lompat.jumpPower
    
    -- Wait sedikit untuk jump animation
    wait(0.2)
    
    local tween = smoothMoveTo(targetPosition, "lompat")
    
    tween:Play()
    
    tween.Completed:Connect(function()
        print("✅ Selesai melompat ke posisi target")
        humanoid.WalkSpeed = 16 -- Reset ke speed normal
        humanoid.JumpPower = 50 -- Reset jump power
    end)
    
    return tween
end

-- Fungsi Lari - Movement dengan kecepatan tinggi
function Lari(x, y, z)
    print("🏃 Berlari ke koordinat: " .. x .. ", " .. y .. ", " .. z)
    
    local targetPosition = Vector3.new(x, y, z)
    local tween = smoothMoveTo(targetPosition, "lari")
    
    -- Set running speed
    humanoid.WalkSpeed = MOVEMENT_CONFIG.lari.speed
    
    tween:Play()
    
    tween.Completed:Connect(function()
        print("✅ Selesai berlari ke posisi target")
        humanoid.WalkSpeed = 16 -- Reset ke speed normal
    end)
    
    return tween
end

-- Fungsi untuk menjalankan sequence movement dengan delay
function RunMovementSequence()
    print("🎮 Memulai sequence autoplay movement...")
    
    -- Koordinat yang diminta
    local startPos = {0, 8, 0}
    local jalankKe = {-25, 4, -60}
    local lompatKe = {-28, 4, -65}
    local lariKe = {-73, 4, -39}
    
    -- Jalankan sequence
    local jalanTween = Jalan(jalankKe[1], jalankKe[2], jalankKe[3])
    
    jalanTween.Completed:Connect(function()
        wait(1) -- Delay 1 detik
        local lompatTween = Lompat(lompatKe[1], lompatKe[2], lompatKe[3])
        
        lompatTween.Completed:Connect(function()
            wait(1) -- Delay 1 detik
            local lariTween = Lari(lariKe[1], lariKe[2], lariKe[3])
            
            lariTween.Completed:Connect(function()
                print("🎉 Sequence movement selesai!")
            end)
        end)
    end)
end

-- Fungsi untuk reset posisi ke koordinat awal
function ResetPosition()
    print("🔄 Reset posisi ke koordinat awal...")
    local resetTween = Jalan(0, 8, 0)
    resetTween.Completed:Connect(function()
        print("✅ Posisi telah direset")
    end)
end

-- Fungsi untuk stop semua movement
function StopMovement()
    humanoid.WalkSpeed = 0
    humanoid.Jump = false
    print("⏹️ Movement dihentikan")
end

-- Auto-run sequence saat script dijalankan
print("🚀 Autoplay script loaded!")
print("📋 Available functions:")
print("   - Jalan(x, y, z)")
print("   - Lompat(x, y, z)")
print("   - Lari(x, y, z)")
print("   - RunMovementSequence()")
print("   - ResetPosition()")
print("   - StopMovement()")

-- Jalankan sequence otomatis setelah 3 detik
wait(3)
RunMovementSequence()
