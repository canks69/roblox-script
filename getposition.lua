-- Script untuk mengambil posisi setiap perpindahan dan mengirim ke Telegram Bot
-- Position tracker and Telegram sender

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- Konfigurasi Telegram Bot
local TELEGRAM_BOT_TOKEN = "8299595872:AAHsPtqWfjsT3N2AlGy6QBxmXN3CM3PPl1Y" -- Token bot Telegram Anda
local TELEGRAM_CHAT_ID = "6817556043" -- Ganti dengan chat ID Anda

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

-- Main tracking loop
local connection
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

-- Commands untuk kontrol manual
game.Players.LocalPlayer.Chatted:Connect(function(message)
    if message:lower() == "/sendpos" then
        sendManualUpdate()
    elseif message:lower() == "/clearpos" then
        clearPositionData()
    elseif message:lower() == "/posinfo" then
        print("📊 Total Movements: " .. positionData.totalMovements)
        print("📍 Positions Recorded: " .. #positionData.positions)
        print("⏰ Session Start: " .. os.date("%H:%M:%S", positionData.startTime))
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

-- Pesan startup
print("🚀 Position Tracker Started!")
print("💬 Commands: /sendpos, /clearpos, /posinfo")
print("⚙️ Jangan lupa set TELEGRAM_BOT_TOKEN dan TELEGRAM_CHAT_ID!")

-- Kirim pesan startup ke Telegram
local startupMessage = "🚀 *Position Tracker Started*\n\n" ..
                      "👤 Player: " .. player.Name .. "\n" ..
                      "⏰ Started at: " .. os.date("%H:%M:%S") .. "\n" ..
                      "📏 Movement threshold: " .. positionThreshold .. " studs\n" ..
                      "⏱️ Send interval: " .. sendInterval .. " seconds"

sendToTelegram(startupMessage)