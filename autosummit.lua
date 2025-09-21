local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local BOT_TOKEN = "aw"
local CHAT_ID = "aw"
local API_URL = "https://api.telegram.org/bot" .. BOT_TOKEN .. "/sendMessage"

local function httpRequest(data)
    if syn and syn.request then return syn.request(data)
    elseif http_request then return http_request(data)
    elseif request then return request(data)
    elseif fluxus and fluxus.request then return fluxus.request(data)
    elseif KRNL_LOADED and request then return request(data)
    else error("Executor lo ga support http request") end
end

local function sendToTelegram(msg)
    local body = {
        chat_id = CHAT_ID,
        text = msg
    }
    local data = HttpService:JSONEncode(body)

    httpRequest({
        Url = API_URL,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = data
    })
end

local Window = Rayfield:CreateWindow({
   Name = "Mount Fvckers by RzkyO & mZZ4",
   Icon = 0,
   LoadingTitle = "mZZ4 HUB",
   LoadingSubtitle = "by RzkyO & mZZ4",
   Theme = "Default",

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,

   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil, 
      FileName = "Big Hub"
   },

   Discord = {
      Enabled = false, 
      Invite = "noinvitelink", 
      RememberJoins = true 
   },

   KeySystem = false, 
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided", 
      FileName = "Key",
      SaveKey = true, 
      GrabKeyFromSite = false,
      Key = {"Hello"} 
   }
})

local Tab = Window:CreateTab("Main")
local Section = Tab:CreateSection("- 3xplo Yang Tersedia -")

local InfiniteJumpEnabled = false

local Toggle = Tab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "Toggle1",
    Callback = function(Value)
        InfiniteJumpEnabled = Value

        if InfiniteJumpEnabled then
            local Player = game:GetService("Players").LocalPlayer
            local UIS = game:GetService("UserInputService")

            if _G.InfiniteJumpConnection then
                _G.InfiniteJumpConnection:Disconnect()
            end

            _G.InfiniteJumpConnection = UIS.JumpRequest:Connect(function()
                if InfiniteJumpEnabled and Player.Character and Player.Character:FindFirstChildOfClass("Humanoid") then
                    Player.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        else
            if _G.InfiniteJumpConnection then
                _G.InfiniteJumpConnection:Disconnect()
                _G.InfiniteJumpConnection = nil
            end
        end
    end,
})

local AutoHealEnabled = false
local HealConnection

local Toggle = Tab:CreateToggle({
    Name = "Auto Heal",
    CurrentValue = false,
    Flag = "AutoHealToggle",
    Callback = function(Value)
        AutoHealEnabled = Value
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")

        if AutoHealEnabled then
            HealConnection = game:GetService("RunService").Heartbeat:Connect(function()
                if humanoid.Health < humanoid.MaxHealth then
                    humanoid.Health = math.min(humanoid.Health + 5, humanoid.MaxHealth)
                end
            end)
        else
            if HealConnection then HealConnection:Disconnect() HealConnection = nil end
        end
    end,
})

local godModeConnection = nil
local function enableGodMode(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Name ~= "GodHumanoid" then
        humanoid.Name = "GodHumanoid"

        godModeConnection = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            if humanoid.Health < 1 then
                humanoid.Health = humanoid.MaxHealth
            end
        end)
    end
end

local function disableGodMode(character)
    if godModeConnection then
        godModeConnection:Disconnect()
        godModeConnection = nil
    end
    local humanoid = character:FindFirstChild("GodHumanoid")
    if humanoid then
        humanoid.Name = "Humanoid"
    end
end

local Toggle = Tab:CreateToggle({
    Name = "God Mode",
    CurrentValue = false,
    Flag = "GodModeToggle",
    Callback = function(Value)
        local character = player.Character or player.CharacterAdded:Wait()
        if Value then
            enableGodMode(character)
        else
            disableGodMode(character)
        end
    end,
})

player.CharacterAdded:Connect(function(character)
    wait(1)
    if Toggle.CurrentValue then
        enableGodMode(character)
    else
        disableGodMode(character)
    end
end)

