local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Create Main Window
local Window = Rayfield:CreateWindow({
   Name = "Auto Run Gunung Yahayuk",
   Icon = 0,
   LoadingTitle = "Auto Run System",
   LoadingSubtitle = "by Canks",
   Theme = "Default",

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,

   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil, 
      FileName = "AutoRun_Yahayuk"
   },

   Discord = {
      Enabled = false, 
      Invite = "noinvitelink", 
      RememberJoins = true 
   },

   KeySystem = false, 
})

-- Main Tab
local MainTab = Window:CreateTab("Auto Run")
local Section = MainTab:CreateSection("🏃‍♂️ Auto Run Configuration")

-- Global Variables
local AutoRunEnabled = false
local SpringEnabled = false
local SelectedCheckpoints = {}
local CurrentCheckpointIndex = 1
local RunConnection = nil
local SpringConnection = nil

-- Checkpoint Coordinates (Gunung Yahayuk)
local Checkpoints = {
    Base = CFrame.new(-674.25, 909.50, -481.76),
    CP1 = CFrame.new(-429.05, 265.50, 788.27),
    CP2 = CFrame.new(-359.93, 405.13, 541.62),
    CP3 = CFrame.new(288.24, 446.13, 506.28),
    CP4 = CFrame.new(336.31, 507.13, 348.97),
    CP5 = CFrame.new(224.20, 331.13, -144.73),
    Summit = CFrame.new(-614.06, 904.50, -551.25)
}

-- Helper Functions
local function getCharacterAndHRP()
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        character = player.Character or player.CharacterAdded:Wait()
        hrp = character:WaitForChild("HumanoidRootPart")
    end
    return character, hrp
end

local function safeWait(seconds)
    local elapsed = 0
    while elapsed < seconds and AutoRunEnabled do
        elapsed = elapsed + RunService.Heartbeat:Wait()
    end
    return AutoRunEnabled
end

local function teleportToPosition(position, checkpointName)
    local character, hrp = getCharacterAndHRP()
    if not hrp or not AutoRunEnabled then return false end
    
    local success = pcall(function()
        hrp.CFrame = position
    end)
    
    if success then
        print("✅ Teleported to " .. checkpointName)
        return true
    else
        warn("❌ Failed to teleport to " .. checkpointName)
        return false
    end
end

