local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- Koordinat Mt. Yahayuk
local coordinates = {
    camp1 = Vector3.new(-413, 250, 763),
    camp2 = Vector3.new(-365, 389, 531),
    camp3 = Vector3.new(269, 431, 525),
    camp4 = Vector3.new(322, 490, 357),
    camp5 = Vector3.new(232, 315, -145),
    summit = Vector3.new(-621, 906, -520),
    start = Vector3.new(-640, 905, -503),
}

local checkpointOrder = {
    "camp1", "camp2", "camp3", "camp4", "camp5", "summit"
}

-- Config
local currentIndex = 1
local HumanoidRootPart
local Humanoid
local moveSpeed = 30 -- stud per detik
local pausePerCheckpoint = 12 -- delay tiap checkpoint (detik)
local liftHeight = 150 -- seberapa tinggi naik ke atas sebelum teleport
local isAutoRunning = false

-- Auto Jump Config
local autoJumpEnabled = true
local jumpHeight = 16 -- default jump power
local obstacleDetectionDistance = 10 -- jarak deteksi obstacle
local jumpCooldown = 0.5 -- cooldown antar jump
local lastJumpTime = 0

-- Update HRP
local function updateHRP()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
    Humanoid = char:WaitForChild("Humanoid")
    
    -- Set jump power
    if Humanoid then
        Humanoid.JumpPower = jumpHeight
    end
end

updateHRP()
LocalPlayer.CharacterAdded:Connect(updateHRP)

-- Raycast untuk deteksi obstacle
local function detectObstacle()
    if not HumanoidRootPart then return false end
    
    local rayOrigin = HumanoidRootPart.Position
    local rayDirection = HumanoidRootPart.CFrame.LookVector * obstacleDetectionDistance
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    
    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    
    if raycastResult then
        local hitPart = raycastResult.Instance
        local hitPoint = raycastResult.Position
        local currentPos = HumanoidRootPart.Position
        
        -- Cek jika obstacle lebih tinggi dari posisi current (tangga, wall, etc)
        if hitPoint.Y > currentPos.Y + 2 then
            return true
        end
    end
    
    return false
end

-- Auto jump function
local function performAutoJump()
    if not Humanoid or not autoJumpEnabled then return end
    
    local currentTime = tick()
    if currentTime - lastJumpTime < jumpCooldown then return end
    
    if detectObstacle() then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        lastJumpTime = currentTime
        print("🦘 Auto jump untuk mengatasi rintangan!")
        return true
    end
    
    return false
end

-- Ground-based movement dengan auto jump
local function moveToPosition(targetPos)
    if not HumanoidRootPart or not Humanoid or not isAutoRunning then return end
    
    local startPos = HumanoidRootPart.Position
    local distance = (targetPos - startPos).Magnitude
    local direction = (targetPos - startPos).Unit
    
    -- Set walkspeed untuk movement
    Humanoid.WalkSpeed = moveSpeed
    
    -- Move character dengan BodyVelocity untuk kontrol yang lebih baik
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(4000, 0, 4000) -- Tidak apply force ke Y axis
    bodyVelocity.Velocity = direction * moveSpeed
    bodyVelocity.Parent = HumanoidRootPart
    
    local startTime = tick()
    local maxMoveTime = distance / moveSpeed + 2 -- tambah buffer
    
    -- Loop movement dengan auto jump
    local moveConnection
    moveConnection = RunService.Heartbeat:Connect(function()
        if not isAutoRunning then
            bodyVelocity:Destroy()
            moveConnection:Disconnect()
            return
        end
        
        local currentPos = HumanoidRootPart.Position
        local remainingDistance = (targetPos - currentPos).Magnitude
        
        -- Auto jump check
        performAutoJump()
        
        -- Update direction jika masih jauh
        if remainingDistance > 5 then
            local newDirection = (targetPos - currentPos).Unit
            bodyVelocity.Velocity = newDirection * moveSpeed
        end
        
        -- Stop jika sudah dekat atau timeout
        if remainingDistance < 3 or (tick() - startTime) > maxMoveTime then
            bodyVelocity:Destroy()
            moveConnection:Disconnect()
            
            -- Final positioning
            task.wait(0.1)
            if HumanoidRootPart then
                HumanoidRootPart.CFrame = CFrame.new(targetPos)
            end
        end
    end)
    
    -- Wait sampai movement selesai
    while bodyVelocity.Parent and isAutoRunning do
        task.wait(0.1)
    end
