-- ============================================================
--  Kavo UI (Clean & Optimized Edition) — Example Usage
--  ANON
-- ============================================================

-- วิธีที่ 1: โหลดจากไฟล์ภายในเครื่อง (ปลอดภัย 100% ไม่ต้องดึงเน็ต)
local Kavo = loadfile("Kavo_Clean.lua")()

-- หรือหากใช้ readfile:
-- local Kavo = loadstring(readfile("Kavo_Clean.lua"))()

-- 1. สร้าง Window (ธีมที่มี: DarkTheme, LightTheme, BloodTheme, GrapeTheme, Ocean, Midnight, Sentinel, Synapse, Serpent)
local Window = Kavo.CreateLib("R1 Battle Royale — Dashboard", "BloodTheme")

-- 2. สร้าง Tab ต่างๆ
local MainTab   = Window:NewTab("Main")
local VisualTab = Window:NewTab("Visuals")
local SettingsTab = Window:NewTab("Settings")

-- 3. สร้าง Section ภายใน Tab
local CombatSection = MainTab:NewSection("Combat")
local ESPSection    = VisualTab:NewSection("ESP Settings")
local ConfigSection = SettingsTab:NewSection("Menu Config")

-- 4. องค์ประกอบ UI (Elements)

-- Button
CombatSection:NewButton("Reset Camera", "Reset camera view angle", function()
    workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position)
end)

-- Toggle
local espEnabled = false
ESPSection:NewToggle("Enable ESP", "Show player outlines", function(state)
    espEnabled = state
    print("[UI] ESP State:", state)
end)

-- Slider
ESPSection:NewSlider("Max Distance", "Filter ESP distance (Studs)", 2000, 100, function(value)
    print("[UI] ESP Max Distance:", value)
end)

-- Dropdown
ESPSection:NewDropdown("Box Style", "Choose ESP box styling", {"2D Box", "Corner Box", "Chams"}, function(choice)
    print("[UI] Selected ESP Style:", choice)
end)

-- Keybind Toggle
ConfigSection:NewKeybind("Toggle Menu Key", "Hide/Show this menu", Enum.KeyCode.RightShift, function()
    Kavo:ToggleUI()
end)

print("[ANON] Kavo UI initialized cleanly.")
