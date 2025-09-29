local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Variabel kontrol
local isRunning = false
local currentTween = nil

-- Jalur posisi
local waypoints = {
    Vector3.new(300, 1417, -139),
    Vector3.new(372, 1431, -142),
    Vector3.new(658, 1499, -142),
    Vector3.new(726, 1495, -142),
    Vector3.new(721, 1567, -285),
    Vector3.new(713, 1593, -345),
    Vector3.new(705, 1693, -493),
    Vector3.new(725, 1768, -571),
    Vector3.new(740, 1802, -642),
    Vector3.new(734, 1804, -959)
}

-- GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FlyControl"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 100)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.new(0, 0, 0)
frame.BorderSizePixel = 2
frame.Active = true -- Diperlukan untuk dragging
frame.Draggable = true -- Membuat frame bisa di drag
frame.Parent = screenGui

local playButton = Instance.new("TextButton")
playButton.Size = UDim2.new(0, 80, 0, 30)
playButton.Position = UDim2.new(0, 10, 0, 10)
playButton.Text = "PLAY"
playButton.TextColor3 = Color3.new(1, 1, 1)
playButton.BackgroundColor3 = Color3.new(0, 0.7, 0)
playButton.Parent = frame

local pauseButton = Instance.new("TextButton")
pauseButton.Size = UDim2.new(0, 80, 0, 30)
pauseButton.Position = UDim2.new(0, 100, 0, 10)
pauseButton.Text = "PAUSE"
pauseButton.TextColor3 = Color3.new(1, 1, 1)
pauseButton.BackgroundColor3 = Color3.new(0.7, 0, 0)
pauseButton.Parent = frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 30)
statusLabel.Position = UDim2.new(0, 10, 0, 50)
statusLabel.Text = "Status: Stopped"
statusLabel.TextColor3 = Color3.new(1, 1, 1)
statusLabel.BackgroundTransparency = 1
statusLabel.Parent = frame

-- Fungsi untuk teleport
local function teleportTo(position)
    local currentChar = player.Character
    if currentChar and currentChar:FindFirstChild("HumanoidRootPart") then
        currentChar.HumanoidRootPart.CFrame = CFrame.new(position)
    end
end

-- Fungsi untuk respawn
local function respawnPlayer()
    local currentChar = player.Character
    if currentChar and currentChar:FindFirstChild("Humanoid") then
        currentChar.Humanoid.Health = 0
        -- Tunggu respawn
        character = player.CharacterAdded:Wait()
        humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        wait(2) -- Tunggu karakter sepenuhnya loaded
    end
end

-- Fungsi untuk melakukan fly sequence
local function startFlySequence()
    statusLabel.Text = "Status: Running"
    
    -- Teleport ke posisi awal
    teleportTo(waypoints[1])
    wait(0.5)
    
    local timePerSegment = 45 / (#waypoints - 1)
    
    -- Tween melalui setiap waypoint
    for i = 2, #waypoints do
        if not isRunning then break end
        
        local tweenInfo = TweenInfo.new(
            timePerSegment,
            Enum.EasingStyle.Linear,
            Enum.EasingDirection.InOut,
            0,
            false,
            0
        )
        
        local goal = {CFrame = CFrame.new(waypoints[i])}
        currentTween = TweenService:Create(humanoidRootPart, tweenInfo, goal)
        currentTween:Play()
        currentTween.Completed:Wait()
    end
    
    if isRunning then
        -- Respawn setelah mencapai tujuan
        statusLabel.Text = "Status: Respawn..."
        respawnPlayer()
        
        -- Lanjutkan cycle jika masih running
        if isRunning then
            startFlySequence()
        end
    end
end

-- Event handlers untuk tombol
playButton.MouseButton1Click:Connect(function()
    if not isRunning then
        isRunning = true
        statusLabel.Text = "Status: Starting..."
        spawn(startFlySequence)
    end
end)

pauseButton.MouseButton1Click:Connect(function()
    isRunning = false
    if currentTween then
        currentTween:Cancel()
    end
    statusLabel.Text = "Status: Stopped"
end)

-- Handle character respawn
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
end)