end

-- Smooth teleport function
local function smoothTeleport(startPos, targetPos, speed)
    if not HumanoidRootPart or not isAutoRunning then return end

    local distance = (targetPos - startPos).Magnitude
    local duration = distance / speed
    local startTime = tick()

    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not isAutoRunning then
            connection:Disconnect()
            return
        end
        
        local elapsed = tick() - startTime
        local alpha = math.clamp(elapsed / duration, 0, 1)
        local newPos = startPos:Lerp(targetPos, alpha)
        
        if HumanoidRootPart then
            HumanoidRootPart.CFrame = CFrame.new(newPos)
        end

        if alpha >= 1 then
            connection:Disconnect()
        end
    end)

    task.wait(duration + 0.1)
end

-- Teleport via udara untuk menghindari obstacle
local function teleportViaAir(targetPos)
    if not HumanoidRootPart or not isAutoRunning then return end

    local currentPos = HumanoidRootPart.Position
    local upPos = currentPos + Vector3.new(0, liftHeight, 0)
    local downPos = targetPos + Vector3.new(0, liftHeight, 0)

    -- Step 1: Naik dulu
    print("⬆️ Naik ke udara...")
    smoothTeleport(currentPos, upPos, moveSpeed * 2)

    if not isAutoRunning then return end

    -- Step 2: Pindah horizontal (masih di atas)
    print("➡️ Bergerak horizontal...")
    smoothTeleport(upPos, downPos, moveSpeed * 3)

    if not isAutoRunning then return end

    -- Step 3: Turun ke target
    print("⬇️ Turun ke checkpoint...")
    smoothTeleport(downPos, targetPos, moveSpeed * 2)
end

-- Instant teleport untuk kembali ke start
local function instantTeleport(targetPos)
    if not HumanoidRootPart then return end
    HumanoidRootPart.CFrame = CFrame.new(targetPos)
end

-- Main auto run function dengan instant teleport
local function startAutoRun()
    isAutoRunning = true
    print("🚀 Auto Run Mt. Yahayuk dimulai!")
    print("⚡ Mode: Instant Teleport ke checkpoint")
    print("🚶 Summit ke Base: Ground movement dengan auto jump")
    
    while isAutoRunning do
        if HumanoidRootPart then
            local cp = checkpointOrder[currentIndex]
            local target = coordinates[cp]

            -- Cek apakah ini summit dan akan kembali ke start
            if cp == "summit" and currentIndex == #checkpointOrder then
                print("▶️ Teleport ke " .. cp .. " (Summit)")
                instantTeleport(target)
                
                if not isAutoRunning then break end
                
                print("🏔️ Sampai di Summit Mt. Yahayuk!")
                task.wait(pausePerCheckpoint)
                
                -- Ground movement dari summit ke start
                print("🚶 Berjalan kembali ke start dengan ground movement...")
                moveToPosition(coordinates.start)
                print("🏁 Kembali ke start position")
                
                currentIndex = 1
                task.wait(5) -- extra delay sebelum cycle baru
            else
                print("▶️ Teleport ke " .. cp)
                instantTeleport(target)
                
                if not isAutoRunning then break end
                
                print("✅ Sampai di " .. cp)
                task.wait(pausePerCheckpoint)

                currentIndex += 1
            end
        end
        task.wait(0.5)
    end
end

