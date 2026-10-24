-- ============================================================
--  R1 Battle Royale Cheat  |  ESP + No Recoil
--  Key System + GUI Menu  |  F10 = toggle menu
--  cook45
-- ============================================================

-- ============================================================
-- CONFIG — เปลี่ยน URL นี้หลัง upload GitHub
-- ============================================================
local KEYS_URL  = "https://raw.githubusercontent.com/YOUR_NAME/YOUR_REPO/main/keys.txt"
local CHEAT_VER = "v1.0"

-- ============================================================
-- SERVICES
-- ============================================================
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local TweenSvc   = game:GetService("TweenService")
local cam        = workspace.CurrentCamera
local lp         = Players.LocalPlayer

if game.PlaceId ~= 75942174630781 then
    warn("[R1] Wrong game!")
    return
end

-- cleanup
for _, v in ipairs(gethui():GetChildren()) do
    if v.Name == "R1ESP" or v.Name == "R1Key" then v:Destroy() end
end

-- ============================================================
-- KEY VALIDATION UI
-- ============================================================
local function showKeyUI(callback)
    local ksg = Instance.new("ScreenGui")
    ksg.Name = "R1Key"; ksg.IgnoreGuiInset = true
    ksg.ResetOnSpawn = false; ksg.Parent = gethui()

    -- backdrop
    local backdrop = Instance.new("Frame", ksg)
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backdrop.BackgroundTransparency = 0.5
    backdrop.BorderSizePixel = 0

    -- card
    local card = Instance.new("Frame", ksg)
    card.Size = UDim2.new(0, 340, 0, 200)
    card.Position = UDim2.new(0.5, -170, 0.5, -100)
    card.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
    card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)
    local cardStroke = Instance.new("UIStroke", card)
    cardStroke.Color = Color3.fromRGB(220, 40, 40)
    cardStroke.Thickness = 1.5

    -- title
    local hdr = Instance.new("Frame", card)
    hdr.Size = UDim2.new(1, 0, 0, 42)
    hdr.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
    hdr.BorderSizePixel = 0
    Instance.new("UICorner", hdr).CornerRadius = UDim.new(0, 12)
    local hdrFix = Instance.new("Frame", hdr)
    hdrFix.Size = UDim2.new(1, 0, 0, 12); hdrFix.Position = UDim2.new(0, 0, 1, -12)
    hdrFix.BackgroundColor3 = Color3.fromRGB(220, 40, 40); hdrFix.BorderSizePixel = 0
    local hdrLbl = Instance.new("TextLabel", hdr)
    hdrLbl.Size = UDim2.new(1, 0, 1, 0)
    hdrLbl.BackgroundTransparency = 1
    hdrLbl.Text = "  \xe2\x9a\xa1 R1 Cheat  " .. CHEAT_VER
    hdrLbl.TextColor3 = Color3.new(1, 1, 1)
    hdrLbl.Font = Enum.Font.GothamBold
    hdrLbl.TextSize = 16
    hdrLbl.TextXAlignment = Enum.TextXAlignment.Left

    -- subtitle
    local sub = Instance.new("TextLabel", card)
    sub.Size = UDim2.new(1, -20, 0, 20)
    sub.Position = UDim2.new(0, 10, 0, 50)
    sub.BackgroundTransparency = 1
    sub.Text = "Enter your key"
    sub.TextColor3 = Color3.fromRGB(160, 160, 160)
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 13

    -- input box
    local inputBG = Instance.new("Frame", card)
    inputBG.Size = UDim2.new(1, -20, 0, 40)
    inputBG.Position = UDim2.new(0, 10, 0, 76)
    inputBG.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    inputBG.BorderSizePixel = 0
    Instance.new("UICorner", inputBG).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", inputBG).Color = Color3.fromRGB(60, 60, 80)

    local input = Instance.new("TextBox", inputBG)
    input.Size = UDim2.new(1, -20, 1, 0)
    input.Position = UDim2.new(0, 10, 0, 0)
    input.BackgroundTransparency = 1
    input.Text = ""
    input.PlaceholderText = "R1-XXXX-XXXX"
    input.PlaceholderColor3 = Color3.fromRGB(80, 80, 100)
    input.TextColor3 = Color3.new(1, 1, 1)
    input.Font = Enum.Font.GothamBold
    input.TextSize = 15
    input.ClearTextOnFocus = false

    -- status label
    local status = Instance.new("TextLabel", card)
    status.Size = UDim2.new(1, -20, 0, 18)
    status.Position = UDim2.new(0, 10, 0, 122)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextColor3 = Color3.fromRGB(255, 80, 80)
    status.Font = Enum.Font.Gotham
    status.TextSize = 12

    -- confirm button
    local btnBG = Instance.new("TextButton", card)
    btnBG.Size = UDim2.new(1, -20, 0, 36)
    btnBG.Position = UDim2.new(0, 10, 0, 148)
    btnBG.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
    btnBG.BorderSizePixel = 0
    btnBG.Text = "CONFIRM KEY"
    btnBG.TextColor3 = Color3.new(1, 1, 1)
    btnBG.Font = Enum.Font.GothamBold
    btnBG.TextSize = 14
    Instance.new("UICorner", btnBG).CornerRadius = UDim.new(0, 8)

    -- hover effect
    btnBG.MouseEnter:Connect(function()
        TweenSvc:Create(btnBG, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(255,60,60)}):Play()
    end)
    btnBG.MouseLeave:Connect(function()
        TweenSvc:Create(btnBG, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(220,40,40)}):Play()
    end)

    -- validate logic
    local checking = false
    local function validate()
        if checking then return end
        local key = input.Text:match("^%s*(.-)%s*$")
        if key == "" then status.Text = "Key cannot be empty"; return end

        checking = true
        btnBG.Text = "Checking..."
        status.Text = ""
        status.TextColor3 = Color3.fromRGB(180, 180, 180)

        -- fetch key list
        local ok, raw = pcall(function() return game:HttpGet(KEYS_URL, true) end)
        if not ok then
            status.Text = "Failed to connect. Try again."
            status.TextColor3 = Color3.fromRGB(255, 80, 80)
            btnBG.Text = "CONFIRM KEY"
            checking = false
            return
        end

        -- parse & check
        local valid = false
        for line in raw:gmatch("[^\n\r]+") do
            local trimmed = line:match("^%s*(.-)%s*$")
            if trimmed ~= "" and not trimmed:sub(1,1) == "#" and trimmed == key then
                valid = true; break
            end
        end

        if valid then
            status.Text = "\xe2\x9c\x93 Key accepted! Loading..."
            status.TextColor3 = Color3.fromRGB(0, 220, 80)
            btnBG.Text = "CONFIRM KEY"
            task.wait(0.8)
            ksg:Destroy()
            callback(true)
        else
            status.Text = "\xe2\x9c\x97 Invalid key"
            status.TextColor3 = Color3.fromRGB(255, 80, 80)
            btnBG.Text = "CONFIRM KEY"
            checking = false
        end
    end

    btnBG.MouseButton1Click:Connect(validate)
    input.FocusLost:Connect(function(enter) if enter then validate() end end)