local Toggle = Tab:CreateToggle({
    Name = "Click Teleport",
    CurrentValue = false,
    Flag = "ClickTP_Toggle",
    Callback = function(Value)
        local player = game.Players.LocalPlayer
        local mouse = player:GetMouse()

        local existingTool = player.Backpack:FindFirstChild("Equip to Click TP") 
            or player.Character:FindFirstChild("Equip to Click TP")

        if Value then
            if not existingTool then
                local tool = Instance.new("Tool")
                tool.RequiresHandle = false
                tool.Name = "Equip to Click TP"

                tool.Activated:Connect(function()
                    local pos = mouse.Hit + Vector3.new(0, 2.5, 0)
                    pos = CFrame.new(pos.X, pos.Y, pos.Z)
                    player.Character.HumanoidRootPart.CFrame = pos
                end)

                tool.Parent = player.Backpack
            end
        else
            if existingTool then existingTool:Destroy() end
        end
    end,
})

-- === CLICK TELEPORT + GET COORDINATE (SEND TO TELEGRAM) ===
local Toggle = Tab:CreateToggle({
    Name = "Click Teleport To Get Coordinate",
    CurrentValue = false,
    Flag = "ClickTP_Coords_Toggle",
    Callback = function(Value)
        local player = game.Players.LocalPlayer
        local mouse = player:GetMouse()

        local existingTool = player.Backpack:FindFirstChild("Equip to Click TP Coords") 
            or player.Character:FindFirstChild("Equip to Click TP Coords")

        if Value then
            if not existingTool then
                local tool = Instance.new("Tool")
                tool.RequiresHandle = false
                tool.Name = "Equip to Click TP Coords"

                tool.Activated:Connect(function()
                    local pos = mouse.Hit + Vector3.new(0, 2.5, 0)
                    pos = CFrame.new(pos.X, pos.Y, pos.Z)
                    player.Character.HumanoidRootPart.CFrame = pos

                    -- Ambil koordinat player setelah teleport
                    local coords = player.Character.HumanoidRootPart.Position
                    local msg = string.format(
                        "Player %s Teleported!\nKoordinat:\n(%.2f,%.2f,%.2f)",
                        player.Name, coords.X, coords.Y, coords.Z
                    )

                    -- Kirim ke Telegram
                    sendToTelegram(msg)
                end)

                tool.Parent = player.Backpack
            end
        else
            if existingTool then existingTool:Destroy() end
        end
    end,
})

local Slider = Tab:CreateSlider({
   Name = "WalkSpeed",
   Range = {0, 100},
   Increment = 1,
   Suffix = "Speed",
   CurrentValue = 16,
   Flag = "Slider1",
   Callback = function(Value)
      local player = game.Players.LocalPlayer
      local character = player.Character or player.CharacterAdded:Wait()
      local humanoid = character:FindFirstChildOfClass("Humanoid")
      
      if humanoid then
          humanoid.WalkSpeed = Value
      end
   end,
})

-- local Tab = Window:CreateTab("Teleport")
-- local Section = Tab:CreateSection("- 3xplo Yang Tersedia -")

-- local Toggle = Tab:CreateToggle({
--     Name = "Teleport to CP1",
--     CurrentValue = false,
--     Flag = "Toggle1",
--     Callback = function(Value)
--         if Value then
--             local player = game.Players.LocalPlayer
--             local character = player.Character or player.CharacterAdded:Wait()
--             local hrp = character:WaitForChild("HumanoidRootPart")

--             -- Ganti ini ke koordinat tujuan kamu
--             local targetPosition = CFrame.new(-370.81,361.78,465.77)

--             hrp.CFrame = targetPosition
--         end
--         -- Kalau Value == false, nggak ngapa-ngapain
--     end,
-- })

