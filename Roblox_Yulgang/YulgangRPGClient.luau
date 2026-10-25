--!strict
--[[
    YulgangRPGClient.luau (v4 - Authentic PC Yulgang Character Creation & HUD)
    ระบบสร้างตัวละครระดับภาพยนตร์ 3D Cinematic Camera แพนรอบแท่นอาคมยุทธภพ
    พร้อม UI ถอดแบบจากเกม Yulgang PC แท้ 100%
    พัฒนาโดย No B สำหรับเจ้านาย (dj)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local CurrentCamera = workspace.CurrentCamera

local RemoteFolder = ReplicatedStorage:WaitForChild("YulgangRemotes")
local SelectClassEvent = RemoteFolder:WaitForChild("SelectClass") :: RemoteEvent
local UpdateStatsEvent = RemoteFolder:WaitForChild("UpdateStats") :: RemoteEvent
local SkillCastEvent = RemoteFolder:WaitForChild("CastSkill") :: RemoteEvent
local AttackEvent = RemoteFolder:WaitForChild("YulgangAttack") :: RemoteEvent
local NPCTalkEvent = RemoteFolder:WaitForChild("NPCTalk") :: RemoteEvent

-- สร้าง ScreenGui หลัก
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Yulgang_Main_GUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

---------------------------------------------------------
-- 1. Cinematic Camera Controller สำหรับหน้าสร้างตัวละคร
---------------------------------------------------------
local inCharacterCreation = true
local cameraAngle = 0
local cameraTargetPos = Vector3.new(0, 3.5, 0)
local cameraFocusTarget = Vector3.new(0, 3.5, 0)

CurrentCamera.CameraType = Enum.CameraType.Scriptable

local cameraConnection: RBXScriptConnection?
cameraConnection = RunService.RenderStepped:Connect(function(dt)
    if not inCharacterCreation then
        if cameraConnection then
            cameraConnection:Disconnect()
            cameraConnection = nil
        end
        return
    end
    
    cameraAngle += dt * 0.15
    local radius = 28
    local height = 8 + math.sin(cameraAngle * 0.5) * 1.5
    local camX = math.sin(cameraAngle) * radius
    local camZ = math.cos(cameraAngle) * radius
    
    cameraFocusTarget = cameraFocusTarget:Lerp(cameraTargetPos, dt * 4)
    local desiredCFrame = CFrame.new(Vector3.new(camX, height, camZ), cameraFocusTarget)
    CurrentCamera.CFrame = CurrentCamera.CFrame:Lerp(desiredCFrame, dt * 5)
end)

---------------------------------------------------------
-- 2. Authentic Yulgang PC Character Creation UI (หน้าสร้างตัวละคร)
---------------------------------------------------------
local creationContainer = Instance.new("Frame")
creationContainer.Name = "Yulgang_CreationScreen"
creationContainer.Size = UDim2.new(1, 0, 1, 0)
creationContainer.BackgroundTransparency = 1
creationContainer.Parent = screenGui

-- โลโก้ Yulgang ด้านบน
local logoTitle = Instance.new("TextLabel")
logoTitle.Name = "YulgangLogo"
logoTitle.Size = UDim2.new(0, 400, 0, 70)
logoTitle.Position = UDim2.new(0.5, -200, 0, 30)
logoTitle.BackgroundTransparency = 1
logoTitle.Font = Enum.Font.Cinzel or Enum.Font.GothamBold
logoTitle.Text = "Y U L G A N G   O N L I N E"
logoTitle.TextColor3 = Color3.fromRGB(255, 215, 60)
logoTitle.TextSize = 28
logoTitle.Parent = creationContainer

local logoStroke = Instance.new("UIStroke")
logoStroke.Color = Color3.fromRGB(180, 50, 10)
logoStroke.Thickness = 2.5
logoStroke.Parent = logoTitle

local logoSub = Instance.new("TextLabel")
logoSub.Size = UDim2.new(1, 0, 0, 24)
logoSub.Position = UDim2.new(0, 0, 1, -10)
logoSub.BackgroundTransparency = 1
logoSub.Font = Enum.Font.GothamBold
logoSub.Text = "「 ยุทธภพครบสลึง - โยวกังออนไลน์ 」"
logoSub.TextColor3 = Color3.fromRGB(255, 240, 180)
logoSub.TextSize = 14
logoSub.Parent = logoTitle

-- แผงสร้างตัวละครฝั่งซ้าย (Classic Ornate Martial Arts Panel)
local leftPanel = Instance.new("Frame")
leftPanel.Name = "CreationPanel"
leftPanel.Size = UDim2.new(0, 380, 0, 560)
leftPanel.Position = UDim2.new(0, 40, 0.5, -280)
leftPanel.BackgroundColor3 = Color3.fromRGB(12, 16, 26)
leftPanel.BackgroundTransparency = 0.15
leftPanel.BorderSizePixel = 0
leftPanel.Parent = creationContainer

local pCorner = Instance.new("UICorner")
pCorner.CornerRadius = UDim.new(0, 14)
pCorner.Parent = leftPanel

local pStroke = Instance.new("UIStroke")
pStroke.Color = Color3.fromRGB(255, 200, 50)
pStroke.Thickness = 2
pStroke.Parent = leftPanel

-- หัวข้อแผงควบคุม
local headerLbl = Instance.new("TextLabel")
headerLbl.Size = UDim2.new(1, 0, 0, 48)
headerLbl.BackgroundColor3 = Color3.fromRGB(20, 28, 48)
headerLbl.BackgroundTransparency = 0.3
headerLbl.Font = Enum.Font.GothamBold
headerLbl.Text = "📜 บันทึกกำเนิดจอมยุทธ์"
headerLbl.TextColor3 = Color3.fromRGB(255, 220, 90)
headerLbl.TextSize = 18
headerLbl.Parent = leftPanel

local hCorner = Instance.new("UICorner")
hCorner.CornerRadius = UDim.new(0, 14)
hCorner.Parent = headerLbl

-- รายชื่อ 5 สายอาชีพต้นตำรับ Yulgang
local CLASSES = {
    { Id = "Blade",  Name = "ฮันกวาง (นักดาบ)", Icon = "⚔️", Color = Color3.fromRGB(255, 60, 20), HeroName = "ฮันกวาง (นักดาบเพลิง)", Desc = "ดาบมังกรเพลิงพลังโจมตีรุนแรง เลือดเยอะ สกิลหนักหน่วง" },
    { Id = "Sword",  Name = "ฮวาริน (นักกระบี่)", Icon = "🗡️", Color = Color3.fromRGB(40, 160, 255), HeroName = "ฮวาริน (นักกระบี่นางแอ่น)", Desc = "กระบี่วิหคน้ำแข็ง เพลงกระบี่รวดเร็ว คริติคอลพริ้วไหว" },
    { Id = "Spear",  Name = "ทวนพิฆาต (นักทวน)", Icon = "🔱", Color = Color3.fromRGB(255, 180, 30), HeroName = "ทวนพิฆาตมังกร", Desc = "ทวนสุริยัน ระยะสังหารกว้างขวาง ดาเมจทะลุเกราะสูงสุด" },
    { Id = "Bow",    Name = "มือธนูวายุ (นักธนู)", Icon = "🏹", Color = Color3.fromRGB(60, 220, 90), HeroName = "มือธนูวายุสวรรค์", Desc = "ธนูปีกหงส์ โจมตีระยะไกล แม่นยำ ว่องไวไร้รอยต่อ" },
    { Id = "Healer", Name = "หมอเทวะ (นักพรต)", Icon = "📜", Color = Color3.fromRGB(200, 80, 255), HeroName = "นักพรตหมอเทวะ", Desc = "คัมภีร์พุทธรักษา เชี่ยวชาญคาถาอาคม ฮีลรักษา ฟื้นฟูมานา" },
}

local selectedClassId = "Blade"
local selectedGender = "ชาย"

-- รายการปุ่มเลือกอาชีพ
local classListContainer = Instance.new("Frame")
classListContainer.Size = UDim2.new(0.9, 0, 0, 250)
classListContainer.Position = UDim2.new(0.05, 0, 0, 60)
classListContainer.BackgroundTransparency = 1
classListContainer.Parent = leftPanel

local cLayout = Instance.new("UIListLayout")
cLayout.Padding = UDim.new(0, 8)
cLayout.Parent = classListContainer

local classButtons = {}

-- คำอธิบายอาชีพที่เลือก
local descBox = Instance.new("TextLabel")
descBox.Size = UDim2.new(0.9, 0, 0, 65)
descBox.Position = UDim2.new(0.05, 0, 0, 320)
descBox.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
descBox.Font = Enum.Font.Gotham
descBox.Text = CLASSES[1].Desc
descBox.TextColor3 = Color3.fromRGB(200, 215, 235)
descBox.TextSize = 12
descBox.TextWrapped = true
descBox.Parent = leftPanel

local dCorner = Instance.new("UICorner")
dCorner.CornerRadius = UDim.new(0, 8)
dCorner.Parent = descBox

-- แผงเลือกเพศ (จอมยุทธ์ ชาย / หญิง)
local genderFrame = Instance.new("Frame")
genderFrame.Size = UDim2.new(0.9, 0, 0, 38)
genderFrame.Position = UDim2.new(0.05, 0, 0, 395)
genderFrame.BackgroundTransparency = 1
genderFrame.Parent = leftPanel

local maleBtn = Instance.new("TextButton")
maleBtn.Size = UDim2.new(0.48, 0, 1, 0)
maleBtn.BackgroundColor3 = Color3.fromRGB(30, 80, 160)
maleBtn.Font = Enum.Font.GothamBold
maleBtn.Text = "จอมยุทธ์ชาย"
maleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
maleBtn.TextSize = 13
maleBtn.Parent = genderFrame
local mCor = Instance.new("UICorner")
mCor.CornerRadius = UDim.new(0, 8)
mCor.Parent = maleBtn

local femaleBtn = Instance.new("TextButton")
femaleBtn.Size = UDim2.new(0.48, 0, 1, 0)
femaleBtn.Position = UDim2.new(0.52, 0, 0, 0)
femaleBtn.BackgroundColor3 = Color3.fromRGB(40, 45, 65)
femaleBtn.Font = Enum.Font.GothamBold
femaleBtn.Text = "จอมยุทธ์หญิง"
femaleBtn.TextColor3 = Color3.fromRGB(180, 190, 210)
femaleBtn.TextSize = 13
femaleBtn.Parent = genderFrame
local fCor = Instance.new("UICorner")
fCor.CornerRadius = UDim.new(0, 8)
fCor.Parent = femaleBtn

maleBtn.MouseButton1Click:Connect(function()
    selectedGender = "ชาย"
    maleBtn.BackgroundColor3 = Color3.fromRGB(30, 80, 160)
    maleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    femaleBtn.BackgroundColor3 = Color3.fromRGB(40, 45, 65)
    femaleBtn.TextColor3 = Color3.fromRGB(180, 190, 210)
end)

femaleBtn.MouseButton1Click:Connect(function()
    selectedGender = "หญิง"
    femaleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 120)
    femaleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    maleBtn.BackgroundColor3 = Color3.fromRGB(40, 45, 65)
    maleBtn.TextColor3 = Color3.fromRGB(180, 190, 210)
end)

-- ช่องใส่ชื่อจอมยุทธ์
local nameInput = Instance.new("TextBox")
nameInput.Size = UDim2.new(0.9, 0, 0, 40)
nameInput.Position = UDim2.new(0.05, 0, 0, 442)
nameInput.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
nameInput.Font = Enum.Font.GothamBold
nameInput.PlaceholderText = "กรุณาใส่ชื่อจอมยุทธ์..."
nameInput.Text = LocalPlayer.Name
nameInput.TextColor3 = Color3.fromRGB(255, 230, 120)
nameInput.TextSize = 14
nameInput.ClearTextOnFocus = false
nameInput.Parent = leftPanel

local niCorner = Instance.new("UICorner")
niCorner.CornerRadius = UDim.new(0, 8)
niCorner.Parent = nameInput

local niStroke = Instance.new("UIStroke")
niStroke.Color = Color3.fromRGB(100, 120, 160)
niStroke.Thickness = 1
niStroke.Parent = nameInput

-- ปุ่มสร้างตัวละคร / ก้าวสู่ยุทธภพ (Create Character Button)
local createBtn = Instance.new("TextButton")
createBtn.Size = UDim2.new(0.9, 0, 0, 48)
createBtn.Position = UDim2.new(0.05, 0, 1, -58)
createBtn.BackgroundColor3 = Color3.fromRGB(220, 40, 20)
createBtn.Font = Enum.Font.GothamBold
createBtn.Text = "🏮 ก้าวสู่ยุทธภพฮอนบัล (สร้างตัวละคร)"
createBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
createBtn.TextSize = 15
createBtn.Parent = leftPanel

local cbCorner = Instance.new("UICorner")
cbCorner.CornerRadius = UDim.new(0, 10)
cbCorner.Parent = createBtn

local cbStroke = Instance.new("UIStroke")
cbStroke.Color = Color3.fromRGB(255, 215, 0)
cbStroke.Thickness = 2
cbStroke.Parent = createBtn

-- สร้างปุ่มอาชีพแต่ละปุ่ม
for _, c in ipairs(CLASSES) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 42)
    btn.BackgroundColor3 = (c.Id == selectedClassId) and Color3.fromRGB(40, 50, 75) or Color3.fromRGB(20, 24, 35)
    btn.Font = Enum.Font.GothamBold
    btn.Text = `   {c.Icon}  {c.Name}`
    btn.TextColor3 = (c.Id == selectedClassId) and Color3.fromRGB(255, 220, 80) or Color3.fromRGB(180, 190, 210)
    btn.TextSize = 14
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = classListContainer
    
    local bCor = Instance.new("UICorner")
    bCor.CornerRadius = UDim.new(0, 8)
    bCor.Parent = btn
    
    local bStr = Instance.new("UIStroke")
    bStr.Color = (c.Id == selectedClassId) and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(45, 55, 75)
    bStr.Thickness = 1.5
    bStr.Parent = btn
    
    classButtons[c.Id] = { Button = btn, Stroke = bStr, Info = c }
    
    btn.MouseButton1Click:Connect(function()
        selectedClassId = c.Id
        descBox.Text = c.Desc
        
        -- อัปเดตสไตล์ปุ่ม
        for id, item in pairs(classButtons) do
            local isSel = (id == selectedClassId)
            item.Button.BackgroundColor3 = isSel and Color3.fromRGB(40, 50, 75) or Color3.fromRGB(20, 24, 35)
            item.Button.TextColor3 = isSel and Color3.fromRGB(255, 220, 80) or Color3.fromRGB(180, 190, 210)
            item.Stroke.Color = isSel and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(45, 55, 75)
        end
        
        -- แพนกล้องส่องไปยังฮีโร่ตัวนั้นบนแท่นวงแหวนเวทย์
        local roster = workspace:FindFirstChild("Yulgang_Hero_Roster")
        if roster then
            local heroModel = roster:FindFirstChild(c.HeroName)
            if heroModel and heroModel:FindFirstChild("Torso") then
                local torso = heroModel:FindFirstChild("Torso") :: BasePart
                cameraTargetPos = torso.Position
            end
        end
    end)
