local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local basePos = Vector3.new(873, 130, 232) -- Koordinat Base
local summitPos = Vector3.new(-3010, 1738, 385) -- Koordinat Summit

local delayTime = 5
local lastTick = tick()
local toBase = true
local HumanoidRootPart

-- Function buat update HRP setelah respawn
local function updateHRP()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
end

-- Initial HRP
updateHRP()

-- Auto update kalau respawn
LocalPlayer.CharacterAdded:Connect(function()
    updateHRP()
end)

-- Loop smooth tanpa wait()
RunService.Heartbeat:Connect(function()
    if HumanoidRootPart and tick() - lastTick >= delayTime then
        if toBase then
            HumanoidRootPart.CFrame = CFrame.new(basePos)
        else
            HumanoidRootPart.CFrame = CFrame.new(summitPos)
        end
        toBase = not toBase
        lastTick = tick()
    end
end)