-- local Toggle = Tab:CreateToggle({
--     Name = "Teleport to CP2",
--     CurrentValue = false,
--     Flag = "Toggle1",
--     Callback = function(Value)
--         if Value then
--             local player = game.Players.LocalPlayer
--             local character = player.Character or player.CharacterAdded:Wait()
--             local hrp = character:WaitForChild("HumanoidRootPart")

--             -- Ganti ini ke koordinat tujuan kamu
--             local targetPosition = CFrame.new(3075.16,9108.50,4457.68)

--             hrp.CFrame = targetPosition
--         end
--         -- Kalau Value == false, nggak ngapa-ngapain
--     end,
-- })

-- local Toggle = Tab:CreateToggle({
--     Name = "Teleport to CP3",
--     CurrentValue = false,
--     Flag = "Toggle1",
--     Callback = function(Value)
--         if Value then
--             local player = game.Players.LocalPlayer
--             local character = player.Character or player.CharacterAdded:Wait()
--             local hrp = character:WaitForChild("HumanoidRootPart")

--             -- Ganti ini ke koordinat tujuan kamu
--             local targetPosition = CFrame.new(1876.87,9552.50,3487.89)

--             hrp.CFrame = targetPosition
--         end
--         -- Kalau Value == false, nggak ngapa-ngapain
--     end,
-- })

-- local Toggle = Tab:CreateToggle({
--     Name = "Teleport to CP4",
--     CurrentValue = false,
--     Flag = "Toggle1",
--     Callback = function(Value)
--         if Value then
--             local player = game.Players.LocalPlayer
--             local character = player.Character or player.CharacterAdded:Wait()
--             local hrp = character:WaitForChild("HumanoidRootPart")

--             -- Ganti ini ke koordinat tujuan kamu
--             local targetPosition = CFrame.new(1369.14,9776.50,3126.86)

--             hrp.CFrame = targetPosition
--         end
--         -- Kalau Value == false, nggak ngapa-ngapain
--     end,
-- })

-- local Toggle = Tab:CreateToggle({
--     Name = "Teleport to CP5",
--     CurrentValue = false,
--     Flag = "Toggle1",
--     Callback = function(Value)
--         if Value then
--             local player = game.Players.LocalPlayer
--             local character = player.Character or player.CharacterAdded:Wait()
--             local hrp = character:WaitForChild("HumanoidRootPart")

--             -- Ganti ini ke koordinat tujuan kamu
--             local targetPosition = CFrame.new(1189.22,10121.51,2295.03)

--             hrp.CFrame = targetPosition
--         end
--         -- Kalau Value == false, nggak ngapa-ngapain
--     end,
-- })

-- local Toggle = Tab:CreateToggle({
--     Name = "Teleport to SUMMIT",
--     CurrentValue = false,
--     Flag = "Toggle1",
--     Callback = function(Value)
--         if Value then
--             local player = game.Players.LocalPlayer
--             local character = player.Character or player.CharacterAdded:Wait()
--             local hrp = character:WaitForChild("HumanoidRootPart")

--             -- Ganti ini ke koordinat tujuan kamu
--             local targetPosition = CFrame.new(-120.01,10832.71,3017.44)

--             hrp.CFrame = targetPosition
--         end
--         -- Kalau Value == false, nggak ngapa-ngapain
--     end,
-- })

-- ===== Helper =====
local function getCharacterAndHRP()
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        -- tunggu ulang kalau belum kebentuk
        character = player.Character or player.CharacterAdded:Wait()
        hrp = character:WaitForChild("HumanoidRootPart")
    end
    return character, hrp
end

local function resetCharacter()
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Health = 0 -- biar respawn
        end
    end
end

local WAIT_SEC = 5
local USE_HEARTBEAT_TIMER = true
local RunService = game:GetService("RunService")
local function sleep(sec)
    if USE_HEARTBEAT_TIMER then
        local t = 0
        while t < sec do
            t += RunService.Heartbeat:Wait()
        end
    else
        task.wait(sec)
    end
end

_G.__TP_BUSY = _G.__TP_BUSY or false

