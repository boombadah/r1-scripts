-- R1 Battle Royale ESP + GUI Menu
-- cook45 | RightShift = toggle menu

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- cleanup old instance
for _, v in ipairs(gethui():GetChildren()) do
    if v.Name == "R1_ESP_Menu" then v:Destroy() end
end

-- ============================================================
-- CONFIG
-- ============================================================
local CFG = {
    Enabled       = true,
    BoxESP        = true,
    NameESP       = true,
    HealthBar     = true,
    DistanceESP   = true,
    TracerESP     = false,
    MaxDistance   = 2000,

    ColorEnemy    = Color3.fromRGB(255, 60,  60),
    ColorLowHP    = Color3.fromRGB(255, 165,  0),
    ColorDead     = Color3.fromRGB(120, 120, 120),
    ColorTracer   = Color3.fromRGB(255, 255,  0),
    ColorHealthHi = Color3.fromRGB(0,   255,  80),
    ColorHealthLo = Color3.fromRGB(255, 60,   60),
    BoxThickness  = 1.5,
    TextSize      = 13,
    TracerOrigin  = "Bottom",
}

-- ============================================================
-- GUI MENU
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "R1_ESP_Menu"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = gethui()

-- Main frame
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 220, 0, 280)
Frame.Position = UDim2.new(0, 20, 0.5, -140)
Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Frame.BorderSizePixel = 0
Frame.Visible = false
Frame.Parent = ScreenGui

Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)

-- Stroke
local stroke = Instance.new("UIStroke", Frame)
stroke.Color = Color3.fromRGB(255, 60, 60)
stroke.Thickness = 1.5

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 32)
TitleBar.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Frame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 8)

-- fix bottom corners of titlebar
local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 8)
TitleFix.Position = UDim2.new(0, 0, 1, -8)
TitleFix.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text = "R1 ESP  •  cook45"
TitleLabel.Size = UDim2.new(1, -10, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3 = Color3.new(1,1,1)
TitleLabel.TextSize = 14
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local HintLabel = Instance.new("TextLabel")
HintLabel.Text = "RightShift = toggle"
HintLabel.Size = UDim2.new(1, 0, 0, 16)
HintLabel.Position = UDim2.new(0, 0, 0, 36)
HintLabel.BackgroundTransparency = 1
HintLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
HintLabel.TextSize = 11
HintLabel.Font = Enum.Font.Gotham
HintLabel.TextXAlignment = Enum.TextXAlignment.Center
HintLabel.Parent = Frame

-- Layout
local List = Instance.new("UIListLayout")
List.SortOrder = Enum.SortOrder.LayoutOrder
List.Padding = UDim.new(0, 6)
List.Parent = Frame

local Padding = Instance.new("UIPadding", Frame)
Padding.PaddingTop = UDim.new(0, 58)
Padding.PaddingLeft = UDim.new(0, 12)
Padding.PaddingRight = UDim.new(0, 12)
Padding.PaddingBottom = UDim.new(0, 10)

-- Toggle button factory
local function MakeToggle(label, cfgKey, order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.Parent = Frame
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Text = label
    lbl.Size = UDim2.new(1, -55, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    -- pill toggle
    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 40, 0, 20)
    pill.Position = UDim2.new(1, -48, 0.5, -10)
    pill.BackgroundColor3 = CFG[cfgKey] and Color3.fromRGB(255,60,60) or Color3.fromRGB(60,60,70)
    pill.BorderSizePixel = 0
    pill.Parent = row
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = CFG[cfgKey] and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel = 0
    knob.Parent = pill
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row

    local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad)
    btn.MouseButton1Click:Connect(function()
        CFG[cfgKey] = not CFG[cfgKey]
        local on = CFG[cfgKey]
        TweenService:Create(pill, tweenInfo, {BackgroundColor3 = on and Color3.fromRGB(255,60,60) or Color3.fromRGB(60,60,70)}):Play()
        TweenService:Create(knob, tweenInfo, {Position = on and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)}):Play()
    end)

    return row
end

