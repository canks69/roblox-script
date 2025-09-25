-- Script untuk mengambil posisi setiap perpindahan dan mengirim ke Telegram Bot
-- Position tracker and Telegram sender with GUI Controls

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Konfigurasi Telegram Bot
local TELEGRAM_BOT_TOKEN = "8299595872:AAG9ts0PzEnagQGbYPtUa2vDseqjvL5pi2w" -- Token bot Telegram Anda
local TELEGRAM_CHAT_ID = "1222630961" -- Ganti dengan chat ID Anda

-- Variabel untuk tracking posisi
local player = Players.LocalPlayer
local character = player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local positionData = {
    playerName = player.Name,
    positions = {},
    startTime = os.time(),
    totalMovements = 0
}

local lastPosition = humanoidRootPart.Position
local positionThreshold = 5 -- Minimum jarak perpindahan untuk dianggap sebagai movement (studs)
local sendInterval = 30 -- Interval pengiriman ke Telegram (detik)
local lastSendTime = os.time()

-- Variabel kontrol
local isTracking = false
local connection = nil

-- Fungsi untuk mengirim data ke Telegram
local function sendToTelegram(message)
    local url = "https://api.telegram.org/bot" .. TELEGRAM_BOT_TOKEN .. "/sendMessage"
    local data = {
        chat_id = TELEGRAM_CHAT_ID,
        text = message,
        parse_mode = "Markdown"
    }
    
    local success, response = pcall(function()
        return HttpService:PostAsync(url, HttpService:JSONEncode(data), Enum.HttpContentType.ApplicationJson)
    end)
    
    if success then
        print("✅ Data berhasil dikirim ke Telegram")
        return true
    else
        warn("❌ Gagal mengirim ke Telegram: " .. tostring(response))
        return false
    end
end

-- Fungsi untuk format posisi
local function formatPosition(pos)
    return string.format("X: %.2f, Y: %.2f, Z: %.2f", pos.X, pos.Y, pos.Z)
end

-- Fungsi untuk menghitung jarak
local function getDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

