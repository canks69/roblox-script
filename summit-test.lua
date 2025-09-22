-- Summit Test - Mini UI Version
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- ====== MINI RAYFIELD UI ======
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local UISettings = {
    speed = 30,
    jumpHeight = 10,
    isPaused = false,
    isRunning = false
}

-- ====== ULTRA MINI WINDOW ======
local Window = Rayfield:CreateWindow({
    Name = "Summit",
    LoadingTitle = "Mini",
    LoadingSubtitle = "UI",
    ConfigurationSaving = {Enabled = false},
    Discord = {Enabled = false},
    KeySystem = false,
    Size = UDim2.fromOffset(280, 200), -- Ultra small size
    Position = UDim2.fromScale(0.85, 0.05), -- Top right, out of way
})

-- ====== SINGLE TAB ONLY ======
local Tab = Window:CreateTab("Control", "play")

-- ====== MINI CONTROLS ======
Tab:CreateButton({
    Name = "▶️ Start",
    Callback = function()
        if not UISettings.isRunning then
            UISettings.isRunning = true
            UISettings.isPaused = false
            RunSummitTest()
        end
    end,
})

Tab:CreateButton({
    Name = "⏸️ Pause",
    Callback = function()
        UISettings.isPaused = not UISettings.isPaused
    end,
})

Tab:CreateButton({
    Name = "🔄 Reset",
    Callback = function()
        UISettings.isRunning = false
        UISettings.isPaused = false
        StopMovement()
        rootPart.CFrame = CFrame.new(-958, 171, 875)
    end,
})

-- ====== MINI SLIDERS ======
Tab:CreateSlider({
    Name = "Speed",
    Range = {20, 40},
    Increment = 2,
    CurrentValue = UISettings.speed,
    Callback = function(Value)
        UISettings.speed = Value
    end,
})

Tab:CreateSlider({
    Name = "Jump",
    Range = {8, 12},
    Increment = 1,
    CurrentValue = UISettings.jumpHeight,
    Callback = function(Value)
        UISettings.jumpHeight = Value
    end,
})

-- ====== STATUS ======
local StatusLabel = Tab:CreateLabel("Ready")

spawn(function()
    while true do
        wait(1)
        if UISettings.isRunning and not UISettings.isPaused then
            StatusLabel:Set("🏃 Running")
        elseif UISettings.isPaused then
            StatusLabel:Set("⏸️ Paused")
        else
            StatusLabel:Set("⭐ Ready")
        end
    end
end)

-- ====== ANIMATIONS ======
local Animations = {
    Run = "rbxassetid://913376220",
    Jump = "rbxassetid://125750702",
}

local AnimTracks = {}
for name, id in pairs(Animations) do
    local anim = Instance.new("Animation")
    anim.AnimationId = id
    AnimTracks[name] = humanoid:LoadAnimation(anim)
end

local function PlayAnim(name)
    for _, track in pairs(AnimTracks) do
        if track.IsPlaying then track:Stop() end
    end
    if AnimTracks[name] then AnimTracks[name]:Play() end
end

-- ====== MOVEMENT SYSTEM ======
local currentMovementConnection = nil
local isMoving = false

local function stopCurrentMovement()
    if currentMovementConnection then
        currentMovementConnection:Disconnect()
        currentMovementConnection = nil
    end
    isMoving = false
end

local function faceDirection(targetPos)
    local currentPos = rootPart.Position
    local direction = (targetPos - currentPos).Unit
    local lookDirection = Vector3.new(direction.X, 0, direction.Z).Unit
    if lookDirection.Magnitude > 0 then
        rootPart.CFrame = CFrame.lookAt(currentPos, currentPos + lookDirection)
    end
end

local function smoothMove(startPos, endPos, speed)
    stopCurrentMovement()
    local distance = (endPos - startPos).Magnitude
    local duration = distance / speed
    local startTime = tick()
    
    faceDirection(endPos)
    isMoving = true
    
    currentMovementConnection = RunService.Heartbeat:Connect(function()
        if UISettings.isPaused or not isMoving then return end
        
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
    
    local waitTime = 0
    while waitTime < (duration + 0.01) do
        if UISettings.isPaused then
            while UISettings.isPaused do task.wait(0.1) end
        end
        task.wait(0.1)
        waitTime = waitTime + 0.1
    end
end

local function smoothMoveJump(startPos, endPos, speed, jumpHeight)
    stopCurrentMovement()
    local distance = (endPos - startPos).Magnitude
    local duration = distance / speed
    local startTime = tick()
    
    faceDirection(endPos)
    isMoving = true
    
    currentMovementConnection = RunService.Heartbeat:Connect(function()
        if UISettings.isPaused or not isMoving then return end
        
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
    
    local waitTime = 0
    while waitTime < (duration + 0.01) do
        if UISettings.isPaused then
            while UISettings.isPaused do task.wait(0.1) end
        end
        task.wait(0.1)
        waitTime = waitTime + 0.1
    end
end

-- ====== MOVEMENT FUNCTIONS ======
function Lari(x, y, z)
    local startPos = rootPart.Position
    local targetPosition = Vector3.new(x, y, z)
    humanoid.WalkSpeed = UISettings.speed
    PlayAnim("Run")
    smoothMove(startPos, targetPosition, UISettings.speed)
    humanoid.WalkSpeed = 16
    AnimTracks["Run"]:Stop()
end

function Lompat(x, y, z)
    local startPos = rootPart.Position
    local targetPosition = Vector3.new(x, y, z)
    humanoid.WalkSpeed = 12
    PlayAnim("Jump")
    smoothMoveJump(startPos, targetPosition, 12, UISettings.jumpHeight)
    humanoid.WalkSpeed = 16
    AnimTracks["Jump"]:Stop()
end

-- ====== SUMMIT ROUTE ======
function RunSummitTest()
    UISettings.isRunning = true
    UISettings.isPaused = false
    
    local route = {
        {type = "Lari", pos = {-878, 179, 851}},
        {type = "Lompat", pos = {-864, 171, 850}},
        {type = "Lari", pos = {-791, 171, 850}},
        {type = "Lompat", pos = {-783, 172, 851}},
        {type = "Lari", pos = {-743, 172, 850}},
        {type = "Lompat", pos = {-732, 178, 848}}
    }
    
    for i, step in ipairs(route) do
        while UISettings.isPaused and UISettings.isRunning do task.wait(0.1) end
        if not UISettings.isRunning then break end
        
        if step.type == "Lari" then
            Lari(step.pos[1], step.pos[2], step.pos[3])
        else
            Lompat(step.pos[1], step.pos[2], step.pos[3])
        end
        
        if i < #route and UISettings.isRunning then task.wait(0.1) end
    end
    
    UISettings.isRunning = false
end

-- ====== UTILITY ======
function StopMovement()
    stopCurrentMovement()
    humanoid.WalkSpeed = 0
    for _, track in pairs(AnimTracks) do
        if track.IsPlaying then track:Stop() end
    end
end

-- ====== INIT ======
print("🏔️ Mini Summit UI Ready!")
Rayfield:Notify({
    Title = "Ready!",
    Content = "Ultra mini UI",
    Duration = 1,
})