MakeToggle("ESP Enabled",   "Enabled",     1)
MakeToggle("Box ESP",       "BoxESP",      2)
MakeToggle("Name Tag",      "NameESP",     3)
MakeToggle("HP Bar",        "HealthBar",   4)
MakeToggle("Distance",      "DistanceESP", 5)
MakeToggle("Tracer Lines",  "TracerESP",   6)

-- Draggable
local dragging, dragStart, startPos = false, nil, nil
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
    end
end)
TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- F10 = toggle menu
UserInputService.InputBegan:Connect(function(input, _)
    if input.KeyCode == Enum.KeyCode.F10 then
        Frame.Visible = not Frame.Visible
    end
end)

-- show menu on load so user knows it's working
Frame.Visible = true

-- ============================================================
-- DRAWING
-- ============================================================
local function NewDrawing(t, props)
    local d = Drawing.new(t)
    for k,v in pairs(props) do d[k]=v end
    return d
end

local ESPObjects = {}

local function CreateESP(player)
    if player == LocalPlayer then return end
    ESPObjects[player] = {
        BoxTop    = NewDrawing("Line",{Thickness=CFG.BoxThickness,Color=CFG.ColorEnemy,Visible=false}),
        BoxBottom = NewDrawing("Line",{Thickness=CFG.BoxThickness,Color=CFG.ColorEnemy,Visible=false}),
        BoxLeft   = NewDrawing("Line",{Thickness=CFG.BoxThickness,Color=CFG.ColorEnemy,Visible=false}),
        BoxRight  = NewDrawing("Line",{Thickness=CFG.BoxThickness,Color=CFG.ColorEnemy,Visible=false}),
        Name      = NewDrawing("Text",{Size=CFG.TextSize,Color=Color3.new(1,1,1),Center=true,Outline=true,OutlineColor=Color3.new(0,0,0),Visible=false,Font=2}),
        HPText    = NewDrawing("Text",{Size=CFG.TextSize-1,Center=true,Outline=true,OutlineColor=Color3.new(0,0,0),Visible=false,Font=2}),
        HPBarBG   = NewDrawing("Line",{Thickness=4,Color=Color3.fromRGB(30,30,30),Visible=false}),
        HPBarFG   = NewDrawing("Line",{Thickness=3,Color=CFG.ColorHealthHi,Visible=false}),
        Distance  = NewDrawing("Text",{Size=CFG.TextSize-1,Color=Color3.fromRGB(200,200,200),Center=true,Outline=true,OutlineColor=Color3.new(0,0,0),Visible=false,Font=2}),
        Tracer    = NewDrawing("Line",{Thickness=1,Color=CFG.ColorTracer,Visible=false}),
    }
end

local function RemoveESP(player)
    local obj = ESPObjects[player]
    if not obj then return end
    for _,d in pairs(obj) do d:Remove() end
    ESPObjects[player] = nil
end

for _, p in ipairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

-- ============================================================
-- UTILS
-- ============================================================
local function W2V(pos)
    local s,z,on = Camera:WorldToViewportPoint(pos)
    return Vector2.new(s.X,s.Y), z, on
end