-- Fungsi untuk membuat pesan Telegram
local function createTelegramMessage()
    local message = "🎮 *Roblox Position Tracker*\n\n"
    message = message .. "👤 *Player:* " .. positionData.playerName .. "\n"
    message = message .. "📊 *Total Movements:* " .. positionData.totalMovements .. "\n"
    message = message .. "⏰ *Session Start:* " .. os.date("%H:%M:%S", positionData.startTime) .. "\n\n"
    
    if #positionData.positions > 0 then
        message = message .. "📍 *Recent Positions:*\n"
        
        -- Tampilkan 10 posisi terakhir
        local startIndex = math.max(1, #positionData.positions - 9)
        for i = startIndex, #positionData.positions do
            local pos = positionData.positions[i]
            message = message .. string.format("• %s - %s\n", 
                os.date("%H:%M:%S", pos.timestamp), 
                formatPosition(pos.position)
            )
        end
        
        if #positionData.positions > 10 then
            message = message .. "\n📝 *(" .. (#positionData.positions - 10) .. " posisi lainnya tersimpan)*"
        end
    else
        message = message .. "📍 *No movements recorded yet*"
    end
    
    return message
end

-- Fungsi untuk menambah posisi baru
local function addPosition(newPosition)
    local positionEntry = {
        position = newPosition,
        timestamp = os.time(),
        distance = getDistance(newPosition, lastPosition)
    }
    
    table.insert(positionData.positions, positionEntry)
    positionData.totalMovements = positionData.totalMovements + 1
    lastPosition = newPosition
    
    print(string.format("📍 Movement #%d: %s (Distance: %.2f studs)", 
        positionData.totalMovements, 
        formatPosition(newPosition),
        positionEntry.distance
    ))
end

-- Fungsi untuk mengirim data secara berkala
local function sendPeriodicUpdate()
    local currentTime = os.time()
    if currentTime - lastSendTime >= sendInterval then
        if positionData.totalMovements > 0 then
            local message = createTelegramMessage()
            sendToTelegram(message)
        end
        lastSendTime = currentTime
    end
end

-- Event handler untuk character respawn
local function onCharacterAdded(newCharacter)
    character = newCharacter
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    lastPosition = humanoidRootPart.Position
    
    print("🔄 Character respawned, position tracking resumed")
end

-- Setup event listeners
player.CharacterAdded:Connect(onCharacterAdded)

-- Fungsi untuk memulai tracking
local function startTracking()
    if not isTracking then
        isTracking = true
        connection = RunService.Heartbeat:Connect(function()
            if character and humanoidRootPart and humanoidRootPart.Parent then
                local currentPosition = humanoidRootPart.Position
                local distance = getDistance(currentPosition, lastPosition)
                
                -- Cek apakah player sudah bergerak cukup jauh
                if distance >= positionThreshold then
                    addPosition(currentPosition)
                end
                
                -- Kirim update berkala
                sendPeriodicUpdate()
            end
        end)
        print("▶️ Position tracking started")
        updateStatusLabel()
    end
end

-- Fungsi untuk menghentikan tracking
local function stopTracking()
    if isTracking and connection then
        isTracking = false
        connection:Disconnect()
        connection = nil
        print("⏹️ Position tracking stopped")
        updateStatusLabel()
    end
end

-- Fungsi untuk reset data
local function resetData()
    stopTracking()
    clearPositionData()
    print("🔄 Data reset and tracking stopped")
    updateStatusLabel()
end

-- Fungsi untuk mengirim data manual
local function sendManualUpdate()
    local message = createTelegramMessage()
    return sendToTelegram(message)
end

-- Fungsi untuk clear data posisi
local function clearPositionData()
    positionData.positions = {}
    positionData.totalMovements = 0
    positionData.startTime = os.time()
    print("🗑️ Position data cleared")
end

-- Membuat GUI
local function createGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PositionTrackerGUI"
    screenGui.Parent = player:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false
    
    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Parent = screenGui
    mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    mainFrame.BorderSizePixel = 0
    mainFrame.Position = UDim2.new(0, 20, 0, 20)
    mainFrame.Size = UDim2.new(0, 300, 0, 250)
    
    -- Corner untuk frame utama
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame
    
    -- Shadow effect
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Parent = screenGui
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.7
    shadow.BorderSizePixel = 0
    shadow.Position = UDim2.new(0, 25, 0, 25)
    shadow.Size = UDim2.new(0, 300, 0, 250)
    shadow.ZIndex = mainFrame.ZIndex - 1
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 12)
    shadowCorner.Parent = shadow
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Parent = mainFrame
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.Size = UDim2.new(1, 0, 0, 40)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = "🎮 Position Tracker"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 16
    
    -- Status Label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Parent = mainFrame
    statusLabel.BackgroundTransparency = 1
    statusLabel.Position = UDim2.new(0, 10, 0, 40)
    statusLabel.Size = UDim2.new(1, -20, 0, 25)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Text = "⏹️ Status: Stopped"
    statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    statusLabel.TextSize = 12
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Info Label
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Name = "InfoLabel"
    infoLabel.Parent = mainFrame
    infoLabel.BackgroundTransparency = 1
    infoLabel.Position = UDim2.new(0, 10, 0, 65)
    infoLabel.Size = UDim2.new(1, -20, 0, 60)
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.Text = "📊 Movements: 0\n📍 Positions: 0\n⏰ Session: " .. os.date("%H:%M:%S")
    infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    infoLabel.TextSize = 10
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.TextYAlignment = Enum.TextYAlignment.Top
    
    -- Fungsi untuk update status label
    function updateStatusLabel()
        if isTracking then
            statusLabel.Text = "▶️ Status: Tracking"
            statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        else
            statusLabel.Text = "⏹️ Status: Stopped"
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
        
        infoLabel.Text = string.format("📊 Movements: %d\n📍 Positions: %d\n⏰ Session: %s",
            positionData.totalMovements,
            #positionData.positions,
            os.date("%H:%M:%S", positionData.startTime)
        )
    end
    
    -- Fungsi untuk membuat tombol
    local function createButton(name, text, position, color, callback)
        local button = Instance.new("TextButton")
        button.Name = name
        button.Parent = mainFrame
        button.BackgroundColor3 = color
        button.BorderSizePixel = 0
        button.Position = position
        button.Size = UDim2.new(0, 65, 0, 30)
        button.Font = Enum.Font.GothamBold
        button.Text = text
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = 11
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 6)
        buttonCorner.Parent = button
        
        -- Hover effect
        button.MouseEnter:Connect(function()
            local tween = TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.new(color.R + 0.1, color.G + 0.1, color.B + 0.1)})
            tween:Play()
        end)
        
        button.MouseLeave:Connect(function()
            local tween = TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = color})
            tween:Play()
        end)
        
        button.MouseButton1Click:Connect(callback)
        
        return button
    end
    
    -- Tombol Play
    createButton("PlayButton", "▶️ Play", UDim2.new(0, 10, 0, 140), Color3.fromRGB(46, 125, 50), function()
        startTracking()
    end)
    
    -- Tombol Stop
    createButton("StopButton", "⏹️ Stop", UDim2.new(0, 85, 0, 140), Color3.fromRGB(198, 40, 40), function()
        stopTracking()
    end)
    
    -- Tombol Reset
    createButton("ResetButton", "🔄 Reset", UDim2.new(0, 160, 0, 140), Color3.fromRGB(255, 152, 0), function()
        resetData()
    end)
    
    -- Tombol Send
    createButton("SendButton", "📤 Send", UDim2.new(0, 235, 0, 140), Color3.fromRGB(33, 150, 243), function()
        sendManualUpdate()
    end)
    
    -- Tombol Close (X)
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Parent = mainFrame
    closeButton.BackgroundColor3 = Color3.fromRGB(198, 40, 40)
    closeButton.BorderSizePixel = 0
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 14
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 15)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        stopTracking()
        screenGui:Destroy()
        shadow:Destroy()
    end)
    
    -- Draggable functionality
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)
    
    mainFrame.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            shadow.Position = UDim2.new(mainFrame.Position.X.Scale, mainFrame.Position.X.Offset + 5, mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset + 5)
        end
    end)
    
    mainFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    -- Update info setiap detik
    spawn(function()
        while screenGui.Parent do
            updateStatusLabel()
            wait(1)
        end
    end)
    
    -- Initial update
    updateStatusLabel()
