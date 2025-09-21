local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

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

-- Config
local currentIndex = 1
local HumanoidRootPart
local moveSpeed = 80 -- stud per detik
local pausePerCheckpoint = 2 -- delay tiap checkpoint
local liftHeight = 120 -- seberapa tinggi naik ke atas sebelum teleport

-- Update HRP
local function updateHRP()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
end

updateHRP()
LocalPlayer.CharacterAdded:Connect(updateHRP)

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

-- Main loop
task.spawn(function()
    while true do
        if HumanoidRootPart then
            local cp = checkpointOrder[currentIndex]
            local target = coordinates[cp]

            -- Cek apakah ini summit dan akan kembali ke base
            if cp == "summit" and currentIndex == #checkpointOrder then
                print("▶️ Teleport via udara ke " .. cp)
                teleportViaAir(target)
                print("✅ Sampai di " .. cp)
                
                task.wait(pausePerCheckpoint)
                
                -- Instant teleport ke base
                print("⚡ Instant teleport kembali ke base")
                HumanoidRootPart.CFrame = CFrame.new(coordinates.base)
                print("✅ Kembali di base")
                
                currentIndex = 1
                task.wait(5) -- extra delay tiap cycle
            else
                print("▶️ Teleport via udara ke " .. cp)
                teleportViaAir(target)
                print("✅ Sampai di " .. cp)

                task.wait(pausePerCheckpoint)

                currentIndex += 1
            end
        end
        task.wait(0.5)
    end
end)