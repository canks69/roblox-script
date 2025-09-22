-- ServerScriptService/ManualUnban.lua
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

-- Konfigurasi
local BAN_STORE = DataStoreService:GetDataStore("MyGame_BannedUsers_v1") -- ganti sesuai nama DataStore lo
local targetId = 9179551098 -- ganti dengan userId yg mau di-unban

-- Fungsi untuk mendapatkan data dari DataStore dengan retry
local function safeGet(key, retries)
    retries = retries or 3
    for i = 1, retries do
        local ok, res = pcall(function() 
            return BAN_STORE:GetAsync(key) 
        end)
        if ok then
            return res
        else
            warn("DataStore GetAsync failed (attempt " .. i .. "/" .. retries .. "):", res)
            if i < retries then
                wait(1) -- tunggu 1 detik sebelum retry
            end
        end
    end
    return nil
end

-- Fungsi untuk menyimpan data ke DataStore dengan retry
local function safeSet(key, value, retries)
    retries = retries or 3
    for i = 1, retries do
        local ok, res = pcall(function() 
            BAN_STORE:SetAsync(key, value) 
        end)
        if ok then
            return true
        else
            warn("DataStore SetAsync failed (attempt " .. i .. "/" .. retries .. "):", res)
            if i < retries then
                wait(1) -- tunggu 1 detik sebelum retry
            end
        end
    end
    return false
end

-- Validasi targetId
if type(targetId) ~= "number" or targetId <= 0 then
    error("Invalid targetId: " .. tostring(targetId))
end

print("Starting unban process for UserID:", targetId)

-- Ambil data ban dari DataStore
local bans = safeGet("bans")
if not bans then
    warn("Failed to retrieve ban data from DataStore after multiple attempts")
    return
end

-- Pastikan bans adalah table
if type(bans) ~= "table" then
    bans = {}
end

local targetIdStr = tostring(targetId)

-- Cek apakah user ter-ban
if bans[targetIdStr] then
    print("Found ban entry for UserID", targetId)
    print("Ban details:", bans[targetIdStr])
    
    -- Hapus ban entry
    bans[targetIdStr] = nil
    
    -- Simpan kembali ke DataStore
    if safeSet("bans", bans) then
        print("✅ SUCCESS: User", targetId, "has been unbanned successfully!")
        
        -- Jika player sedang online, kick mereka agar bisa join kembali
        local player = Players:GetPlayerByUserId(targetId)
        if player then
            print("Player is currently online. Kicking to refresh ban status...")
            player:Kick("You have been unbanned! Please rejoin the game.")
        end
    else
        warn("❌ FAILED: Could not save unban to DataStore after multiple attempts")
    end
else
    print("ℹ️  No ban entry found for UserID", targetId, "- User is not banned or already unbanned")
end

print("Unban process completed.")