-- Air teleport mode (original)
local function startAutoRunAir()
    isAutoRunning = true
    print("🚀 Auto Run Mt. Yahayuk dimulai (Air Mode)!")
    
    while isAutoRunning do
        if HumanoidRootPart then
            local cp = checkpointOrder[currentIndex]
            local target = coordinates[cp]

            -- Cek apakah ini summit dan akan kembali ke start
            if cp == "summit" and currentIndex == #checkpointOrder then
                print("▶️ Menuju ke " .. cp .. " (Summit) via air")
                teleportViaAir(target)
                
                if not isAutoRunning then break end
                
                print("🏔️ Sampai di Summit Mt. Yahayuk!")
                task.wait(pausePerCheckpoint)
                
                -- Ground movement dari summit ke start (berbeda dari mode ground)
                print("🚶 Berjalan kembali ke start dengan ground movement...")
                moveToPosition(coordinates.start)
                print("🏁 Kembali ke start position")
                
                currentIndex = 1
                task.wait(5) -- extra delay sebelum cycle baru
            else
                print("▶️ Menuju ke " .. cp .. " via air")
                teleportViaAir(target)
                
                if not isAutoRunning then break end
                
                print("✅ Sampai di " .. cp)
                task.wait(pausePerCheckpoint)

                currentIndex += 1
            end
        end
        task.wait(0.5)
    end
end

-- Stop auto run function
local function stopAutoRun()
    isAutoRunning = false
    print("⏹️ Auto Run Mt. Yahayuk dihentikan!")
end

-- GUI Setup menggunakan ScreenGui
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local TitleLabel = Instance.new("TextLabel")
local StartButton = Instance.new("TextButton")
local StopButton = Instance.new("TextButton")
local StatusLabel = Instance.new("TextLabel")
local JumpToggle = Instance.new("TextButton")
local ModeToggle = Instance.new("TextButton")
local CloseButton = Instance.new("TextButton")

-- Movement mode
local useGroundMovement = true

-- Setup GUI
ScreenGui.Name = "YahayukAutoRun"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main Frame
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
MainFrame.Size = UDim2.new(0, 300, 0, 280)
MainFrame.Active = true
MainFrame.Draggable = true

-- Corner rounding
local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

-- Title
TitleLabel.Name = "TitleLabel"
TitleLabel.Parent = MainFrame
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 0, 0, 0)
TitleLabel.Size = UDim2.new(1, 0, 0, 40)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.Text = "🏔️ Auto Run Mt. Yahayuk"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextScaled = true

-- Start Button
StartButton.Name = "StartButton"
StartButton.Parent = MainFrame
StartButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
StartButton.BorderSizePixel = 0
StartButton.Position = UDim2.new(0.1, 0, 0.25, 0)
StartButton.Size = UDim2.new(0.35, 0, 0.12, 0)
StartButton.Font = Enum.Font.SourceSansBold
StartButton.Text = "▶️ START"
StartButton.TextColor3 = Color3.fromRGB(255, 255, 255)
StartButton.TextScaled = true

local StartCorner = Instance.new("UICorner")
StartCorner.CornerRadius = UDim.new(0, 5)
StartCorner.Parent = StartButton

-- Stop Button
StopButton.Name = "StopButton"
StopButton.Parent = MainFrame
StopButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
StopButton.BorderSizePixel = 0
StopButton.Position = UDim2.new(0.55, 0, 0.25, 0)
StopButton.Size = UDim2.new(0.35, 0, 0.12, 0)
StopButton.Font = Enum.Font.SourceSansBold
StopButton.Text = "⏹️ STOP"
StopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
StopButton.TextScaled = true

local StopCorner = Instance.new("UICorner")
StopCorner.CornerRadius = UDim.new(0, 5)
StopCorner.Parent = StopButton

-- Jump Toggle Button
JumpToggle.Name = "JumpToggle"
JumpToggle.Parent = MainFrame
JumpToggle.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
JumpToggle.BorderSizePixel = 0
JumpToggle.Position = UDim2.new(0.1, 0, 0.4, 0)
JumpToggle.Size = UDim2.new(0.35, 0, 0.12, 0)
JumpToggle.Font = Enum.Font.SourceSans
JumpToggle.Text = "🦘 Jump: ON"
JumpToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
JumpToggle.TextScaled = true

local JumpCorner = Instance.new("UICorner")
JumpCorner.CornerRadius = UDim.new(0, 5)
JumpCorner.Parent = JumpToggle

