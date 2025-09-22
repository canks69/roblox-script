-- ServerScriptService/ManualUnban.lua
local DataStoreService = game:GetService("DataStoreService")
local BAN_STORE = DataStoreService:GetDataStore("MyGame_BannedUsers_v1") -- ganti sesuai nama DataStore lo
local targetId = 9179551098 -- ganti dengan userId yg mau di-unban

local function safeGet(key)
    local ok, res = pcall(function() return BAN_STORE:GetAsync(key) end)
    if not ok then
        warn("DataStore GetAsync failed:", res)
        return nil
    end
    return res
end

local function safeSet(key, value)
    local ok, res = pcall(function() BAN_STORE:SetAsync(key, value) end)
    if not ok then
        warn("DataStore SetAsync failed:", res)
        return false
    end
    return true
end

local bans = safeGet("bans") or {}

if bans[tostring(targetId)] then
    print("Found ban entry for", targetId, "- removing...")
    bans[tostring(targetId)] = nil
    if safeSet("bans", bans) then
        print("Unban saved to DataStore. User is now unbanned.")
    else
        warn("Failed to save unban to DataStore.")
    end
else
    print("No ban entry found for", targetId)
end