local function runOnceResilient(points, toggleRef)
    if _G.__TP_BUSY then
        warn("Auto Summit lagi jalan, batal start baru.")
        pcall(function()
            if toggleRef and (toggleRef.Set or toggleRef.SetState) then
                (toggleRef.Set or toggleRef.SetState)(toggleRef, false)
            end
        end)
        return
    end
    _G.__TP_BUSY = true

    local ok, err = pcall(function()
        local i = 1
        while i <= #points do
            local character, hrp = getCharacterAndHRP()

            local teleported = false
            while not teleported do
                if not hrp or not hrp.Parent then
                    character, hrp = getCharacterAndHRP()
                end

                local okSet = pcall(function()
                    hrp.CFrame = points[i]
                end)

                if okSet then
                    teleported = true
                else
                    task.wait(0.1)
                end
            end

            if i < #points then
                sleep(WAIT_SEC)
            end
            i += 1
        end

        resetCharacter()
    end)

    _G.__TP_BUSY = false

    pcall(function()
        if toggleRef and (toggleRef.Set or toggleRef.SetState) then
            (toggleRef.Set or toggleRef.SetState)(toggleRef, false)
        end
    end)

    if not ok then
        warn("runOnceResilient error: " .. tostring(err))
    end
end

local Tab = Window:CreateTab("Auto Summit")
local Section = Tab:CreateSection("- 3xplo Yang Tersedia -")

local AutoSummitYahayuk = {
    CFrame.new(-429.05, 265.50, 788.27), -- Camp 1
    CFrame.new(-359.93, 405.13, 541.62), -- Camp 2
    CFrame.new(288.24,  446.13, 506.28), -- Camp 3
    CFrame.new(336.31,  507.13, 348.97), -- Camp 4
    CFrame.new(224.20, 331.13, -144.73), -- Camp 5
    CFrame.new(-614.06, 904.50, -551.25), -- Summit
    CFrame.new(-674.25, 909.50, -481.76), -- Start
}

local AutoSummitCKPTW = {
    CFrame.new(386.77,308.18,-183.78), -- CP1
    CFrame.new(100.16,410.78,616.67), -- CP2
    CFrame.new(6.61,603.33,996.07), -- CP3
    CFrame.new(871.21,868.46,586.52), -- CP4
    CFrame.new(1612.18,1084.12,159.86), -- CP5
    CFrame.new(2965.00,1531.21,705.93), -- CP6
    CFrame.new(1811.56,1980.17,2166.88), -- SUMMIT
}

local AutoSummitATIN = {
    CFrame.new(-184.15,135.96,408.26), -- CP2
    CFrame.new(-165.85,237.86,652.82), -- CP3
    CFrame.new(-38.09,414.72,616.19), -- CP4
    CFrame.new(129.79,657.62,612.45), -- CP5
    CFrame.new(-247.56,673.80,733.76), -- CP6
    CFrame.new(-683.53,647.78,865.59), -- CP7
    CFrame.new(-658.56,696.34,1458.61), -- CP8
    CFrame.new(-508.22,910.78,1868.44), -- CP9
    CFrame.new(61.01,955.51,2089.64), -- CP10
    CFrame.new(50.73,989.36,2450.35), -- CP11
    CFrame.new(72.75,1104.84,2457.93), -- CP12
    CFrame.new(263.02,1278.07,2036.99), -- CP13
    CFrame.new(-419.41,1310.04,2394.95), -- CP14
    CFrame.new(-773.75,1321.82,2664.02), -- CP15
    CFrame.new(-837.27,1479.91,2626.56), -- CP16
    CFrame.new(-468.61,1473.57,2769.79), -- CP17
    CFrame.new(-468.19,1545.35,2836.32), -- CP18
    CFrame.new(-385.21,1648.19,2793.62), -- CP19
    CFrame.new(-208.67,1673.70,2749.49), -- CP20
    CFrame.new(-233.00,1749.94,2792.68), -- CP21
    CFrame.new(-422.38,1745.45,2797.23), -- CP22
    CFrame.new(-425.31,1721.03,3419.69), -- CP23
    CFrame.new(70.22,1726.61,3427.71), -- CP24
    CFrame.new(436.40,1728.44,3431.17), -- CP25
    CFrame.new(625.72,1807.36,3432.32), -- CP26
    CFrame.new(806.40,2169.73,3897.66), -- SUMMIT
    CFrame.new(112.62,2432.62,3484.93), -- PLANG
    CFrame.new(15.32,54.67,-1081.71), -- Balik Ke Start
}