end

-- ============================================================
-- MAIN CHEAT (runs after key validation)
-- ============================================================
local function loadCheat()
    -- NO RECOIL
    local function patchRecoil()
        local ok, Config = pcall(require, game.ReplicatedStorage.TPS.Config)
        if not ok or not Config or not Config.Weapons then return end
        for _, w in pairs(Config.Weapons) do
            if type(w) == "table" and type(w.Recoil) == "table" then
                local R = w.Recoil
                R.VerticalDeg=0; R.VerticalGrowthDeg=0; R.VerticalMaxDeg=0
                R.HorizontalDeg=0; R.HorizontalGrowthDeg=0; R.HorizontalMaxDeg=0
                R.VariationDeg=0; R.AimMultiplier=0; R.HipMultiplier=0
            end
        end
    end
    patchRecoil()

    -- GUI
    local sg = Instance.new("ScreenGui")
    sg.Name = "R1ESP"; sg.IgnoreGuiInset = true
    sg.ResetOnSpawn = false; sg.Parent = gethui()

    local bg = Instance.new("Frame", sg)
    bg.Size = UDim2.new(0, 230, 0, 300)
    bg.Position = UDim2.new(0, 20, 0, 80)
    bg.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
    bg.BorderSizePixel = 0; bg.Active = true
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", bg).Color = Color3.fromRGB(220, 40, 40)

    local title = Instance.new("TextLabel", bg)
    title.Size = UDim2.new(1, 0, 0, 36)
    title.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
    title.BorderSizePixel = 0
    title.Text = "  \xe2\x9a\xa1 R1 Cheat  [F10]"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)
    local fix = Instance.new("Frame", title)
    fix.Size = UDim2.new(1, 0, 0, 8); fix.Position = UDim2.new(0, 0, 1, -8)
    fix.BackgroundColor3 = Color3.fromRGB(220, 40, 40); fix.BorderSizePixel = 0

    local CFG = {
        ESP=true, Box=true, Name=true, HP=true, Dist=true, Tracer=false,
        NoRecoil=true, MaxDist=900,
    }

    local function Toggle(lbl, key, yPos)
        local row = Instance.new("Frame", bg)
        row.Size = UDim2.new(1, -16, 0, 30); row.Position = UDim2.new(0, 8, 0, yPos)
        row.BackgroundColor3 = Color3.fromRGB(22, 22, 32); row.BorderSizePixel = 0
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
        local txt = Instance.new("TextLabel", row)
        txt.Size = UDim2.new(1, -52, 1, 0); txt.Position = UDim2.new(0, 10, 0, 0)
        txt.BackgroundTransparency = 1; txt.Text = lbl
        txt.TextColor3 = Color3.fromRGB(210, 210, 210)
        txt.Font = Enum.Font.Gotham; txt.TextSize = 13
        txt.TextXAlignment = Enum.TextXAlignment.Left
        local pill = Instance.new("Frame", row)
        pill.Size = UDim2.new(0, 38, 0, 20); pill.Position = UDim2.new(1, -46, 0.5, -10)
        pill.BackgroundColor3 = CFG[key] and Color3.fromRGB(220, 40, 40) or Color3.fromRGB(55, 55, 65)
        pill.BorderSizePixel = 0
        Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
        local knob = Instance.new("Frame", pill)
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.Position = CFG[key] and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        knob.BackgroundColor3 = Color3.new(1, 1, 1); knob.BorderSizePixel = 0
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
        local btn = Instance.new("TextButton", row)
        btn.Size = UDim2.new(1, 0, 1, 0); btn.BackgroundTransparency = 1; btn.Text = ""
        btn.MouseButton1Click:Connect(function()
            CFG[key] = not CFG[key]
            pill.BackgroundColor3 = CFG[key] and Color3.fromRGB(220, 40, 40) or Color3.fromRGB(55, 55, 65)
            knob.Position = CFG[key] and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            if key == "NoRecoil" and CFG[key] then patchRecoil() end
        end)
    end

    Toggle("ESP Enable",  "ESP",      44)
    Toggle("Box ESP",     "Box",      80)
    Toggle("Name Tag",    "Name",     116)
    Toggle("HP Bar",      "HP",       152)
    Toggle("Distance",    "Dist",     188)
    Toggle("Tracer",      "Tracer",   224)
    Toggle("No Recoil",   "NoRecoil", 262)

    local drag, ds, dp = false, nil, nil
    bg.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag=true; ds=i.Position; dp=bg.Position
        end
    end)
    bg.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag=false end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position-ds
            bg.Position = UDim2.new(dp.X.Scale, dp.X.Offset+d.X, dp.Y.Scale, dp.Y.Offset+d.Y)
        end
    end)
    UIS.InputBegan:Connect(function(i, _)
        if i.KeyCode == Enum.KeyCode.F10 then bg.Visible = not bg.Visible end
    end)

    -- Drawing
    local function D(t, p)
        local d = Drawing.new(t)
        for k, v in pairs(p) do d[k] = v end
        return d
    end
    local function LC(a, b, t)
        return Color3.new(a.R+(b.R-a.R)*t, a.G+(b.G-a.G)*t, a.B+(b.B-a.B)*t)
    end
    local hi=Color3.fromRGB(0,255,80); local lo=Color3.fromRGB(255,60,60); local gray=Color3.fromRGB(120,120,120)
    local entries={}; local modelSet={}; local myName=lp.Name

    local function makeD()
        return {
            BT=D("Line",{Thickness=1.5,Color=lo,Visible=false}),
            BB=D("Line",{Thickness=1.5,Color=lo,Visible=false}),
            BL=D("Line",{Thickness=1.5,Color=lo,Visible=false}),
            BR=D("Line",{Thickness=1.5,Color=lo,Visible=false}),
            NT=D("Text",{Size=13,Color=Color3.new(1,1,1),Center=true,Outline=true,OutlineColor=Color3.new(0,0,0),Visible=false,Font=2}),
            HT=D("Text",{Size=12,Color=hi,Center=true,Outline=true,OutlineColor=Color3.new(0,0,0),Visible=false,Font=2}),
            BG=D("Line",{Thickness=4,Color=Color3.fromRGB(30,30,30),Visible=false}),
            FG=D("Line",{Thickness=3,Color=hi,Visible=false}),
            DT=D("Text",{Size=11,Color=Color3.fromRGB(180,180,180),Center=true,Outline=true,OutlineColor=Color3.new(0,0,0),Visible=false,Font=2}),
            TR=D("Line",{Thickness=1,Color=Color3.fromRGB(255,255,0),Visible=false}),
        }
    end
    local function hideAll(o) for _, d in pairs(o) do d.Visible=false end end
    local function rmD(o) for _, d in pairs(o) do d:Remove() end end

    local function addModel(model)
        if not model or modelSet[model] or model.Name==myName then return end
        local hum=model:FindFirstChildOfClass("Humanoid")
        local hrp=model:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return end
        local e={model=model,hum=hum,hrp=hrp,dr=makeD(),lastHP=-1,col=lo,hcol=hi,
            visible=false,tv=Vector2.new(),bv=Vector2.new(),
            TLx=0,TRx=0,BLx=0,BRx=0,distM=0,hp=100,mhp=100,dead=false,f=1}
        modelSet[model]=e; table.insert(entries,e)
    end
    local function removeModel(model)
        local e=modelSet[model]; if not e then return end
        rmD(e.dr); modelSet[model]=nil
        for i,v in ipairs(entries) do if v==e then table.remove(entries,i); break end end
    end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.ClassName=="Humanoid" and obj.Parent then addModel(obj.Parent) end
    end
    workspace.DescendantAdded:Connect(function(obj)
        if obj.ClassName=="Humanoid" then task.defer(function() addModel(obj.Parent) end) end
    end)
    workspace.DescendantRemoving:Connect(function(obj)
        if obj.ClassName=="HumanoidRootPart" and obj.Parent then
            task.defer(function() removeModel(obj.Parent) end)
        end
    end)

    local maxDistSq = CFG.MaxDist*CFG.MaxDist
    RunService.Heartbeat:Connect(function()
        local myChr=lp.Character; local myHRP=myChr and myChr:FindFirstChild("HumanoidRootPart")
        local myPos=myHRP and myHRP.Position
        for _, e in ipairs(entries) do
            if not e.model.Parent or not e.hrp.Parent then e.visible=false; continue end
            local pos=e.hrp.Position
            if myPos then
                local dx=myPos.X-pos.X; local dy=myPos.Y-pos.Y; local dz=myPos.Z-pos.Z
                if dx*dx+dy*dy+dz*dz>maxDistSq then e.visible=false; continue end
                e.distM=(myPos-pos).Magnitude*0.28
            end
            local ts=cam:WorldToViewportPoint(pos+Vector3.new(0,3.2,0))
            local bs=cam:WorldToViewportPoint(pos-Vector3.new(0,3.2,0))
            if ts.Z<=0 and bs.Z<=0 then e.visible=false; continue end
            local tv=Vector2.new(ts.X,ts.Y); local bv=Vector2.new(bs.X,bs.Y)
            local h=math.abs(tv.Y-bv.Y); if h<4 then e.visible=false; continue end
            local w=h*0.55
            e.tv=tv; e.bv=bv
            e.TLx=tv.X-w/2; e.TRx=tv.X+w/2; e.BLx=bv.X-w/2; e.BRx=bv.X+w/2
            local hp=e.hum.Health; local mhp=e.hum.MaxHealth
            e.hp=hp; e.mhp=mhp; e.dead=hp<=0
            if hp~=e.lastHP then
                e.lastHP=hp; local f=mhp>0 and hp/mhp or 0; e.f=f
                e.col=e.dead and gray or (f<0.5 and Color3.fromRGB(255,165,0) or lo)
                e.hcol=LC(lo,hi,f)
            end
            e.visible=true
        end
    end)

    local tracerO=Vector2.new(cam.ViewportSize.X/2,cam.ViewportSize.Y)
    RunService.RenderStepped:Connect(function()
        local vp=cam.ViewportSize; tracerO=Vector2.new(vp.X/2,vp.Y)
        if not CFG.ESP then for _,e in ipairs(entries) do hideAll(e.dr) end; return end
        for _,e in ipairs(entries) do
            local o=e.dr
            if not e.visible then hideAll(o); continue end
            local tv,bv=e.tv,e.bv
            local TLx,TRx,BLx,BRx=e.TLx,e.TRx,e.BLx,e.BRx
            local col,hcol=e.col,e.hcol
            if CFG.Box then
                o.BT.From=Vector2.new(TLx,tv.Y);o.BT.To=Vector2.new(TRx,tv.Y);o.BT.Color=col;o.BT.Visible=true
                o.BB.From=Vector2.new(BLx,bv.Y);o.BB.To=Vector2.new(BRx,bv.Y);o.BB.Color=col;o.BB.Visible=true
                o.BL.From=Vector2.new(TLx,tv.Y);o.BL.To=Vector2.new(BLx,bv.Y);o.BL.Color=col;o.BL.Visible=true
                o.BR.From=Vector2.new(TRx,tv.Y);o.BR.To=Vector2.new(BRx,bv.Y);o.BR.Color=col;o.BR.Visible=true
            else o.BT.Visible=false;o.BB.Visible=false;o.BL.Visible=false;o.BR.Visible=false end
            if CFG.Name then
                o.NT.Text=e.model.Name; o.NT.Position=Vector2.new(tv.X,tv.Y-15); o.NT.Visible=true
            else o.NT.Visible=false end
            if CFG.HP then
                o.HT.Text=string.format("%d/%d",math.floor(e.hp),math.floor(e.mhp))
                o.HT.Position=Vector2.new(bv.X,bv.Y+3); o.HT.Color=hcol; o.HT.Visible=not e.dead
                local bx=TLx-5; local bf=tv.Y+(bv.Y-tv.Y)*(1-e.f)
                o.BG.From=Vector2.new(bx,tv.Y);o.BG.To=Vector2.new(bx,bv.Y);o.BG.Visible=true
                o.FG.From=Vector2.new(bx,bf);o.FG.To=Vector2.new(bx,bv.Y);o.FG.Color=hcol;o.FG.Visible=not e.dead
            else o.HT.Visible=false;o.BG.Visible=false;o.FG.Visible=false end
            if CFG.Dist then
                o.DT.Text=string.format("[%.0fm]",e.distM)
                o.DT.Position=Vector2.new(tv.X,tv.Y-27); o.DT.Visible=true
            else o.DT.Visible=false end
            if CFG.Tracer then o.TR.From=tracerO;o.TR.To=bv;o.TR.Visible=true else o.TR.Visible=false end
        end
    end)

    print("[R1 Cheat] Loaded | " .. #entries .. " players")
end

-- ============================================================
-- ENTRY POINT
-- ============================================================
showKeyUI(function(ok)
    if ok then loadCheat() end
end)
