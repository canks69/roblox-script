-- Script untuk mengambil posisi setiap perpindahan dan mengirim ke Telegram Bot
-- Position tracker and Telegram sender with Rayfield UI

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

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

-- Variabel untuk Rayfield UI
local Window = nil
local statusLabel = nil
local Tab = nil

-- Membuat Rayfield UI
local function createRayfieldGUI()
    -- Create Main Window
    Window = Rayfield:CreateWindow({
        Name = "🎮 Position Tracker",
        LoadingTitle = "Position Tracker",
        LoadingSubtitle = "by Canks69",
        Theme = "Ocean", -- Ocean, DarkBlue, Amethyst, etc.
        DisableRayfieldPrompts = false,
        DisableBuildWarnings = false,
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "PositionTracker",
            FileName = "config"
        },
        Discord = {
            Enabled = false
        },
        KeySystem = false
    })
    
    -- Create Main Tab
    Tab = Window:CreateTab("🎯 Main Controls", 4483362458)
    
    -- Status Section
    Tab:CreateSection("📊 Status Information")
    
    statusLabel = Tab:CreateLabel("⏹️ Status: Stopped | Movements: 0 | Positions: 0")
    
    -- Settings Section  
    Tab:CreateSection("⚙️ Settings")
    
    local thresholdSlider = Tab:CreateSlider({
        Name = "📏 Movement Threshold (studs)",
        Range = {1, 20},
        Increment = 1,
        Suffix = " studs",
        CurrentValue = positionThreshold,
        Flag = "ThresholdSlider",
        Callback = function(Value)
            positionThreshold = Value
            print("📏 Movement threshold set to: " .. Value .. " studs")
        end,
    })
    
    local intervalSlider = Tab:CreateSlider({
        Name = "⏱️ Send Interval (seconds)",
        Range = {10, 300},
        Increment = 10,
        Suffix = " sec",
        CurrentValue = sendInterval,
        Flag = "IntervalSlider", 
        Callback = function(Value)
            sendInterval = Value
            print("⏱️ Send interval set to: " .. Value .. " seconds")
        end,
    })
    
    -- Control Section
    Tab:CreateSection("🎮 Controls")
    
    -- Start/Stop Toggle
    local trackingToggle = Tab:CreateToggle({
        Name = "▶️ Start Position Tracking",
        CurrentValue = false,
        Flag = "TrackingToggle",
        Callback = function(Value)
            if Value then
                startTracking()
            else
                stopTracking()
            end
        end,
    })
    
    -- Control Buttons
    local playButton = Tab:CreateButton({
        Name = "▶️ Start Tracking",
        Callback = function()
            startTracking()
            trackingToggle:Set(true)
        end,
    })
    
    local stopButton = Tab:CreateButton({
        Name = "⏹️ Stop Tracking", 
        Callback = function()
            stopTracking()
            trackingToggle:Set(false)
        end,
    })
    
    local resetButton = Tab:CreateButton({
        Name = "🔄 Reset Data",
        Callback = function()
            resetData()
            trackingToggle:Set(false)
            Rayfield:Notify({
                Title = "Data Reset",
                Content = "All position data has been cleared!",
                Duration = 3,
                Image = 4483362458,
            })
        end,
    })
    
    local sendButton = Tab:CreateButton({
        Name = "📤 Send to Telegram",
        Callback = function()
            local success = sendManualUpdate()
            if success then
                Rayfield:Notify({
                    Title = "Message Sent",
                    Content = "Position data sent to Telegram successfully!",
                    Duration = 3,
                    Image = 4483362458,
                })
            else
                Rayfield:Notify({
                    Title = "Send Failed",
                    Content = "Failed to send message to Telegram!",
                    Duration = 5,
                    Image = 4483362458,
                })
            end
        end,
    })
    
    -- Information Tab
    local InfoTab = Window:CreateTab("📊 Information", 4483362458)
    
    InfoTab:CreateSection("📈 Session Statistics")
    
    local movementsLabel = InfoTab:CreateLabel("📍 Total Movements: 0")
    local positionsLabel = InfoTab:CreateLabel("📊 Positions Recorded: 0") 
    local sessionLabel = InfoTab:CreateLabel("⏰ Session Started: " .. os.date("%H:%M:%S"))
    local lastPosLabel = InfoTab:CreateLabel("📍 Last Position: Not available")
    
    InfoTab:CreateSection("⚙️ Current Settings")
    
    local thresholdInfo = InfoTab:CreateLabel("📏 Movement Threshold: " .. positionThreshold .. " studs")
    local intervalInfo = InfoTab:CreateLabel("⏱️ Send Interval: " .. sendInterval .. " seconds")
    local botInfo = InfoTab:CreateLabel("🤖 Bot Status: Connected")
    
    -- Telegram Tab
    local TelegramTab = Window:CreateTab("📱 Telegram", 4483362458)
    
    TelegramTab:CreateSection("🤖 Bot Configuration")
    
    TelegramTab:CreateLabel("🆔 Bot Token: " .. TELEGRAM_BOT_TOKEN:sub(1, 20) .. "...")
    TelegramTab:CreateLabel("💬 Chat ID: " .. TELEGRAM_CHAT_ID)
    
    local testButton = TelegramTab:CreateButton({
        Name = "🧪 Test Bot Connection",
        Callback = function()
            local testSuccess = sendToTelegram("🧪 *Test Message*\n\n✅ Bot connection is working!\n📅 " .. os.date("%Y-%m-%d %H:%M:%S"))
            if testSuccess then
                Rayfield:Notify({
                    Title = "Test Successful",
                    Content = "Test message sent to Telegram!",
                    Duration = 3,
                    Image = 4483362458,
                })
            else
                Rayfield:Notify({
                    Title = "Test Failed", 
                    Content = "Failed to send test message!",
                    Duration = 5,
                    Image = 4483362458,
                })
            end
        end,
    })
    
    TelegramTab:CreateSection("📋 Message Preview")
    
    local previewButton = TelegramTab:CreateButton({
        Name = "👁️ Preview Message Format",
        Callback = function()
            local previewMessage = createTelegramMessage()
            print("📋 Message Preview:")
            print(previewMessage)
            Rayfield:Notify({
                Title = "Preview Generated",
                Content = "Check console for message preview!",
                Duration = 3,
                Image = 4483362458,
            })
        end,
    })
    
    -- Advanced Tab
    local AdvancedTab = Window:CreateTab("⚙️ Advanced", 4483362458)
    
    AdvancedTab:CreateSection("🎨 UI Theme")
    
    local themeDropdown = AdvancedTab:CreateDropdown({
        Name = "Select UI Theme",
        Options = {"Ocean", "DarkBlue", "Amethyst", "Green", "Light"},
        CurrentOption = "Ocean",
        Flag = "ThemeDropdown",
        Callback = function(Option)
            -- Note: Theme change requires UI reload
            Rayfield:Notify({
                Title = "Theme Changed",
                Content = "Restart script to apply " .. Option .. " theme!",
                Duration = 5,
                Image = 4483362458,
            })
        end,
    })
    
    AdvancedTab:CreateSection("🔧 Advanced Settings")
    
    local debugToggle = AdvancedTab:CreateToggle({
        Name = "🐛 Debug Mode",
        CurrentValue = false,
        Flag = "DebugToggle",
        Callback = function(Value)
            if Value then
                print("🐛 Debug mode enabled")
            else
                print("🐛 Debug mode disabled")  
            end
        end,
    })
    
    local autoSendToggle = AdvancedTab:CreateToggle({
        Name = "📤 Auto Send to Telegram",
        CurrentValue = true,
        Flag = "AutoSendToggle",
        Callback = function(Value)
            if Value then
                print("📤 Auto send enabled")
            else
                print("📤 Auto send disabled")
            end
        end,
    })
    
    AdvancedTab:CreateSection("📊 Export Data")
    
    local exportButton = AdvancedTab:CreateButton({
        Name = "💾 Export Position Data",
        Callback = function()
            local exportData = "Position Data Export\n"
            exportData = exportData .. "Player: " .. positionData.playerName .. "\n"
            exportData = exportData .. "Total Movements: " .. positionData.totalMovements .. "\n"
            exportData = exportData .. "Session Start: " .. os.date("%Y-%m-%d %H:%M:%S", positionData.startTime) .. "\n\n"
            exportData = exportData .. "Positions:\n"
            
            for i, pos in ipairs(positionData.positions) do
                exportData = exportData .. string.format("%d. %s - %s (Distance: %.2f)\n", 
                    i, 
                    os.date("%H:%M:%S", pos.timestamp),
                    formatPosition(pos.position),
                    pos.distance
                )
            end
            
            print("💾 POSITION DATA EXPORT:")
            print(exportData)
            
            Rayfield:Notify({
                Title = "Data Exported",
                Content = "Check console for exported position data!",
                Duration = 3,
                Image = 4483362458,
            })
        end,
    })
    
    local clearAllButton = AdvancedTab:CreateButton({
        Name = "🗑️ Clear All Data & Reset",
        Callback = function()
            resetData()
            Rayfield:Notify({
                Title = "Complete Reset",
                Content = "All data cleared and tracking stopped!",
                Duration = 3,
                Image = 4483362458,
            })
        end,
    })
    
    -- Fungsi untuk update status label
    function updateStatusLabel()
        local statusText = ""
        if isTracking then
            statusText = "▶️ Status: Tracking"
        else
            statusText = "⏹️ Status: Stopped"
        end
        
        statusText = statusText .. " | Movements: " .. positionData.totalMovements .. " | Positions: " .. #positionData.positions
        
        if statusLabel then
            statusLabel:Set(statusText)
        end
        
        -- Update information tab labels
        if movementsLabel then movementsLabel:Set("📍 Total Movements: " .. positionData.totalMovements) end
        if positionsLabel then positionsLabel:Set("📊 Positions Recorded: " .. #positionData.positions) end
        if sessionLabel then sessionLabel:Set("⏰ Session Started: " .. os.date("%H:%M:%S", positionData.startTime)) end
        if lastPosLabel and humanoidRootPart then 
            lastPosLabel:Set("📍 Last Position: " .. formatPosition(humanoidRootPart.Position))
        end
        if thresholdInfo then thresholdInfo:Set("📏 Movement Threshold: " .. positionThreshold .. " studs") end
        if intervalInfo then intervalInfo:Set("⏱️ Send Interval: " .. sendInterval .. " seconds") end
    end
    
    -- Update status setiap detik
    spawn(function()
        while Window do
            updateStatusLabel()
            wait(1)
        end
    end)
    
    -- Initial status update
    updateStatusLabel()
    
    print("🎮 Rayfield Position Tracker GUI loaded successfully!")
end

-- Fungsi untuk membuat updateStatusLabel global (fallback)
function updateStatusLabel()
    -- This will be overridden by the Rayfield GUI function
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
        createRayfieldGUI()
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

-- Fungsi untuk membuat updateStatusLabel global (fallback)
function updateStatusLabel()
    -- This will be overridden by the Rayfield GUI function
end

-- Startup
print("🚀 Position Tracker with Rayfield UI Started!")
print("💬 Commands: /play, /stop, /sendpos, /clearpos, /posinfo, /gui")
print("🎮 Loading Rayfield UI...")

-- Kirim pesan startup ke Telegram
local startupMessage = "🚀 *Position Tracker Started*\n\n" ..
                      "👤 Player: " .. player.Name .. "\n" ..
                      "⏰ Started at: " .. os.date("%H:%M:%S") .. "\n" ..
                      "📏 Movement threshold: " .. positionThreshold .. " studs\n" ..
                      "⏱️ Send interval: " .. sendInterval .. " seconds\n" ..
                      "🎮 UI: Rayfield Professional Interface"

sendToTelegram(startupMessage)

-- Auto-create Rayfield GUI setelah 2 detik
wait(2)
createRayfieldGUI()