local AutoSummitMerapi = {
    CFrame.new(-2000.68,1878.72,-268.20), -- Summit
    CFrame.new(-4240.44,13.90,2316.65), -- Basecamp
}

local AutoSummitRinjani = {
    CFrame.new(3353.48,9033.58,5633.81), -- CP1
    CFrame.new(3079.93,9108.74,4455.46), -- CP2
    CFrame.new(1878.50,9553.97,3484.22), -- CP3
    CFrame.new(1370.43,9776.59,3122.20), -- CP4
    CFrame.new(1188.40,10122.28,2291.25), -- CP5
    CFrame.new(-120.01,10832.71,3017.44), -- SUMMIT
    CFrame.new(2693.64,8956.50,7527.51), -- Balik Ke Start
}

local AutoSummitHilih = {
    CFrame.new(444.01,14.01,-606.61), -- CP1
    CFrame.new(-212.45,48.58,-121.66), -- CP2
    CFrame.new(-840.77,35.99,-74.67), -- CP3
    CFrame.new(-710.52,400.87,396.13), -- CP4
    CFrame.new(-343.62,149.93,218.66), -- CP5
    CFrame.new(-371.40,360.07,469.29), -- CP6
    CFrame.new(-73.06,336.25,242.59), -- CP7
    CFrame.new(255.53,527.68,137.86), -- SUMMIT
    CFrame.new(-913.85,23.17,-718.45), -- Balik Ke Start
}

local Toggle_A
Toggle_A = Tab:CreateToggle({
    Name = "Auto Summit Gunung Yahayuk",
    CurrentValue = false,
    Flag = "AutoTP_Toggle_A",
    Callback = function(on)
        if on then
            spawn(function()
                runOnceResilient(AutoSummitYahayuk, Toggle_A)
            end)
        end
    end,
})

local Toggle_B
Toggle_B = Tab:CreateToggle({
    Name = "Auto Summit Gunung CKPTW",
    CurrentValue = false,
    Flag = "AutoTP_Toggle_B",
    Callback = function(on)
        if on then
            spawn(function()
                runOnceResilient(AutoSummitCKPTW, Toggle_B)
            end)
        end
    end,
})

local Toggle_C
Toggle_C = Tab:CreateToggle({
    Name = "Auto Summit Gunung ATIN",
    CurrentValue = false,
    Flag = "AutoTP_Toggle_C",
    Callback = function(on)
        if on then
            spawn(function()
                runOnceResilient(AutoSummitATIN, Toggle_C)
            end)
        end
    end,
})

local Toggle_D
Toggle_D = Tab:CreateToggle({
    Name = "Auto Summit Gunung Merapi (Relog)",
    CurrentValue = false,
    Flag = "AutoTP_Toggle_D",
    Callback = function(on)
        if on then
            spawn(function()
                runOnceResilient(AutoSummitMerapi, Toggle_D)
            end)
        end
    end,
})

local Toggle_E
Toggle_E = Tab:CreateToggle({
    Name = "Auto Summit Gunung Rinjani",
    CurrentValue = false,
    Flag = "AutoTP_Toggle_E",
    Callback = function(on)
        if on then
            spawn(function()
                runOnceResilient(AutoSummitRinjani, Toggle_E)
            end)
        end
    end,
})

local Toggle_F
Toggle_F = Tab:CreateToggle({
    Name = "Auto Summit Gunung Hilih",
    CurrentValue = false,
    Flag = "AutoTP_Toggle_F",
    Callback = function(on)
        if on then
            spawn(function()
                runOnceResilient(AutoSummitHilih, Toggle_F)
            end)
        end
    end,
})

Rayfield:LoadConfiguration()