end

---------------------------------------------------------
-- 3. Classic Yulgang HUD (แสดงผลหลังสร้างตัวละครเสร็จ)
---------------------------------------------------------
local hudFrame = Instance.new("Frame")
hudFrame.Name = "YulgangHUD"
hudFrame.Size = UDim2.new(0, 320, 0, 90)
hudFrame.Position = UDim2.new(0, 24, 0, -120) -- ซ่อนไว้ก่อน
hudFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 25)
hudFrame.BackgroundTransparency = 0.2
hudFrame.Parent = screenGui

local hudCorner = Instance.new("UICorner")
hudCorner.CornerRadius = UDim.new(0, 12)
hudCorner.Parent = hudFrame

local hudStroke = Instance.new("UIStroke")
hudStroke.Color = Color3.fromRGB(255, 215, 0)
hudStroke.Thickness = 1.5
hudStroke.Parent = hudFrame

local nameAndClassLbl = Instance.new("TextLabel")
nameAndClassLbl.Size = UDim2.new(0.7, 0, 0, 24)
nameAndClassLbl.Position = UDim2.new(0, 16, 0, 8)
nameAndClassLbl.BackgroundTransparency = 1
nameAndClassLbl.Font = Enum.Font.GothamBold
nameAndClassLbl.Text = `Lv. 1 {LocalPlayer.Name} (นักดาบ)`
nameAndClassLbl.TextColor3 = Color3.fromRGB(255, 235, 120)
nameAndClassLbl.TextSize = 14
nameAndClassLbl.TextXAlignment = Enum.TextXAlignment.Left
nameAndClassLbl.Parent = hudFrame