local function GetBounds(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local p = hrp.Position
    local ts,tz,ton = W2V(p+Vector3.new(0,3.2,0))
    local bs,bz,bon = W2V(p-Vector3.new(0,3.2,0))
    if not ton and not bon then return nil end
    if tz<=0 and bz<=0 then return nil end
    local h = math.abs(ts.Y-bs.Y)
    local w = h*0.55
    return {
        top=ts, bottom=bs,
        TL=Vector2.new(ts.X-w/2,ts.Y), TR=Vector2.new(ts.X+w/2,ts.Y),
        BL=Vector2.new(bs.X-w/2,bs.Y), BR=Vector2.new(bs.X+w/2,bs.Y),
    }
end

local function LerpC(a,b,t)
    return Color3.new(a.R+(b.R-a.R)*t, a.G+(b.G-a.G)*t, a.B+(b.B-a.B)*t)
end

local function HPColor(f)
    return LerpC(CFG.ColorHealthLo, CFG.ColorHealthHi, f)
end

local function TracerOrigin()
    local vp = Camera.ViewportSize
    return Vector2.new(vp.X/2, vp.Y)
end

-- ============================================================
-- RENDER
-- ============================================================
RunService.RenderStepped:Connect(function()
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    for player, obj in pairs(ESPObjects) do
        local char = player.Character
        local hum  = char and char:FindFirstChild("Humanoid")
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")

        if not CFG.Enabled or not char or not hum or not hrp then
            for _,d in pairs(obj) do d.Visible=false end
            goto continue
        end

        local hp, maxHP = hum.Health, hum.MaxHealth
        local f = maxHP>0 and hp/maxHP or 0
        local dead = hp<=0
        local dist = myHRP and (myHRP.Position-hrp.Position).Magnitude or 0

        if dist > CFG.MaxDistance then
            for _,d in pairs(obj) do d.Visible=false end
            goto continue
        end

        local b = GetBounds(char)
        if not b then
            for _,d in pairs(obj) do d.Visible=false end
            goto continue
        end

        local col = dead and CFG.ColorDead or (f<0.5 and CFG.ColorLowHP or CFG.ColorEnemy)

        -- Box
        if CFG.BoxESP then
            obj.BoxTop.From=b.TL; obj.BoxTop.To=b.TR; obj.BoxTop.Color=col; obj.BoxTop.Visible=true
            obj.BoxBottom.From=b.BL; obj.BoxBottom.To=b.BR; obj.BoxBottom.Color=col; obj.BoxBottom.Visible=true
            obj.BoxLeft.From=b.TL; obj.BoxLeft.To=b.BL; obj.BoxLeft.Color=col; obj.BoxLeft.Visible=true
            obj.BoxRight.From=b.TR; obj.BoxRight.To=b.BR; obj.BoxRight.Color=col; obj.BoxRight.Visible=true
        else
            obj.BoxTop.Visible=false; obj.BoxBottom.Visible=false; obj.BoxLeft.Visible=false; obj.BoxRight.Visible=false
        end

        -- Name
        if CFG.NameESP then
            obj.Name.Text=player.Name; obj.Name.Position=Vector2.new(b.top.X,b.TL.Y-16); obj.Name.Visible=true
        else obj.Name.Visible=false end

        -- HP
        if CFG.HealthBar then
            obj.HPText.Text=string.format("HP %d/%d",math.floor(hp),math.floor(maxHP))
            obj.HPText.Position=Vector2.new(b.bottom.X,b.BL.Y+4)
            obj.HPText.Color=HPColor(f); obj.HPText.Visible=not dead

            local bx=b.TL.X-6; local bt=b.TL.Y; local bb=b.BL.Y; local bf=bt+(bb-bt)*(1-f)
            obj.HPBarBG.From=Vector2.new(bx,bt); obj.HPBarBG.To=Vector2.new(bx,bb); obj.HPBarBG.Visible=true
            obj.HPBarFG.From=Vector2.new(bx,bf); obj.HPBarFG.To=Vector2.new(bx,bb); obj.HPBarFG.Color=HPColor(f); obj.HPBarFG.Visible=not dead
        else
            obj.HPText.Visible=false; obj.HPBarBG.Visible=false; obj.HPBarFG.Visible=false
        end

        -- Distance
        if CFG.DistanceESP then
            obj.Distance.Text=string.format("[%.0fm]",dist*0.28)
            obj.Distance.Position=Vector2.new(b.top.X,b.TL.Y-28); obj.Distance.Visible=true
        else obj.Distance.Visible=false end

        -- Tracer
        if CFG.TracerESP then
            obj.Tracer.From=TracerOrigin(); obj.Tracer.To=b.bottom
            obj.Tracer.Color=dead and CFG.ColorDead or CFG.ColorTracer; obj.Tracer.Visible=true
        else obj.Tracer.Visible=false end

        ::continue::
    end
end)

print("[R1 ESP] Loaded — RightShift = menu")