-- Spring (Infinite Jump) System
local function enableSpring()
    if SpringConnection then return end
    
    SpringConnection = UserInputService.JumpRequest:Connect(function()
        if SpringEnabled and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
end

local function disableSpring()
    if SpringConnection then
        SpringConnection:Disconnect()
        SpringConnection = nil
    end
end

-- Auto Run System
local function startAutoRun()
    if #SelectedCheckpoints == 0 then
        warn("❌ No checkpoints selected!")
        return
    end
    
    AutoRunEnabled = true
    CurrentCheckpointIndex = 1
    
    RunConnection = task.spawn(function()
        while AutoRunEnabled and CurrentCheckpointIndex <= #SelectedCheckpoints do
            local checkpointName = SelectedCheckpoints[CurrentCheckpointIndex]
            local position = Checkpoints[checkpointName]
            
            if position then
                local success = teleportToPosition(position, checkpointName)
                if success then
                    if CurrentCheckpointIndex < #SelectedCheckpoints then
                        if not safeWait(3) then break end -- Wait 3 seconds between checkpoints
                    end
                    CurrentCheckpointIndex = CurrentCheckpointIndex + 1
                else
                    warn("❌ Failed at " .. checkpointName .. ", stopping auto run")
                    break
                end
            else
                warn("❌ Invalid checkpoint: " .. checkpointName)
                break
            end
        end
        
        -- Auto run completed or stopped
        AutoRunEnabled = false
        if AutoRunToggle then
            AutoRunToggle:Set(false)
        end
        
        if CurrentCheckpointIndex > #SelectedCheckpoints then
            print("🎉 Auto run completed successfully!")
        else
            print("⏹️ Auto run stopped")
        end
    end)
end

local function stopAutoRun()
    AutoRunEnabled = false
    CurrentCheckpointIndex = 1
    if RunConnection then
        task.cancel(RunConnection)
        RunConnection = nil
    end
end

-- Spring Toggle
local SpringToggle = MainTab:CreateToggle({
    Name = "🌸 Spring (Infinite Jump)",
    CurrentValue = false,
    Flag = "SpringToggle",
    Callback = function(Value)
        SpringEnabled = Value
        if SpringEnabled then
            enableSpring()
            print("🌸 Spring enabled!")
        else
            disableSpring()
            print("🌸 Spring disabled!")
        end
    end,
})

-- Checkpoint Selection Section
local CheckpointSection = MainTab:CreateSection("📍 Checkpoint Selection")

-- Individual Checkpoint Toggles
local CheckpointToggles = {}

local function updateSelectedCheckpoints()
    SelectedCheckpoints = {}
    local order = {"Base", "CP1", "CP2", "CP3", "CP4", "CP5", "Summit"}
    
    for _, checkpoint in ipairs(order) do
        if CheckpointToggles[checkpoint] and CheckpointToggles[checkpoint].CurrentValue then
            table.insert(SelectedCheckpoints, checkpoint)
        end
    end
    
    print("📍 Selected checkpoints: " .. table.concat(SelectedCheckpoints, " → "))
end

-- Create checkpoint toggles
CheckpointToggles.Base = MainTab:CreateToggle({
    Name = "🏠 Base Camp",
    CurrentValue = false,
    Flag = "BaseToggle",
    Callback = updateSelectedCheckpoints
})

CheckpointToggles.CP1 = MainTab:CreateToggle({
    Name = "1️⃣ Checkpoint 1",
    CurrentValue = false,
    Flag = "CP1Toggle",
    Callback = updateSelectedCheckpoints
})

CheckpointToggles.CP2 = MainTab:CreateToggle({
    Name = "2️⃣ Checkpoint 2",
    CurrentValue = false,
    Flag = "CP2Toggle",
    Callback = updateSelectedCheckpoints
})

CheckpointToggles.CP3 = MainTab:CreateToggle({
    Name = "3️⃣ Checkpoint 3",
    CurrentValue = false,
    Flag = "CP3Toggle",
    Callback = updateSelectedCheckpoints
})

CheckpointToggles.CP4 = MainTab:CreateToggle({
    Name = "4️⃣ Checkpoint 4",
    CurrentValue = false,
    Flag = "CP4Toggle",
    Callback = updateSelectedCheckpoints
})

CheckpointToggles.CP5 = MainTab:CreateToggle({
    Name = "5️⃣ Checkpoint 5",
    CurrentValue = false,
    Flag = "CP5Toggle",
    Callback = updateSelectedCheckpoints
})

CheckpointToggles.Summit = MainTab:CreateToggle({
    Name = "🏔️ Summit (Puncak)",
    CurrentValue = false,
    Flag = "SummitToggle",
    Callback = updateSelectedCheckpoints
})

-- Quick Selection Buttons
local QuickSelectSection = MainTab:CreateSection("⚡ Quick Selection")

local FullRunButton = MainTab:CreateButton({
    Name = "🎯 Select Full Run (Base → Summit)",
    Callback = function()
        for name, toggle in pairs(CheckpointToggles) do
            toggle:Set(true)
        end
        print("🎯 Full run selected!")
    end,
})

local ClearAllButton = MainTab:CreateButton({
    Name = "🧹 Clear All Selections",
    Callback = function()
        for name, toggle in pairs(CheckpointToggles) do
            toggle:Set(false)
        end
        print("🧹 All selections cleared!")
    end,
})

-- Auto Run Control Section
local ControlSection = MainTab:CreateSection("🎮 Auto Run Control")

-- Main Auto Run Toggle
AutoRunToggle = MainTab:CreateToggle({
    Name = "🏃‍♂️ Start Auto Run",
    CurrentValue = false,
    Flag = "AutoRunToggle",
    Callback = function(Value)
        if Value then
            if #SelectedCheckpoints == 0 then
                warn("❌ Please select at least one checkpoint first!")
                AutoRunToggle:Set(false)
                return
            end
            print("🏃‍♂️ Starting auto run...")
            startAutoRun()
        else
            print("⏹️ Stopping auto run...")
            stopAutoRun()
        end
    end,
})

-- Emergency Stop Button
local EmergencyStopButton = MainTab:CreateButton({
    Name = "🚨 Emergency Stop",
    Callback = function()
        stopAutoRun()
        if AutoRunToggle then
            AutoRunToggle:Set(false)
        end
        print("🚨 Emergency stop activated!")
    end,
})

-- Status Section
local StatusSection = MainTab:CreateSection("📊 Status")

-- Settings Tab
local SettingsTab = Window:CreateTab("Settings")
local SettingsSection = SettingsTab:CreateSection("⚙️ Configuration")

-- Wait Time Slider
local WaitTime = 3
local WaitSlider = SettingsTab:CreateSlider({
    Name = "⏱️ Wait Time Between Checkpoints",
    Range = {1, 10},
    Increment = 0.5,
    Suffix = " seconds",
    CurrentValue = 3,
    Flag = "WaitTimeSlider",
    Callback = function(Value)
        WaitTime = Value
        print("⏱️ Wait time set to " .. Value .. " seconds")
    end,
})

-- Update the safeWait function to use the slider value
safeWait = function(seconds)
    local elapsed = 0
    local actualWaitTime = seconds or WaitTime
    while elapsed < actualWaitTime and AutoRunEnabled do
        elapsed = elapsed + RunService.Heartbeat:Wait()
    end
    return AutoRunEnabled
end

-- Manual Teleport Tab
local TeleportTab = Window:CreateTab("Manual TP")
local TeleportSection = TeleportTab:CreateSection("📍 Manual Teleportation")

-- Manual teleport buttons for each checkpoint
for name, position in pairs(Checkpoints) do
    local emoji = "📍"
    if name == "Base" then emoji = "🏠"
    elseif name == "Summit" then emoji = "🏔️"
    elseif name:match("CP") then emoji = name:gsub("CP", "") .. "️⃣"
    end
    
    TeleportTab:CreateButton({
        Name = emoji .. " Teleport to " .. name,
        Callback = function()
            teleportToPosition(position, name)
        end,
    })
end

-- Utilities Tab
local UtilitiesTab = Window:CreateTab("Utilities")
local UtilitiesSection = UtilitiesTab:CreateSection("🛠️ Useful Tools")

-- Speed Control
local WalkSpeedSlider = UtilitiesTab:CreateSlider({
    Name = "🏃‍♂️ Walk Speed",
    Range = {16, 100},
    Increment = 1,
    Suffix = " speed",
    CurrentValue = 16,
    Flag = "WalkSpeedSlider",
    Callback = function(Value)
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = Value
            end
        end
    end,
})

-- Click Teleport Tool
local ClickTPToggle = UtilitiesTab:CreateToggle({
    Name = "🖱️ Click Teleport",
    CurrentValue = false,
    Flag = "ClickTPToggle",
    Callback = function(Value)
        local mouse = player:GetMouse()
        local existingTool = player.Backpack:FindFirstChild("Click TP Tool") 
            or (player.Character and player.Character:FindFirstChild("Click TP Tool"))

        if Value then
            if not existingTool then
                local tool = Instance.new("Tool")
                tool.RequiresHandle = false
                tool.Name = "Click TP Tool"

                tool.Activated:Connect(function()
                    local pos = mouse.Hit + Vector3.new(0, 2.5, 0)
                    pos = CFrame.new(pos.X, pos.Y, pos.Z)
                    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        player.Character.HumanoidRootPart.CFrame = pos
                    end
                end)

                tool.Parent = player.Backpack
            end
        else
            if existingTool then 
                existingTool:Destroy() 
            end
        end
    end,
})

-- Info Tab
local InfoTab = Window:CreateTab("Info")
local InfoSection = InfoTab:CreateSection("ℹ️ Information")

InfoTab:CreateParagraph({
    Title = "📖 How to Use",
    Content = "1. Enable Spring if you want infinite jump\n2. Select your desired checkpoints\n3. Use Quick Selection for common routes\n4. Start Auto Run and enjoy!\n5. Use Emergency Stop if needed"
})

InfoTab:CreateParagraph({
    Title = "⚠️ Important Notes",
    Content = "• Auto run will teleport you through selected checkpoints\n• Make sure you have selected at least one checkpoint\n• Spring (infinite jump) is optional but recommended\n• You can adjust wait time between checkpoints in Settings"
})

InfoTab:CreateParagraph({
    Title = "👨‍💻 Credits",
    Content = "Created by: RzkyO & mZZ4\nUI Framework: Rayfield\nSpecial thanks to all contributors!"
})

-- Cleanup when player leaves
player.AncestryChanged:Connect(function()
    if not player.Parent then
        stopAutoRun()
        disableSpring()
    end
end)

-- Load Configuration
Rayfield:LoadConfiguration()

print("🏔️ Auto Run Gunung Yahayuk loaded successfully!")
print("📍 Available checkpoints: Base, CP1-CP5, Summit")
print("🌸 Spring and Auto Run features ready!")