local moneyLbl = Instance.new("TextLabel")
moneyLbl.Size = UDim2.new(0.28, 0, 0, 24)
moneyLbl.Position = UDim2.new(0.7, 0, 0, 8)
moneyLbl.BackgroundTransparency = 1
moneyLbl.Font = Enum.Font.GothamBold
moneyLbl.Text = "🪙 500 สลึง"
moneyLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
moneyLbl.TextSize = 12
moneyLbl.Parent = hudFrame

-- แถบ HP
local hpBg = Instance.new("Frame")
hpBg.Size = UDim2.new(0.9, 0, 0, 16)
hpBg.Position = UDim2.new(0.05, 0, 0, 36)
hpBg.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
hpBg.Parent = hudFrame
local hpFill = Instance.new("Frame")
hpFill.Size = UDim2.fromScale(1, 1)
hpFill.BackgroundColor3 = Color3.fromRGB(230, 40, 40)
hpFill.Parent = hpBg
local hpText = Instance.new("TextLabel")
hpText.Size = UDim2.fromScale(1, 1)
hpText.BackgroundTransparency = 1
hpText.Font = Enum.Font.GothamBold
hpText.Text = "HP: 300 / 300"
hpText.TextColor3 = Color3.fromRGB(255, 255, 255)
hpText.TextSize = 11
hpText.Parent = hpBg

