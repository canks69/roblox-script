local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Konfigurasi nama baru
local newDisplayName = "MountainClimber"
local newUsername = "AutoClimber_" .. math.random(1000, 9999)

-- Function untuk ganti display name
local function changeDisplayName()
    if LocalPlayer then
        LocalPlayer.DisplayName = newDisplayName
        print("✅ Display name diganti ke: " .. newDisplayName)
    end
end

-- Function untuk ganti username (hanya visual di client)
local function changeUsername()
    if LocalPlayer then
        -- Ini hanya mengubah tampilan username di client
        LocalPlayer.Name = newUsername
        print("✅ Username diganti ke: " .. newUsername)
    end
end

-- Function untuk reset nama ke original
local function resetNames()
    if LocalPlayer then
        -- Reset ke nama asli (mungkin tidak selalu berhasil)
        LocalPlayer.DisplayName = LocalPlayer.Name
        print("🔄 Nama direset ke asli")
    end
end

-- Jalankan perubahan nama
print("🔧 Mengubah nama player...")
changeDisplayName()
task.wait(0.5)
changeUsername()

-- Update nama saat character respawn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1) -- tunggu sebentar setelah spawn
    print("🔄 Character respawn - mengupdate nama...")
    changeDisplayName()
    changeUsername()
end)

print("✨ Script replace nama aktif!")
print("💡 Untuk reset nama, jalankan: resetNames()")

-- Export functions agar bisa dipanggil manual
_G.changeDisplayName = changeDisplayName
_G.changeUsername = changeUsername
_G.resetNames = resetNames