-- Mode Toggle Button
ModeToggle.Name = "ModeToggle"
ModeToggle.Parent = MainFrame
ModeToggle.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
ModeToggle.BorderSizePixel = 0
ModeToggle.Position = UDim2.new(0.55, 0, 0.4, 0)
ModeToggle.Size = UDim2.new(0.35, 0, 0.12, 0)
ModeToggle.Font = Enum.Font.SourceSans
ModeToggle.Text = "⚡ Instant"
ModeToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
ModeToggle.TextScaled = true

local ModeCorner = Instance.new("UICorner")
ModeCorner.CornerRadius = UDim.new(0, 5)
ModeCorner.Parent = ModeToggle

-- Status Label
StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0.1, 0, 0.55, 0)
StatusLabel.Size = UDim2.new(0.8, 0, 0.12, 0)
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.Text = "Status: Siap untuk start"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextScaled = true

-- Close Button
CloseButton.Name = "CloseButton"
CloseButton.Parent = MainFrame
CloseButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
CloseButton.BorderSizePixel = 0
CloseButton.Position = UDim2.new(0.1, 0, 0.7, 0)
CloseButton.Size = UDim2.new(0.8, 0, 0.12, 0)
CloseButton.Font = Enum.Font.SourceSans
CloseButton.Text = "❌ Tutup GUI"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextScaled = true

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 5)
CloseCorner.Parent = CloseButton

-- Button Events
StartButton.MouseButton1Click:Connect(function()
    if not isAutoRunning then
        StatusLabel.Text = "Status: Berjalan..."
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        
        if useGroundMovement then
            task.spawn(startAutoRun)
        else
            task.spawn(startAutoRunAir)
        end
    end
end)

StopButton.MouseButton1Click:Connect(function()
    if isAutoRunning then
        stopAutoRun()
        StatusLabel.Text = "Status: Dihentikan"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        currentIndex = 1 -- reset ke awal
    end
end)

JumpToggle.MouseButton1Click:Connect(function()
    autoJumpEnabled = not autoJumpEnabled
    JumpToggle.Text = "🦘 Jump: " .. (autoJumpEnabled and "ON" or "OFF")
    JumpToggle.BackgroundColor3 = autoJumpEnabled and Color3.fromRGB(0, 120, 200) or Color3.fromRGB(120, 120, 120)
    print("🦘 Auto Jump: " .. (autoJumpEnabled and "AKTIF" or "NONAKTIF"))
end)

ModeToggle.MouseButton1Click:Connect(function()
    if not isAutoRunning then
        useGroundMovement = not useGroundMovement
        ModeToggle.Text = useGroundMovement and "⚡ Instant" or "✈️ Air"
        ModeToggle.BackgroundColor3 = useGroundMovement and Color3.fromRGB(255, 140, 0) or Color3.fromRGB(0, 150, 200)
        print("🚶 Mode: " .. (useGroundMovement and "Instant Teleport (Summit->Base: Ground)" or "Air Teleport (Summit->Base: Ground)"))
    else
        print("⚠️ Tidak bisa ganti mode saat auto run sedang berjalan!")
    end
end)

CloseButton.MouseButton1Click:Connect(function()
    stopAutoRun()
    ScreenGui:Destroy()
end)

-- Update status secara real-time
task.spawn(function()
    while ScreenGui.Parent do
        if isAutoRunning and currentIndex <= #checkpointOrder then
            local currentCP = checkpointOrder[currentIndex]
            StatusLabel.Text = "Status: Menuju " .. currentCP
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        elseif not isAutoRunning then
            StatusLabel.Text = "Status: Berhenti"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
        task.wait(1)
    end
end)

print("✅ Script Auto Run Mt. Yahayuk berhasil dimuat!")
print("📋 Checkpoint order: Camp1 → Camp2 → Camp3 → Camp4 → Camp5 → Summit → Start")
print("🎮 Gunakan GUI untuk mengontrol auto run")
print("🦘 Auto Jump: Otomatis melompat saat ada rintangan (untuk movement Summit->Base)")
print("⚡ Instant Mode: Teleport instant ke checkpoint, Summit->Base jalan kaki")
print("✈️ Air Mode: Teleport melalui udara ke checkpoint, Summit->Base jalan kaki")