-- แถบ MP
local mpBg = Instance.new("Frame")
mpBg.Size = UDim2.new(0.9, 0, 0, 14)
mpBg.Position = UDim2.new(0.05, 0, 0, 58)
mpBg.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
mpBg.Parent = hudFrame
local mpFill = Instance.new("Frame")
mpFill.Size = UDim2.fromScale(1, 1)
mpFill.BackgroundColor3 = Color3.fromRGB(40, 130, 240)
mpFill.Parent = mpBg
local mpText = Instance.new("TextLabel")
mpText.Size = UDim2.fromScale(1, 1)
mpText.BackgroundTransparency = 1
mpText.Font = Enum.Font.GothamBold
mpText.Text = "MP: 80 / 80"
mpText.TextColor3 = Color3.fromRGB(255, 255, 255)
mpText.TextSize = 10
mpText.Parent = mpBg

-- แถบ EXP ด้านล่าง
local expBarBg = Instance.new("Frame")
expBarBg.Size = UDim2.new(0.6, 0, 0, 12)
expBarBg.Position = UDim2.new(0.2, 0, 1, 30) -- ซ่อนไว้ก่อน
expBarBg.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
expBarBg.Parent = screenGui
local expFill = Instance.new("Frame")
expFill.Size = UDim2.fromScale(0.05, 1)
expFill.BackgroundColor3 = Color3.fromRGB(60, 220, 90)
expFill.Parent = expBarBg
local expText = Instance.new("TextLabel")
expText.Size = UDim2.fromScale(1, 1)
expText.BackgroundTransparency = 1
expText.Font = Enum.Font.GothamBold
expText.Text = "EXP: 5.0%"
expText.TextColor3 = Color3.fromRGB(255, 255, 255)
expText.TextSize = 9
expText.Parent = expBarBg