end

-- Commands untuk kontrol manual (backup)
game.Players.LocalPlayer.Chatted:Connect(function(message)
    if message:lower() == "/sendpos" then
        sendManualUpdate()
    elseif message:lower() == "/clearpos" then
        resetData()
    elseif message:lower() == "/posinfo" then
        print("📊 Total Movements: " .. positionData.totalMovements)
        print("📍 Positions Recorded: " .. #positionData.positions)
        print("⏰ Session Start: " .. os.date("%H:%M:%S", positionData.startTime))
    elseif message:lower() == "/play" then
        startTracking()
    elseif message:lower() == "/stop" then
        stopTracking()
    elseif message:lower() == "/gui" then
        createGUI()
    end
end)

-- Cleanup saat script dihentikan
game:BindToClose(function()
    if connection then
        connection:Disconnect()
    end
    
    -- Kirim data terakhir sebelum keluar
    if positionData.totalMovements > 0 then
        local finalMessage = "🔴 *Session Ended*\n\n" .. createTelegramMessage()
        sendToTelegram(finalMessage)
    end
end)

-- Fungsi untuk membuat updateStatusLabel global
function updateStatusLabel()
    -- This will be overridden by the GUI function
end

-- Startup
print("🚀 Position Tracker Started!")
print("💬 Commands: /play, /stop, /sendpos, /clearpos, /posinfo, /gui")
print("🎮 GUI akan otomatis muncul!")

-- Kirim pesan startup ke Telegram
local startupMessage = "🚀 *Position Tracker Started*\n\n" ..
                      "👤 Player: " .. player.Name .. "\n" ..
                      "⏰ Started at: " .. os.date("%H:%M:%S") .. "\n" ..
                      "📏 Movement threshold: " .. positionThreshold .. " studs\n" ..
                      "⏱️ Send interval: " .. sendInterval .. " seconds\n" ..
                      "🎮 GUI Controls: Play, Stop, Reset, Send"

sendToTelegram(startupMessage)

-- Auto-create GUI setelah 2 detik
wait(2)
createGUI()