-- สกิล Hotbar [Q], [E], [R]
local hotbarFrame = Instance.new("Frame")
hotbarFrame.Size = UDim2.new(0, 240, 0, 70)
hotbarFrame.Position = UDim2.new(0.5, -120, 1, 100) -- ซ่อนไว้ก่อน
hotbarFrame.BackgroundTransparency = 1
hotbarFrame.Parent = screenGui

local SKILLS = {
    { Key = "Q", Name = "วายุสังหาร", Cost = "15 MP", Slot = 0 },
    { Key = "E", Name = "ค่ายกลสะท้านฟ้า", Cost = "30 MP", Slot = 1 },
    { Key = "R", Name = "ท่าร่างล่องนภา", Cost = "20 MP", Slot = 2 },
}

for _, s in ipairs(SKILLS) do
    local slot = Instance.new("Frame")
    slot.Size = UDim2.new(0, 68, 0, 68)
    slot.Position = UDim2.new(0, s.Slot * 80, 0, 0)
    slot.BackgroundColor3 = Color3.fromRGB(20, 24, 38)
    slot.Parent = hotbarFrame
    
    local sc = Instance.new("UICorner")
    sc.CornerRadius = UDim.new(0, 10)
    sc.Parent = slot
    
    local ss = Instance.new("UIStroke")
    ss.Color = Color3.fromRGB(255, 200, 40)
    ss.Thickness = 1.5
    ss.Parent = slot
    
    local keyBadge = Instance.new("TextLabel")
    keyBadge.Size = UDim2.new(0, 22, 0, 22)
    keyBadge.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
    keyBadge.Font = Enum.Font.GothamBold
    keyBadge.Text = s.Key
    keyBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyBadge.TextSize = 12
    keyBadge.Parent = slot
    local kbc = Instance.new("UICorner")
    kbc.CornerRadius = UDim.new(0, 6)
    kbc.Parent = keyBadge
    
    local sName = Instance.new("TextLabel")
    sName.Size = UDim2.new(1, 0, 0, 24)
    sName.Position = UDim2.new(0, 0, 0.35, 0)
    sName.BackgroundTransparency = 1
    sName.Font = Enum.Font.GothamBold
    sName.Text = s.Name
    sName.TextColor3 = Color3.fromRGB(255, 230, 150)
    sName.TextSize = 10
    sName.Parent = slot
    
    local sCost = Instance.new("TextLabel")
    sCost.Size = UDim2.new(1, 0, 0, 16)
    sCost.Position = UDim2.new(0, 0, 0.72, 0)
    sCost.BackgroundTransparency = 1
    sCost.Font = Enum.Font.Gotham
    sCost.Text = s.Cost
    sCost.TextColor3 = Color3.fromRGB(80, 160, 255)
    sCost.TextSize = 9
    sCost.Parent = slot
end

---------------------------------------------------------
-- 4. ยืนยันการสร้างตัวละคร (Transition to Game World)
---------------------------------------------------------
createBtn.MouseButton1Click:Connect(function()
    createBtn.Active = false
    
    -- แจ้ง Server ให้มอบอาชีพและอาวุธ
    SelectClassEvent:FireServer(selectedClassId)
    
    -- อัปเดตชื่อใน HUD
    local chosenClassInfo = classButtons[selectedClassId].Info
    nameAndClassLbl.Text = `Lv. 1 {nameInput.Text} ({chosenClassInfo.Name})`
    
    -- หน้าจอวาบแสงขาวจำลองการเทเลพอร์ตเข้าสู่เมืองฮอนบัล
    local flash = Instance.new("Frame")
    flash.Size = UDim2.new(1, 0, 1, 0)
    flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    flash.BackgroundTransparency = 1
    flash.ZIndex = 50
    flash.Parent = screenGui
    
    TweenService:Create(flash, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0
    }):Play()
    
    task.wait(0.6)
    
    -- ปิดหน้าต่างสร้างตัวละคร
    creationContainer.Visible = false
    inCharacterCreation = false
    CurrentCamera.CameraType = Enum.CameraType.Custom
    
    -- จางแสงขาวออก
    TweenService:Create(flash, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        BackgroundTransparency = 1
    }):Play()
    
    -- เลื่อน HUD ลงมาจากด้านบน
    TweenService:Create(hudFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 24, 0, 24)
    }):Play()
    
    -- เลื่อน EXP bar ขึ้นมา
    TweenService:Create(expBarBg, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.2, 0, 1, -24)
    }):Play()
    
    -- เลื่อน Hotbar ขึ้นมา
    TweenService:Create(hotbarFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -120, 1, -95)
    }):Play()
    
    task.wait(1.0)
    flash:Destroy()
end)

---------------------------------------------------------
-- 5. ระบบ Event รับค่าจาก Server
---------------------------------------------------------
UpdateStatsEvent.OnClientEvent:Connect(function(data)
    if data.HP and data.MaxHP then
        local ratio = math.clamp(data.HP / data.MaxHP, 0, 1)
        hpFill.Size = UDim2.fromScale(ratio, 1)
        hpText.Text = `HP: {math.floor(data.HP)} / {data.MaxHP}`
    end
    if data.MP and data.MaxMP then
        local ratio = math.clamp(data.MP / data.MaxMP, 0, 1)
        mpFill.Size = UDim2.fromScale(ratio, 1)
        mpText.Text = `MP: {math.floor(data.MP)} / {data.MaxMP}`
    end
    if data.EXP and data.MaxEXP then
        local ratio = math.clamp(data.EXP / data.MaxEXP, 0, 1)
        expFill.Size = UDim2.fromScale(ratio, 1)
        expText.Text = string.format("EXP: %.1f%%", ratio * 100)
    end
    if data.Money then
        moneyLbl.Text = `🪙 {data.Money} สลึง`
    end
    if data.Level then
        nameAndClassLbl.Text = `Lv. {data.Level} {nameInput.Text} ({data.Class})`
    end
end)

-- ควบคุมปุ่มกดสกิล
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or inCharacterCreation then return end
    if input.KeyCode == Enum.KeyCode.Q then
        SkillCastEvent:FireServer("Q")
    elseif input.KeyCode == Enum.KeyCode.E then
        SkillCastEvent:FireServer("E")
    elseif input.KeyCode == Enum.KeyCode.R then
        SkillCastEvent:FireServer("R")
    end
end)
