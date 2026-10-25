-- ============================================================
--  R1 Battle Royale  |  ESP + No Recoil + Kavo Clean UI
--  Keyless Edition  |  Auto-Teleport Reconnect  |  F10 = Menu
--  ANON
-- ============================================================

local CHEAT_VER = "v1.1 (Keyless)"
print("[R1 Cheat] Executed successfully | Version: " .. CHEAT_VER)

-- ============================================================
-- AUTO TELEPORT RECONNECT (queue_on_teleport)
-- ============================================================
local queueTeleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
if queueTeleport then
    queueTeleport([[
        task.wait(1)
        loadstring(game:HttpGet("https://raw.githubusercontent.com/boombadah/r1-scripts/main/R1_Cheat.lua?t=" .. tick()))()
    ]])
end

-- ============================================================
-- SERVICES
-- ============================================================
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local TweenSvc   = game:GetService("TweenService")
local cam        = workspace.CurrentCamera

local lp = Players.LocalPlayer
if not lp then
    repeat
        task.wait(0.1)
        lp = Players.LocalPlayer
    until lp
end

-- Safe Environment resolver
local function getEnv()
    if typeof(getgenv) == "function" then
        local ok, env = pcall(getgenv)
        if ok and env then return env end
    end
    return _G
end
local env = getEnv()

-- Safe GUI Parent resolver (with write capability check)
local function getSafeGui()
    -- 1. gethui() (Executor hidden GUI)
    if typeof(gethui) == "function" then
        local ok, res = pcall(gethui)
        if ok and res then
            local canWrite = pcall(function()
                local f = Instance.new("Folder")
                f.Parent = res
                f:Destroy()
            end)
            if canWrite then return res end
        end
    end

    -- 2. CoreGui (test write capability)
    local okCore, core = pcall(function() return game:GetService("CoreGui") end)
    if okCore and core then
        local canCore = pcall(function()
            local f = Instance.new("Folder")
            f.Parent = core
            f:Destroy()
        end)
        if canCore then return core end
    end

    -- 3. PlayerGui (guaranteed writable by all clients)
    local pg = lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui", 5)
    return pg
end
local safeParent = getSafeGui()

local VALID_PLACES = {[75942174630781]=true, [114690486941238]=true}
if not VALID_PLACES[game.PlaceId] then
    warn("[R1] Notice: PlaceId=" .. tostring(game.PlaceId) .. " (Running in test/bypass mode)")
end

-- Unload previous instance if running
if typeof(env.R1_Unload) == "function" then
    pcall(env.R1_Unload)
end

-- Comprehensive GUI cleanup across safeParent, CoreGui, PlayerGui
local function cleanupOldGuis()
    local targets = {safeParent}
    local okCore, core = pcall(function() return game:GetService("CoreGui") end)
    if okCore and core then table.insert(targets, core) end
    local pg = lp:FindFirstChildOfClass("PlayerGui")
    if pg then table.insert(targets, pg) end

    for _, container in ipairs(targets) do
        pcall(function()
            for _, v in ipairs(container:GetChildren()) do
                if v:IsA("ScreenGui") and (v.Name == "R1_Cheat_UI" or v.Name == "R1ESP" or v.Name == "R1Key" or v:GetAttribute("R1_UI")) then
                    v:Destroy()
                end
            end
        end)
    end
end
cleanupOldGuis()

-- ============================================================
-- MAIN CHEAT (KEYLESS)
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

    -- ============================================================
    -- EMBEDDED KAVO UI LIBRARY (CLEAN, EVENT-DRIVEN, 0 CPU LAG)
    -- 100% Standalone: 0 external files, 0 network requests
    -- ============================================================
    local Library = (function()
    -- [ANON SECURITY HARDENED] Safe Container Resolver
    local safeGuiParent = safeParent

    --// to the 2 peoplee who are constantly watching this repo, get a life yall weird.
    --// to the people who are still forking this unoptimized garbage, if you want a custom optimized rewrite for $, hmu on discord: federal6768 or federal.

    local Kavo = {}

    local tween = game:GetService("TweenService")
    local tweeninfo = TweenInfo.new
    local input = game:GetService("UserInputService")
    local run = game:GetService("RunService")

    local Utility = {}
    local Objects = {}
    function Kavo:DraggingEnabled(frame, parent)

        parent = parent or frame

        -- stolen from wally or kiriot, kek
        local dragging = false
        local dragInput, mousePos, framePos

        frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                mousePos = input.Position
                framePos = parent.Position

                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        frame.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                dragInput = input
            end
        end)

        input.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - mousePos
                parent.Position  = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
            end
        end)
    end

    function Utility:TweenObject(obj, properties, duration, ...)
        tween:Create(obj, tweeninfo(duration, ...), properties):Play()
    end


    local themes = {
        SchemeColor = Color3.fromRGB(74, 99, 135),
        Background = Color3.fromRGB(36, 37, 43),
        Header = Color3.fromRGB(28, 29, 34),
        TextColor = Color3.fromRGB(255,255,255),
        ElementColor = Color3.fromRGB(32, 32, 38)
    }
    local themeStyles = {
        DarkTheme = {
            SchemeColor = Color3.fromRGB(64, 64, 64),
            Background = Color3.fromRGB(0, 0, 0),
            Header = Color3.fromRGB(0, 0, 0),
            TextColor = Color3.fromRGB(255,255,255),
            ElementColor = Color3.fromRGB(20, 20, 20)
        },
        LightTheme = {
            SchemeColor = Color3.fromRGB(150, 150, 150),
            Background = Color3.fromRGB(255,255,255),
            Header = Color3.fromRGB(200, 200, 200),
            TextColor = Color3.fromRGB(0,0,0),
            ElementColor = Color3.fromRGB(224, 224, 224)
        },
        BloodTheme = {
            SchemeColor = Color3.fromRGB(227, 27, 27),
            Background = Color3.fromRGB(10, 10, 10),
            Header = Color3.fromRGB(5, 5, 5),
            TextColor = Color3.fromRGB(255,255,255),
            ElementColor = Color3.fromRGB(20, 20, 20)
        },
        GrapeTheme = {
            SchemeColor = Color3.fromRGB(166, 71, 214),
            Background = Color3.fromRGB(64, 50, 71),
            Header = Color3.fromRGB(36, 28, 41),
            TextColor = Color3.fromRGB(255,255,255),
            ElementColor = Color3.fromRGB(74, 58, 84)
        },
        Ocean = {
            SchemeColor = Color3.fromRGB(86, 76, 251),
            Background = Color3.fromRGB(26, 32, 58),
            Header = Color3.fromRGB(38, 45, 71),
            TextColor = Color3.fromRGB(200, 200, 200),
            ElementColor = Color3.fromRGB(38, 45, 71)
        },
        Midnight = {
            SchemeColor = Color3.fromRGB(26, 189, 158),
            Background = Color3.fromRGB(44, 62, 82),
            Header = Color3.fromRGB(57, 81, 105),
            TextColor = Color3.fromRGB(255, 255, 255),
            ElementColor = Color3.fromRGB(52, 74, 95)
        },
        Sentinel = {
            SchemeColor = Color3.fromRGB(230, 35, 69),
            Background = Color3.fromRGB(32, 32, 32),
            Header = Color3.fromRGB(24, 24, 24),
            TextColor = Color3.fromRGB(119, 209, 138),
            ElementColor = Color3.fromRGB(24, 24, 24)
        },
        Synapse = {
            SchemeColor = Color3.fromRGB(46, 48, 43),
            Background = Color3.fromRGB(13, 15, 12),
            Header = Color3.fromRGB(36, 38, 35),
            TextColor = Color3.fromRGB(152, 99, 53),
            ElementColor = Color3.fromRGB(24, 24, 24)
        },
        Serpent = {
            SchemeColor = Color3.fromRGB(0, 166, 58),
            Background = Color3.fromRGB(31, 41, 43),
            Header = Color3.fromRGB(22, 29, 31),
            TextColor = Color3.fromRGB(255,255,255),
            ElementColor = Color3.fromRGB(22, 29, 31)
        }
    }
    local oldTheme = ""

    local SettingsT = {

    }

    local Name = "KavoConfig.JSON"

    pcall(function()

    if not pcall(function() readfile(Name) end) then
    writefile(Name, game:GetService('HttpService'):JSONEncode(SettingsT))
    end

    Settings = game:GetService('HttpService'):JSONEncode(readfile(Name))
    end)

    local LibName = "R1_Cheat_UI"
    local currentScreenGui = nil
    local currentMain = nil

    function Kavo:ToggleUI()
        if currentScreenGui then
            currentScreenGui.Enabled = not currentScreenGui.Enabled
            if currentMain then
                currentMain.Visible = currentScreenGui.Enabled
            end
        elseif currentMain then
            currentMain.Visible = not currentMain.Visible
        end
    end

    function Kavo.CreateLib(kavName, themeList)
        if not themeList then
            themeList = themes
        end
        if themeList == "DarkTheme" then
            themeList = themeStyles.DarkTheme
        elseif themeList == "LightTheme" then
            themeList = themeStyles.LightTheme
        elseif themeList == "BloodTheme" then
            themeList = themeStyles.BloodTheme
        elseif themeList == "GrapeTheme" then
            themeList = themeStyles.GrapeTheme
        elseif themeList == "Ocean" then
            themeList = themeStyles.Ocean
        elseif themeList == "Midnight" then
            themeList = themeStyles.Midnight
        elseif themeList == "Sentinel" then
            themeList = themeStyles.Sentinel
        elseif themeList == "Synapse" then
            themeList = themeStyles.Synapse
        elseif themeList == "Serpent" then
            themeList = themeStyles.Serpent
        else
            if themeList.SchemeColor == nil then
                themeList.SchemeColor = Color3.fromRGB(74, 99, 135)
            elseif themeList.Background == nil then
                themeList.Background = Color3.fromRGB(36, 37, 43)
            elseif themeList.Header == nil then
                themeList.Header = Color3.fromRGB(28, 29, 34)
            elseif themeList.TextColor == nil then
                themeList.TextColor = Color3.fromRGB(255,255,255)
            elseif themeList.ElementColor == nil then
                themeList.ElementColor = Color3.fromRGB(32, 32, 38)
            end
        end

        themeList = themeList or {}
        local selectedTab 
        kavName = "R1_Cheat_UI"
        table.insert(Kavo, kavName)
        cleanupOldGuis()
        local ScreenGui = Instance.new("ScreenGui")
        local Main = Instance.new("Frame")
        local MainCorner = Instance.new("UICorner")
        local MainHeader = Instance.new("Frame")
        local headerCover = Instance.new("UICorner")
        local coverup = Instance.new("Frame")
        local title = Instance.new("TextLabel")
        local close = Instance.new("ImageButton")
        local MainSide = Instance.new("Frame")
        local sideCorner = Instance.new("UICorner")
        local coverup_2 = Instance.new("Frame")
        local tabFrames = Instance.new("Frame")
        local tabListing = Instance.new("UIListLayout")
        local pages = Instance.new("Frame")
        local Pages = Instance.new("Folder")
        local infoContainer = Instance.new("Frame")

        local blurFrame = Instance.new("Frame")

        Kavo:DraggingEnabled(MainHeader, Main)

        blurFrame.Name = "blurFrame"
        blurFrame.Parent = pages
        blurFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        blurFrame.BackgroundTransparency = 1
        blurFrame.BorderSizePixel = 0
        blurFrame.Position = UDim2.new(-0.0222222228, 0, -0.0371747203, 0)
        blurFrame.Size = UDim2.new(0, 376, 0, 289)
        blurFrame.ZIndex = 999

        local okP = pcall(function() ScreenGui.Parent = safeGuiParent end)
        if not okP or not ScreenGui.Parent then
            ScreenGui.Parent = lp:WaitForChild("PlayerGui")
        end
        currentScreenGui = ScreenGui
        currentMain = Main
        ScreenGui.Name = "R1_Cheat_UI"
        ScreenGui:SetAttribute("R1_UI", true)
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        ScreenGui.ResetOnSpawn = false

        Main.Name = "Main"
        Main.Parent = ScreenGui
        Main.BackgroundColor3 = themeList.Background
        Main.ClipsDescendants = true
        Main.Position = UDim2.new(0.336503863, 0, 0.275485456, 0)
        Main.Size = UDim2.new(0, 525, 0, 318)

        MainCorner.CornerRadius = UDim.new(0, 4)
        MainCorner.Name = "MainCorner"
        MainCorner.Parent = Main

        MainHeader.Name = "MainHeader"
        MainHeader.Parent = Main
        MainHeader.BackgroundColor3 = themeList.Header
        Objects[MainHeader] = "BackgroundColor3"
        MainHeader.Size = UDim2.new(0, 525, 0, 29)
        headerCover.CornerRadius = UDim.new(0, 4)
        headerCover.Name = "headerCover"
        headerCover.Parent = MainHeader

        coverup.Name = "coverup"
        coverup.Parent = MainHeader
        coverup.BackgroundColor3 = themeList.Header
        Objects[coverup] = "BackgroundColor3"
        coverup.BorderSizePixel = 0
        coverup.Position = UDim2.new(0, 0, 0.758620679, 0)
        coverup.Size = UDim2.new(0, 525, 0, 7)

        title.Name = "title"
        title.Parent = MainHeader
        title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        title.BackgroundTransparency = 1.000
        title.BorderSizePixel = 0
        title.Position = UDim2.new(0.0171428565, 0, 0.344827592, 0)
        title.Size = UDim2.new(0, 204, 0, 8)
        title.Font = Enum.Font.Gotham
        title.RichText = true
        title.Text = kavName
        title.TextColor3 = Color3.fromRGB(245, 245, 245)
        title.TextSize = 16.000
        title.TextXAlignment = Enum.TextXAlignment.Left

        close.Name = "close"
        close.Parent = MainHeader
        close.BackgroundTransparency = 1.000
        close.Position = UDim2.new(0.949999988, 0, 0.137999997, 0)
        close.Size = UDim2.new(0, 21, 0, 21)
        close.ZIndex = 2
        close.Image = "rbxassetid://3926305904"
        close.ImageRectOffset = Vector2.new(284, 4)
        close.ImageRectSize = Vector2.new(24, 24)
        close.MouseButton1Click:Connect(function()
            game.TweenService:Create(close, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                ImageTransparency = 1
            }):Play()
            task.wait()
            game.TweenService:Create(Main, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
    			Size = UDim2.new(0,0,0,0),
    			Position = UDim2.new(0, Main.AbsolutePosition.X + (Main.AbsoluteSize.X / 2), 0, Main.AbsolutePosition.Y + (Main.AbsoluteSize.Y / 2))
    		}):Play()
            task.wait(1)
            ScreenGui:Destroy()
        end)

        MainSide.Name = "MainSide"
        MainSide.Parent = Main
        MainSide.BackgroundColor3 = themeList.Header
        Objects[MainSide] = "Header"
        MainSide.Position = UDim2.new(-7.4505806e-09, 0, 0.0911949649, 0)
        MainSide.Size = UDim2.new(0, 149, 0, 289)

        sideCorner.CornerRadius = UDim.new(0, 4)
        sideCorner.Name = "sideCorner"
        sideCorner.Parent = MainSide

        coverup_2.Name = "coverup"
        coverup_2.Parent = MainSide
        coverup_2.BackgroundColor3 = themeList.Header
        Objects[coverup_2] = "Header"
        coverup_2.BorderSizePixel = 0
        coverup_2.Position = UDim2.new(0.949939311, 0, 0, 0)
        coverup_2.Size = UDim2.new(0, 7, 0, 289)

        tabFrames.Name = "tabFrames"
        tabFrames.Parent = MainSide
        tabFrames.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        tabFrames.BackgroundTransparency = 1.000
        tabFrames.Position = UDim2.new(0.0438990258, 0, -0.00066378375, 0)
        tabFrames.Size = UDim2.new(0, 135, 0, 283)

        tabListing.Name = "tabListing"
        tabListing.Parent = tabFrames
        tabListing.SortOrder = Enum.SortOrder.LayoutOrder

        pages.Name = "pages"
        pages.Parent = Main
        pages.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        pages.BackgroundTransparency = 1.000
        pages.BorderSizePixel = 0
        pages.Position = UDim2.new(0.299047589, 0, 0.122641519, 0)
        pages.Size = UDim2.new(0, 360, 0, 269)

        Pages.Name = "Pages"
        Pages.Parent = pages

        infoContainer.Name = "infoContainer"
        infoContainer.Parent = Main
        infoContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        infoContainer.BackgroundTransparency = 1.000
        infoContainer.BorderColor3 = Color3.fromRGB(27, 42, 53)
        infoContainer.ClipsDescendants = true
        infoContainer.Position = UDim2.new(0.299047619, 0, 0.874213815, 0)
        infoContainer.Size = UDim2.new(0, 368, 0, 33)


        local function applyThemeColors()
            Main.BackgroundColor3 = themeList.Background
            MainHeader.BackgroundColor3 = themeList.Header
            MainSide.BackgroundColor3 = themeList.Header
            coverup_2.BackgroundColor3 = themeList.Header
            coverup.BackgroundColor3 = themeList.Header
        end
        applyThemeColors()

        function Kavo:ChangeColor(prope,color)
            if prope == "Background" then
                themeList.Background = color
            elseif prope == "SchemeColor" then
                themeList.SchemeColor = color
            elseif prope == "Header" then
                themeList.Header = color
            elseif prope == "TextColor" then
                themeList.TextColor = color
            elseif prope == "ElementColor" then
                themeList.ElementColor = color
            end
        applyThemeColors()
        end
        local Tabs = {}

        local first = true

        function Tabs:NewTab(tabName)
            tabName = tabName or "Tab"
            local tabButton = Instance.new("TextButton")
            local UICorner = Instance.new("UICorner")
            local page = Instance.new("ScrollingFrame")
            local pageListing = Instance.new("UIListLayout")

            local function UpdateSize()
                local cS = pageListing.AbsoluteContentSize

                game.TweenService:Create(page, TweenInfo.new(0.15, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
                    CanvasSize = UDim2.new(0,cS.X,0,cS.Y)
                }):Play()
            end

            page.Name = "Page"
            page.Parent = Pages
            page.Active = true
            page.BackgroundColor3 = themeList.Background
            page.BorderSizePixel = 0
            page.Position = UDim2.new(0, 0, -0.00371747208, 0)
            page.Size = UDim2.new(1, 0, 1, 0)
            page.ScrollBarThickness = 5
            page.Visible = false
            page.ScrollBarImageColor3 = Color3.fromRGB(themeList.SchemeColor.r * 255 - 16, themeList.SchemeColor.g * 255 - 15, themeList.SchemeColor.b * 255 - 28)

            pageListing.Name = "pageListing"
            pageListing.Parent = page
            pageListing.SortOrder = Enum.SortOrder.LayoutOrder
            pageListing.Padding = UDim.new(0, 5)

            tabButton.Name = tabName.."TabButton"
            tabButton.Parent = tabFrames
            tabButton.BackgroundColor3 = themeList.SchemeColor
            Objects[tabButton] = "SchemeColor"
            tabButton.Size = UDim2.new(0, 135, 0, 28)
            tabButton.AutoButtonColor = false
            tabButton.Font = Enum.Font.Gotham
            tabButton.Text = tabName
            tabButton.TextColor3 = themeList.TextColor
            Objects[tabButton] = "TextColor3"
            tabButton.TextSize = 14.000
            tabButton.BackgroundTransparency = 1

            if first then
                first = false
                page.Visible = true
                tabButton.BackgroundTransparency = 0
                UpdateSize()
            else
                page.Visible = false
                tabButton.BackgroundTransparency = 1
            end

            UICorner.CornerRadius = UDim.new(0, 5)
            UICorner.Parent = tabButton
            table.insert(Tabs, tabName)

            UpdateSize()
            page.ChildAdded:Connect(UpdateSize)
            page.ChildRemoved:Connect(UpdateSize)

            tabButton.MouseButton1Click:Connect(function()
                UpdateSize()
                for i,v in next, Pages:GetChildren() do
                    v.Visible = false
                end
                page.Visible = true
                for i,v in next, tabFrames:GetChildren() do
                    if v:IsA("TextButton") then
                        if themeList.SchemeColor == Color3.fromRGB(255,255,255) then
                            Utility:TweenObject(v, {TextColor3 = Color3.fromRGB(255,255,255)}, 0.2)
                        end 
                        if themeList.SchemeColor == Color3.fromRGB(0,0,0) then
                            Utility:TweenObject(v, {TextColor3 = Color3.fromRGB(0,0,0)}, 0.2)
                        end 
                        Utility:TweenObject(v, {BackgroundTransparency = 1}, 0.2)
                    end
                end
                if themeList.SchemeColor == Color3.fromRGB(255,255,255) then
                    Utility:TweenObject(tabButton, {TextColor3 = Color3.fromRGB(0,0,0)}, 0.2)
                end 
                if themeList.SchemeColor == Color3.fromRGB(0,0,0) then
                    Utility:TweenObject(tabButton, {TextColor3 = Color3.fromRGB(255,255,255)}, 0.2)
                end 
                Utility:TweenObject(tabButton, {BackgroundTransparency = 0}, 0.2)
            end)
            local Sections = {}
            local focusing = false
            local viewDe = false

            do
    page.BackgroundColor3 = themeList.Background
                    page.ScrollBarImageColor3 = Color3.fromRGB(themeList.SchemeColor.r * 255 - 16, themeList.SchemeColor.g * 255 - 15, themeList.SchemeColor.b * 255 - 28)
                    tabButton.TextColor3 = themeList.TextColor
                    tabButton.BackgroundColor3 = themeList.SchemeColor
    end

            function Sections:NewSection(secName, hidden)
                secName = secName or "Section"
                local sectionFunctions = {}
                local modules = {}
    	    hidden = hidden or false
                local sectionFrame = Instance.new("Frame")
                local sectionlistoknvm = Instance.new("UIListLayout")
                local sectionHead = Instance.new("Frame")
                local sHeadCorner = Instance.new("UICorner")
                local sectionName = Instance.new("TextLabel")
                local sectionInners = Instance.new("Frame")
                local sectionElListing = Instance.new("UIListLayout")

    	    if hidden then
    		sectionHead.Visible = false
    	    else
    		sectionHead.Visible = true
    	    end

                sectionFrame.Name = "sectionFrame"
                sectionFrame.Parent = page
                sectionFrame.BackgroundColor3 = themeList.Background--36, 37, 43
                sectionFrame.BorderSizePixel = 0

                sectionlistoknvm.Name = "sectionlistoknvm"
                sectionlistoknvm.Parent = sectionFrame
                sectionlistoknvm.SortOrder = Enum.SortOrder.LayoutOrder
                sectionlistoknvm.Padding = UDim.new(0, 5)

                sectionInners.ChildAdded:Connect(function()
                    UpdateSize()
                    updateSectionFrame()
                end)
                sectionHead.Name = "sectionHead"
                sectionHead.Parent = sectionFrame
                sectionHead.BackgroundColor3 = themeList.SchemeColor
                Objects[sectionHead] = "BackgroundColor3"
                sectionHead.Size = UDim2.new(0, 352, 0, 33)

                sHeadCorner.CornerRadius = UDim.new(0, 4)
                sHeadCorner.Name = "sHeadCorner"
                sHeadCorner.Parent = sectionHead

                sectionName.Name = "sectionName"
                sectionName.Parent = sectionHead
                sectionName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                sectionName.BackgroundTransparency = 1.000
                sectionName.BorderColor3 = Color3.fromRGB(27, 42, 53)
                sectionName.Position = UDim2.new(0.0198863633, 0, 0, 0)
                sectionName.Size = UDim2.new(0.980113626, 0, 1, 0)
                sectionName.Font = Enum.Font.Gotham
                sectionName.Text = secName
                sectionName.RichText = true
                sectionName.TextColor3 = themeList.TextColor
                Objects[sectionName] = "TextColor3"
                sectionName.TextSize = 14.000
                sectionName.TextXAlignment = Enum.TextXAlignment.Left
                if themeList.SchemeColor == Color3.fromRGB(255,255,255) then
                    Utility:TweenObject(sectionName, {TextColor3 = Color3.fromRGB(0,0,0)}, 0.2)
                end 
                if themeList.SchemeColor == Color3.fromRGB(0,0,0) then
                    Utility:TweenObject(sectionName, {TextColor3 = Color3.fromRGB(255,255,255)}, 0.2)
                end 

                sectionInners.Name = "sectionInners"
                sectionInners.Parent = sectionFrame
                sectionInners.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                sectionInners.BackgroundTransparency = 1.000
                sectionInners.Position = UDim2.new(0, 0, 0.190751448, 0)

                sectionElListing.Name = "sectionElListing"
                sectionElListing.Parent = sectionInners
                sectionElListing.SortOrder = Enum.SortOrder.LayoutOrder
                sectionElListing.Padding = UDim.new(0, 3)


            do
    sectionFrame.BackgroundColor3 = themeList.Background
                    sectionHead.BackgroundColor3 = themeList.SchemeColor
                    tabButton.TextColor3 = themeList.TextColor
                    tabButton.BackgroundColor3 = themeList.SchemeColor
                    sectionName.TextColor3 = themeList.TextColor
    end

                local function updateSectionFrame()
                    local innerSc = sectionElListing.AbsoluteContentSize
                    sectionInners.Size = UDim2.new(1, 0, 0, innerSc.Y)
                    local frameSc = sectionlistoknvm.AbsoluteContentSize
                    sectionFrame.Size = UDim2.new(0, 352, 0, frameSc.Y)
                end
                    updateSectionFrame()
                    UpdateSize()
                local Elements = {}
                function Elements:NewButton(bname,tipINf, callback)
                    showLogo = showLogo or true
                    local ButtonFunction = {}
                    tipINf = tipINf or "Tip: Clicking this nothing will happen!"
                    bname = bname or "Click Me!"
                    callback = callback or function() end

                    local buttonElement = Instance.new("TextButton")
                    local UICorner = Instance.new("UICorner")
                    local btnInfo = Instance.new("TextLabel")
                    local viewInfo = Instance.new("ImageButton")
                    local touch = Instance.new("ImageLabel")
                    local Sample = Instance.new("ImageLabel")

                    table.insert(modules, bname)

                    buttonElement.Name = bname
                    buttonElement.Parent = sectionInners
                    buttonElement.BackgroundColor3 = themeList.ElementColor
                    buttonElement.ClipsDescendants = true
                    buttonElement.Size = UDim2.new(0, 352, 0, 33)
                    buttonElement.AutoButtonColor = false
                    buttonElement.Font = Enum.Font.SourceSans
                    buttonElement.Text = ""
                    buttonElement.TextColor3 = Color3.fromRGB(0, 0, 0)
                    buttonElement.TextSize = 14.000
                    Objects[buttonElement] = "BackgroundColor3"

                    UICorner.CornerRadius = UDim.new(0, 4)
                    UICorner.Parent = buttonElement

                    viewInfo.Name = "viewInfo"
                    viewInfo.Parent = buttonElement
                    viewInfo.BackgroundTransparency = 1.000
                    viewInfo.LayoutOrder = 9
                    viewInfo.Position = UDim2.new(0.930000007, 0, 0.151999995, 0)
                    viewInfo.Size = UDim2.new(0, 23, 0, 23)
                    viewInfo.ZIndex = 2
                    viewInfo.Image = "rbxassetid://3926305904"
                    viewInfo.ImageColor3 = themeList.SchemeColor
                    Objects[viewInfo] = "ImageColor3"
                    viewInfo.ImageRectOffset = Vector2.new(764, 764)
                    viewInfo.ImageRectSize = Vector2.new(36, 36)

                    Sample.Name = "Sample"
                    Sample.Parent = buttonElement
                    Sample.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    Sample.BackgroundTransparency = 1.000
                    Sample.Image = "http://www.roblox.com/asset/?id=4560909609"
                    Sample.ImageColor3 = themeList.SchemeColor
                    Objects[Sample] = "ImageColor3"
                    Sample.ImageTransparency = 0.600

                    local moreInfo = Instance.new("TextLabel")
                    local UICorner = Instance.new("UICorner")

                    moreInfo.Name = "TipMore"
                    moreInfo.Parent = infoContainer
                    moreInfo.BackgroundColor3 = Color3.fromRGB(themeList.SchemeColor.r * 255 - 14, themeList.SchemeColor.g * 255 - 17, themeList.SchemeColor.b * 255 - 13)
                    moreInfo.Position = UDim2.new(0, 0, 2, 0)
                    moreInfo.Size = UDim2.new(0, 353, 0, 33)
                    moreInfo.ZIndex = 9
                    moreInfo.Font = Enum.Font.GothamSemibold
                    moreInfo.Text = "  "..tipINf
                    moreInfo.RichText = true
                    moreInfo.TextColor3 = themeList.TextColor
                    Objects[moreInfo] = "TextColor3"
                    moreInfo.TextSize = 14.000
                    moreInfo.TextXAlignment = Enum.TextXAlignment.Left
                    Objects[moreInfo] = "BackgroundColor3"

                    UICorner.CornerRadius = UDim.new(0, 4)
                    UICorner.Parent = moreInfo

                    touch.Name = "touch"
                    touch.Parent = buttonElement
                    touch.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    touch.BackgroundTransparency = 1.000
                    touch.BorderColor3 = Color3.fromRGB(27, 42, 53)
                    touch.Position = UDim2.new(0.0199999996, 0, 0.180000007, 0)
                    touch.Size = UDim2.new(0, 21, 0, 21)
                    touch.Image = "rbxassetid://3926305904"
                    touch.ImageColor3 = themeList.SchemeColor
                    Objects[touch] = "SchemeColor"
                    touch.ImageRectOffset = Vector2.new(84, 204)
                    touch.ImageRectSize = Vector2.new(36, 36)
                    touch.ImageTransparency = 0

                    btnInfo.Name = "btnInfo"
                    btnInfo.Parent = buttonElement
                    btnInfo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    btnInfo.BackgroundTransparency = 1.000
                    btnInfo.Position = UDim2.new(0.096704483, 0, 0.272727281, 0)
                    btnInfo.Size = UDim2.new(0, 314, 0, 14)
                    btnInfo.Font = Enum.Font.GothamSemibold
                    btnInfo.Text = bname
                    btnInfo.RichText = true
                    btnInfo.TextColor3 = themeList.TextColor
                    Objects[btnInfo] = "TextColor3"
                    btnInfo.TextSize = 14.000
                    btnInfo.TextXAlignment = Enum.TextXAlignment.Left

                    if themeList.SchemeColor == Color3.fromRGB(255,255,255) then
                        Utility:TweenObject(moreInfo, {TextColor3 = Color3.fromRGB(0,0,0)}, 0.2)
                    end 
                    if themeList.SchemeColor == Color3.fromRGB(0,0,0) then
                        Utility:TweenObject(moreInfo, {TextColor3 = Color3.fromRGB(255,255,255)}, 0.2)
                    end 

                    updateSectionFrame()
                                    UpdateSize()

                    local ms = game.Players.LocalPlayer:GetMouse()

                    local btn = buttonElement
                    local sample = Sample

                    btn.MouseButton1Click:Connect(function()
                        if not focusing then
                            callback()
                            local c = sample:Clone()
                            c.Parent = btn
                            local x, y = (ms.X - c.AbsolutePosition.X), (ms.Y - c.AbsolutePosition.Y)
                            c.Position = UDim2.new(0, x, 0, y)
                            local len, size = 0.35, nil
                            if btn.AbsoluteSize.X >= btn.AbsoluteSize.Y then
                                size = (btn.AbsoluteSize.X * 1.5)
                            else
                                size = (btn.AbsoluteSize.Y * 1.5)
                            end
                            c:TweenSizeAndPosition(UDim2.new(0, size, 0, size), UDim2.new(0.5, (-size / 2), 0.5, (-size / 2)), 'Out', 'Quad', len, true, nil)
                            for i = 1, 10 do
                                c.ImageTransparency = c.ImageTransparency + 0.05
                                task.wait(len / 12)
                            end
                            c:Destroy()
                        else
                            for i,v in next, infoContainer:GetChildren() do
                                Utility:TweenObject(v, {Position = UDim2.new(0,0,2,0)}, 0.2)
                                focusing = false
                            end
                            Utility:TweenObject(blurFrame, {BackgroundTransparency = 1}, 0.2)
                        end
                    end)
                    local hovering = false
                    btn.MouseEnter:Connect(function()
                        if not focusing then
                            game.TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
                                BackgroundColor3 = Color3.fromRGB(themeList.ElementColor.r * 255 + 8, themeList.ElementColor.g * 255 + 9, themeList.ElementColor.b * 255 + 10)
                            }):Play()
                            hovering = true
                        end
                    end)
                    btn.MouseLeave:Connect(function()
                        if not focusing then 
                            game.TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
                                BackgroundColor3 = themeList.ElementColor
                            }):Play()
                            hovering = false
                        end
                    end)
                    viewInfo.MouseButton1Click:Connect(function()
                        if not viewDe then
                            viewDe = true
                            focusing = true
                            for i,v in next, infoContainer:GetChildren() do
                                if v ~= moreInfo then
                                    Utility:TweenObject(v, {Position = UDim2.new(0,0,2,0)}, 0.2)
                                end
                            end
                            Utility:TweenObject(moreInfo, {Position = UDim2.new(0,0,0,0)}, 0.2)
                            Utility:TweenObject(blurFrame, {BackgroundTransparency = 0.5}, 0.2)
                            Utility:TweenObject(btn, {BackgroundColor3 = themeList.ElementColor}, 0.2)
                            task.wait(1.5)
                            focusing = false
                            Utility:TweenObject(moreInfo, {Position = UDim2.new(0,0,2,0)}, 0.2)
                            Utility:TweenObject(blurFrame, {BackgroundTransparency = 1}, 0.2)
                            task.wait(0)
                            viewDe = false
                        end
                    end)
                    do
    if not hovering then
                                buttonElement.BackgroundColor3 = themeList.ElementColor
                            end
                            viewInfo.ImageColor3 = themeList.SchemeColor
                            Sample.ImageColor3 = themeList.SchemeColor
                            moreInfo.BackgroundColor3 = Color3.fromRGB(themeList.SchemeColor.r * 255 - 14, themeList.SchemeColor.g * 255 - 17, themeList.SchemeColor.b * 255 - 13)
                            moreInfo.TextColor3 = themeList.TextColor
                            touch.ImageColor3 = themeList.SchemeColor
                            btnInfo.TextColor3 = themeList.TextColor
    end

                    function ButtonFunction:UpdateButton(newTitle)
                        btnInfo.Text = newTitle
                    end
                    return ButtonFunction
                end

                function Elements:NewTextBox(tname, tTip, callback)
                    tname = tname or "Textbox"
                    tTip = tTip or "Gets a value of Textbox"
                    callback = callback or function() end
                    local textboxElement = Instance.new("TextButton")
                    local UICorner = Instance.new("UICorner")
                    local viewInfo = Instance.new("ImageButton")
                    local write = Instance.new("ImageLabel")
                    local TextBox = Instance.new("TextBox")
                    local UICorner_2 = Instance.new("UICorner")
                    local togName = Instance.new("TextLabel")

                    textboxElement.Name = "textboxElement"
                    textboxElement.Parent = sectionInners
                    textboxElement.BackgroundColor3 = themeList.ElementColor
                    textboxElement.ClipsDescendants = true
                    textboxElement.Size = UDim2.new(0, 352, 0, 33)
                    textboxElement.AutoButtonColor = false
                    textboxElement.Font = Enum.Font.SourceSans
                    textboxElement.Text = ""
                    textboxElement.TextColor3 = Color3.fromRGB(0, 0, 0)
                    textboxElement.TextSize = 14.000

                    UICorner.CornerRadius = UDim.new(0, 4)
                    UICorner.Parent = textboxElement

                    viewInfo.Name = "viewInfo"
                    viewInfo.Parent = textboxElement
                    viewInfo.BackgroundTransparency = 1.000
                    viewInfo.LayoutOrder = 9
                    viewInfo.Position = UDim2.new(0.930000007, 0, 0.151999995, 0)
                    viewInfo.Size = UDim2.new(0, 23, 0, 23)
                    viewInfo.ZIndex = 2
                    viewInfo.Image = "rbxassetid://3926305904"
                    viewInfo.ImageColor3 = themeList.SchemeColor
                    viewInfo.ImageRectOffset = Vector2.new(764, 764)
                    viewInfo.ImageRectSize = Vector2.new(36, 36)

                    write.Name = "write"
                    write.Parent = textboxElement
                    write.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    write.BackgroundTransparency = 1.000
                    write.BorderColor3 = Color3.fromRGB(27, 42, 53)
                    write.Position = UDim2.new(0.0199999996, 0, 0.180000007, 0)
                    write.Size = UDim2.new(0, 21, 0, 21)
                    write.Image = "rbxassetid://3926305904"
                    write.ImageColor3 = themeList.SchemeColor
                    write.ImageRectOffset = Vector2.new(324, 604)
                    write.ImageRectSize = Vector2.new(36, 36)

                    TextBox.Parent = textboxElement
                    TextBox.BackgroundColor3 = Color3.fromRGB(themeList.ElementColor.r * 255 - 6, themeList.ElementColor.g * 255 - 6, themeList.ElementColor.b * 255 - 7)
                    TextBox.BorderSizePixel = 0
                    TextBox.ClipsDescendants = true
                    TextBox.Position = UDim2.new(0.488749921, 0, 0.212121218, 0)
                    TextBox.Size = UDim2.new(0, 150, 0, 18)
                    TextBox.ZIndex = 99
                    TextBox.ClearTextOnFocus = false
                    TextBox.Font = Enum.Font.Gotham
                    TextBox.PlaceholderColor3 = Color3.fromRGB(themeList.SchemeColor.r * 255 - 19, themeList.SchemeColor.g * 255 - 26, themeList.SchemeColor.b * 255 - 35)
                    TextBox.PlaceholderText = "Type here!"
                    TextBox.Text = ""
                    TextBox.TextColor3 = themeList.SchemeColor
                    TextBox.TextSize = 12.000

                    UICorner_2.CornerRadius = UDim.new(0, 4)
                    UICorner_2.Parent = TextBox

                    togName.Name = "togName"
                    togName.Parent = textboxElement
                    togName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    togName.BackgroundTransparency = 1.000
                    togName.Position = UDim2.new(0.096704483, 0, 0.272727281, 0)
                    togName.Size = UDim2.new(0, 138, 0, 14)
                    togName.Font = Enum.Font.GothamSemibold
                    togName.Text = tname
                    togName.RichText = true
                    togName.TextColor3 = themeList.TextColor
                    togName.TextSize = 14.000
                    togName.TextXAlignment = Enum.TextXAlignment.Left

                    local moreInfo = Instance.new("TextLabel")
                    local UICorner = Instance.new("UICorner")

                    moreInfo.Name = "TipMore"
                    moreInfo.Parent = infoContainer
                    moreInfo.BackgroundColor3 = Color3.fromRGB(themeList.SchemeColor.r * 255 - 14, themeList.SchemeColor.g * 255 - 17, themeList.SchemeColor.b * 255 - 13)
                    moreInfo.Position = UDim2.new(0, 0, 2, 0)
                    moreInfo.Size = UDim2.new(0, 353, 0, 33)
                    moreInfo.ZIndex = 9
                    moreInfo.Font = Enum.Font.GothamSemibold
                    moreInfo.RichText = true
                    moreInfo.Text = "  "..tTip
                    moreInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
                    moreInfo.TextSize = 14.000
                    moreInfo.TextXAlignment = Enum.TextXAlignment.Left

                    if themeList.SchemeColor == Color3.fromRGB(255,255,255) then
                        Utility:TweenObject(moreInfo, {TextColor3 = Color3.fromRGB(0,0,0)}, 0.2)
                    end 
                    if themeList.SchemeColor == Color3.fromRGB(0,0,0) then
                        Utility:TweenObject(moreInfo, {TextColor3 = Color3.fromRGB(255,255,255)}, 0.2)
                    end 

                    UICorner.CornerRadius = UDim.new(0, 4)
                    UICorner.Parent = moreInfo


                    updateSectionFrame()
                                    UpdateSize()

                    local btn = textboxElement
                    local infBtn = viewInfo

                    btn.MouseButton1Click:Connect(function()
                        if focusing then
                            for i,v in next, infoContainer:GetChildren() do
                                Utility:TweenObject(v, {Position = UDim2.new(0,0,2,0)}, 0.2)
                                focusing = false
                            end
                            Utility:TweenObject(blurFrame, {BackgroundTransparency = 1}, 0.2)
                        end
                    end)
                    local hovering = false
                    btn.MouseEnter:Connect(function()
                        if not focusing then
                            game.TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
                                BackgroundColor3 = Color3.fromRGB(themeList.ElementColor.r * 255 + 8, themeList.ElementColor.g * 255 + 9, themeList.ElementColor.b * 255 + 10)
                            }):Play()
                            hovering = true
                        end 
                    end)

                    btn.MouseLeave:Connect(function()
                        if not focusing then
                            game.TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
                                BackgroundColor3 = themeList.ElementColor
                            }):Play()
                            hovering = false
                        end
                    end)

                    TextBox.FocusLost:Connect(function(EnterPressed)
                        if focusing then
                            for i,v in next, infoContainer:GetChildren() do
                                Utility:TweenObject(v, {Position = UDim2.new(0,0,2,0)}, 0.2)
                                focusing = false
                            end
                            Utility:TweenObject(blurFrame, {BackgroundTransparency = 1}, 0.2)
                        end
                        if not EnterPressed then 
                            return
                        else
                            callback(TextBox.Text)
                            task.wait(0.18)
                            TextBox.Text = ""  
                        end
                    end)

                    viewInfo.MouseButton1Click:Connect(function()
                        if not viewDe then
                            viewDe = true
                            focusing = true
                            for i,v in next, infoContainer:GetChildren() do
                                if v ~= moreInfo then
                                    Utility:TweenObject(v, {Position = UDim2.new(0,0,2,0)}, 0.2)
                                end
                            end
                            Utility:TweenObject(moreInfo, {Position = UDim2.new(0,0,0,0)}, 0.2)
                            Utility:TweenObject(blurFrame, {BackgroundTransparency = 0.5}, 0.2)
                            Utility:TweenObject(btn, {BackgroundColor3 = themeList.ElementColor}, 0.2)
                            task.wait(1.5)
                            focusing = false
                            Utility:TweenObject(moreInfo, {Position = UDim2.new(0,0,2,0)}, 0.2)
                            Utility:TweenObject(blurFrame, {BackgroundTransparency = 1}, 0.2)
                            task.wait(0)
                            viewDe = false
                        end
                    end)
                    do
    if not hovering then
                                textboxElement.BackgroundColor3 = themeList.ElementColor
                            end
                            TextBox.BackgroundColor3 = Color3.fromRGB(themeList.ElementColor.r * 255 - 6, themeList.ElementColor.g * 255 - 6, themeList.ElementColor.b * 255 - 7)
                            viewInfo.ImageColor3 = themeList.SchemeColor
                            moreInfo.BackgroundColor3 = Color3.fromRGB(themeList.SchemeColor.r * 255 - 14, themeList.SchemeColor.g * 255 - 17, themeList.SchemeColor.b * 255 - 13)
                            moreInfo.TextColor3 = themeList.TextColor
                            write.ImageColor3 = themeList.SchemeColor
                            togName.TextColor3 = themeList.TextColor
                            TextBox.PlaceholderColor3 = Color3.fromRGB(themeList.SchemeColor.r * 255 - 19, themeList.SchemeColor.g * 255 - 26, themeList.SchemeColor.b * 255 - 35)
                            TextBox.TextColor3 = themeList.SchemeColor
    end
                end 

                    function Elements:NewToggle(tname, nTip, callback)
                        local TogFunction = {}
                        tname = tname or "Toggle"
                        nTip = nTip or "Prints Current Toggle State"
                        callback = callback or function() end
                        local toggled = false
                        table.insert(SettingsT, tname)

                        local toggleElement = Instance.new("TextButton")
                        local UICorner = Instance.new("UICorner")
                        local toggleDisabled = Instance.new("ImageLabel")
                        local toggleEnabled = Instance.new("ImageLabel")
                        local togName = Instance.new("TextLabel")
                        local viewInfo = Instance.new("ImageButton")
                        local Sample = Instance.new("ImageLabel")

                        toggleElement.Name = "toggleElement"
                        toggleElement.Parent = sectionInners
                        toggleElement.BackgroundColor3 = themeList.ElementColor
                        toggleElement.ClipsDescendants = true
                        toggleElement.Size = UDim2.new(0, 352, 0, 33)
                        toggleElement.AutoButtonColor = false
                        toggleElement.Font = Enum.Font.SourceSans
                        toggleElement.Text = ""
                        toggleElement.TextColor3 = Color3.fromRGB(0, 0, 0)
                        toggleElement.TextSize = 14.000

                        UICorner.CornerRadius = UDim.new(0, 4)
                        UICorner.Parent = toggleElement

                        toggleDisabled.Name = "toggleDisabled"
                        toggleDisabled.Parent = toggleElement
                        toggleDisabled.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        toggleDisabled.BackgroundTransparency = 1.000
                        toggleDisabled.Position = UDim2.new(0.0199999996, 0, 0.180000007, 0)
                        toggleDisabled.Size = UDim2.new(0, 21, 0, 21)
                        toggleDisabled.Image = "rbxassetid://3926309567"
                        toggleDisabled.ImageColor3 = themeList.SchemeColor
                        toggleDisabled.ImageRectOffset = Vector2.new(628, 420)
                        toggleDisabled.ImageRectSize = Vector2.new(48, 48)

                        toggleEnabled.Name = "toggleEnabled"
                        toggleEnabled.Parent = toggleElement
                        toggleEnabled.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        toggleEnabled.BackgroundTransparency = 1.000
                        toggleEnabled.Position = UDim2.new(0.0199999996, 0, 0.180000007, 0)
                        toggleEnabled.Size = UDim2.new(0, 21, 0, 21)
                        toggleEnabled.Image = "rbxassetid://3926309567"
                        toggleEnabled.ImageColor3 = themeList.SchemeColor
                        toggleEnabled.ImageRectOffset = Vector2.new(784, 420)
                        toggleEnabled.ImageRectSize = Vector2.new(48, 48)
                        toggleEnabled.ImageTransparency = 1.000

                        togName.Name = "togName"
                        togName.Parent = toggleElement
                        togName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        togName.BackgroundTransparency = 1.000
                        togName.Position = UDim2.new(0.096704483, 0, 0.272727281, 0)
                        togName.Size = UDim2.new(0, 288, 0, 14)
                        togName.Font = Enum.Font.GothamSemibold
                        togName.Text = tname
                        togName.RichText = true
                        togName.TextColor3 = themeList.TextColor
                        togName.TextSize = 14.000
                        togName.TextXAlignment = Enum.TextXAlignment.Left

                        viewInfo.Name = "viewInfo"
                        viewInfo.Parent = toggleElement
                        viewInfo.BackgroundTransparency = 1.000
                        viewInfo.LayoutOrder = 9
                        viewInfo.Position = UDim2.new(0.930000007, 0, 0.151999995, 0)
                        viewInfo.Size = UDim2.new(0, 23, 0, 23)
                        viewInfo.ZIndex = 2
                        viewInfo.Image = "rbxassetid://3926305904"
                        viewInfo.ImageColor3 = themeList.SchemeColor
                        viewInfo.ImageRectOffset = Vector2.new(764, 764)
                        viewInfo.ImageRectSize = Vector2.new(36, 36)

                        Sample.Name = "Sample"
                        Sample.Parent = toggleElement
                        Sample.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        Sample.BackgroundTransparency = 1.000
                        Sample.Image = "http://www.roblox.com/asset/?id=4560909609"
                        Sample.ImageColor3 = themeList.SchemeColor
                        Sample.ImageTransparency = 0.600

                        local moreInfo = Instance.new("TextLabel")
                        local UICorner = Instance.new("UICorner")

                        moreInfo.Name = "TipMore"
                        moreInfo.Parent = infoContainer
                        moreInfo.BackgroundColor3 = Color3.fromRGB(themeList.SchemeColor.r * 255 - 14, themeList.SchemeColor.g * 255 - 17, themeList.SchemeColor.b * 255 - 13)
                        moreInfo.Position = UDim2.new(0, 0, 2, 0)
                        moreInfo.Size = UDim2.new(0, 353, 0, 33)
                        moreInfo.ZIndex = 9
                        moreInfo.Font = Enum.Font.GothamSemibold
                        moreInfo.RichText = true
                        moreInfo.Text = "  "..nTip
                        moreInfo.TextColor3 = themeList.TextColor
                        moreInfo.TextSize = 14.000
                        moreInfo.TextXAlignment = Enum.TextXAlignment.Left

                        UICorner.CornerRadius = UDim.new(0, 4)
                        UICorner.Parent = moreInfo

                        local ms = game.Players.LocalPlayer:GetMouse()

                        if themeList.SchemeColor == Color3.fromRGB(255,255,255) then
                            Utility:TweenObject(moreInfo, {TextColor3 = Color3.fromRGB(0,0,0)}, 0.2)
                        end 
                        if themeList.SchemeColor == Color3.fromRGB(0,0,0) then
                            Utility:TweenObject(moreInfo, {TextColor3 = Color3.fromRGB(255,255,255)}, 0.2)
                        end 

                        local btn = toggleElement
                        local sample = Sample
                        local img = toggleEnabled
                        local infBtn = viewInfo

                                        updateSectionFrame()
                    UpdateSize()

                        btn.MouseButton1Click:Connect(function()
                            if not focusing then
                                if toggled == false then
                                    game.TweenService:Create(img, TweenInfo.new(0.11, Enum.EasingStyle.Linear,Enum.EasingDirection.In), {
                                        ImageTransparency = 0
                                    }):Play()
                                    local c = sample:Clone()
                                    c.Parent = btn
                                    local x, y = (ms.X - c.AbsolutePosition.X), (ms.Y - c.AbsolutePosition.Y)
                                    c.Position = UDim2.new(0, x, 0, y)
                                    local len, size = 0.35, nil
                                    if btn.AbsoluteSize.X >= btn.AbsoluteSize.Y then
                                        size = (btn.AbsoluteSize.X * 1.5)
                                    else
                                        size = (btn.AbsoluteSize.Y * 1.5)
                                    end
                                    c:TweenSizeAndPosition(UDim2.new(0, size, 0, size), UDim2.new(0.5, (-size / 2), 0.5, (-size / 2)), 'Out', 'Quad', len, true, nil)
                                    for i = 1, 10 do
                                        c.ImageTransparency = c.ImageTransparency + 0.05
                                        task.wait(len / 12)
                                    end
                                    c:Destroy()
                                else
                                    game.TweenService:Create(img, TweenInfo.new(0.11, Enum.EasingStyle.Linear,Enum.EasingDirection.In), {
                                        ImageTransparency = 1
                                    }):Play()
                                    local c = sample:Clone()
                                    c.Parent = btn
                                    local x, y = (ms.X - c.AbsolutePosition.X), (ms.Y - c.AbsolutePosition.Y)
                                    c.Position = UDim2.new(0, x, 0, y)
                                    local len, size = 0.35, nil
                                    if btn.AbsoluteSize.X >= btn.AbsoluteSize.Y then
                                        size = (btn.AbsoluteSize.X * 1.5)
                                    else
                                        size = (btn.AbsoluteSize.Y * 1.5)
                                    end
                                    c:TweenSizeAndPosition(UDim2.new(0, size, 0, size), UDim2.new(0.5, (-size / 2), 0.5, (-size / 2)), 'Out', 'Quad', len, true, nil)
                                    for i = 1, 10 do
                                        c.ImageTransparency = c.ImageTransparency + 0.05
                                        task.wait(len / 12)
                                    end
                                    c:Destroy()
                                end
                                toggled = not toggled
                                pcall(callback, toggled)
                            else
                                for i,v in next, infoContainer:GetChildren() do
                                    Utility:TweenObject(v, {Position = UDim2.new(0,0,2,0)}, 0.2)
                                    focusing = false
                                end
                                Utility:TweenObject(blurFrame, {BackgroundTransparency = 1}, 0.2)
                            end
                        end)
                        local hovering = false
                        btn.MouseEnter:Connect(function()
                            if not focusing then
                                game.TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
                                    BackgroundColor3 = Color3.fromRGB(themeList.ElementColor.r * 255 + 8, themeList.ElementColor.g * 255 + 9, themeList.ElementColor.b * 255 + 10)
                                }):Play()
                                hovering = true
                            end 
                        end)
                        btn.MouseLeave:Connect(function()
                            if not focusing then
                                game.TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
                                    BackgroundColor3 = themeList.ElementColor
                                }):Play()
                                hovering = false
                            end
                        end)

                        do
    if not hovering then
                                    toggleElement.BackgroundColor3 = themeList.ElementColor
                                end
                                toggleDisabled.ImageColor3 = themeList.SchemeColor
                                toggleEnabled.ImageColor3 = themeList.SchemeColor
                                togName.TextColor3 = themeList.TextColor
                                viewInfo.ImageColor3 = themeList.SchemeColor
                                Sample.ImageColor3 = themeList.SchemeColor
                                moreInfo.BackgroundColor3 = Color3.fromRGB(themeList.SchemeColor.r * 255 - 14, themeList.SchemeColor.g * 255 - 17, themeList.SchemeColor.b * 255 - 13)
                                moreInfo.TextColor3 = themeList.TextColor
    end
                        viewInfo.MouseButton1Click:Connect(function()
                            if not viewDe then
                                viewDe = true
                                focusing = true
                                for i,v in next, infoContainer:GetChildren() do
                                    if v ~= moreInfo then
                                        Utility:TweenObject(v, {Position = UDim2.new(0,0,2,0)}, 0.2)
                                    end
                                end
                                Utility:TweenObject(moreInfo, {Position = UDim2.new(0,0,0,0)}, 0.2)
                                Utility:TweenObject(blurFrame, {BackgroundTransparency = 0.5}, 0.2)
                                Utility:TweenObject(btn, {BackgroundColor3 = themeList.ElementColor}, 0.2)
                                task.wait(1.5)
                                focusing = false
                                Utility:TweenObject(moreInfo, {Position = UDim2.new(0,0,2,0)}, 0.2)
                                Utility:TweenObject(blurFrame, {BackgroundTransparency = 1}, 0.2)
                                task.wait(0)
                                viewDe = false
                            end
                        end)
                        function TogFunction:UpdateToggle(newText, isTogOn)
                            isTogOn = isTogOn or toggle
                            if newText ~= nil then 
                                togName.Text = newText
                            end
                            if isTogOn then
                                toggled = true
                                game.TweenService:Create(img, TweenInfo.new(0.11, Enum.EasingStyle.Linear,Enum.EasingDirection.In), {
                                    ImageTransparency = 0
                                }):Play()
                                pcall(callback, toggled)
                            else
                                toggled = false
                                game.TweenService:Create(img, TweenInfo.new(0.11, Enum.EasingStyle.Linear,Enum.EasingDirection.In), {
                                    ImageTransparency = 1
                                }):Play()
                                pcall(callback, toggled)
                            end
                        end
                        return TogFunction
                end

                function Elements:NewSlider(slidInf, slidTip, maxvalue, minvalue, callback)
                    slidInf = slidInf or "Slider"
                    slidTip = slidTip or "Slider tip here"
                    maxvalue = maxvalue or 500
                    minvalue = minvalue or 16
                    startVal = startVal or 0
                    callback = callback or function() end

                    local sliderElement = Instance.new("TextButton")
                    local UICorner = Instance.new("UICorner")
                    local togName = Instance.new("TextLabel")
                    local viewInfo = Instance.new("ImageButton")
                    local sliderBtn = Instance.new("TextButton")
                    local UICorner_2 = Instance.new("UICorner")
                    local UIListLayout = Instance.new("UIListLayout")
                    local sliderDrag = Instance.new("Frame")
                    local UICorner_3 = Instance.new("UICorner")
                    local write = Instance.new("ImageLabel")
                    local val = Instance.new("TextLabel")

                    sliderElement.Name = "sliderElement"
                    sliderElement.Parent = sectionInners
                    sliderElement.BackgroundColor3 = themeList.ElementColor
                    sliderElement.ClipsDescendants = true
                    sliderElement.Size = UDim2.new(0, 352, 0, 33)
                    sliderElement.AutoButtonColor = false
                    sliderElement.Font = Enum.Font.SourceSans
                    sliderElement.Text = ""
                    sliderElement.TextColor3 = Color3.fromRGB(0, 0, 0)
                    sliderElement.TextSize = 14.000

                    UICorner.CornerRadius = UDim.new(0, 4)
                    UICorner.Parent = sliderElement

                    togName.Name = "togName"
                    togName.Parent = sliderElement
                    togName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    togName.BackgroundTransparency = 1.000
                    togName.Position = UDim2.new(0.096704483, 0, 0.272727281, 0)
                    togName.Size = UDim2.new(0, 138, 0, 14)
                    togName.Font = Enum.Font.GothamSemibold
                    togName.Text = slidInf
                    togName.RichText = true
                    togName.TextColor3 = themeList.TextColor
                    togName.TextSize = 14.000
                    togName.TextXAlignment = Enum.TextXAlignment.Left

                    viewInfo.Name = "viewInfo"
                    viewInfo.Parent = sliderElement
                    viewInfo.BackgroundTransparency = 1.000
                    viewInfo.LayoutOrder = 9
                    viewInfo.Position = UDim2.new(0.930000007, 0, 0.151999995, 0)
                    viewInfo.Size = UDim2.new(0, 23, 0, 23)
                    viewInfo.ZIndex = 2
                    viewInfo.Image = "rbxassetid://3926305904"
                    viewInfo.ImageColor3 = themeList.SchemeColor
                    viewInfo.ImageRectOffset = Vector2.new(764, 764)
                    viewInfo.ImageRectSize = Vector2.new(36, 36)

                    sliderBtn.Name = "sliderBtn"
                    sliderBtn.Parent = sliderElement
                    sliderBtn.BackgroundColor3 = Color3.fromRGB(themeList.ElementColor.r * 255 + 5, themeList.ElementColor.g * 255 + 5, themeList.ElementColor.b * 255  + 5)
                    sliderBtn.BorderSizePixel = 0
                    sliderBtn.Position = UDim2.new(0.488749951, 0, 0.393939406, 0)
                    sliderBtn.Size = UDim2.new(0, 149, 0, 6)
                    sliderBtn.AutoButtonColor = false
                    sliderBtn.Font = Enum.Font.SourceSans
                    sliderBtn.Text = ""
                    sliderBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
                    sliderBtn.TextSize = 14.000

                    UICorner_2.Parent = sliderBtn

                    UIListLayout.Parent = sliderBtn
                    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                    UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center

                    sliderDrag.Name = "sliderDrag"
                    sliderDrag.Parent = sliderBtn
                    sliderDrag.BackgroundColor3 = themeList.SchemeColor
                    sliderDrag.BorderColor3 = Color3.fromRGB(74, 99, 135)
                    sliderDrag.BorderSizePixel = 0
                    sliderDrag.Size = UDim2.new(-0.671140969, 100,1,0)

                    UICorner_3.Parent = sliderDrag

                    write.Name = "write"
                    write.Parent = sliderElement
                    write.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    write.BackgroundTransparency = 1.000
                    write.BorderColor3 = Color3.fromRGB(27, 42, 53)
                    write.Position = UDim2.new(0.0199999996, 0, 0.180000007, 0)
                    write.Size = UDim2.new(0, 21, 0, 21)
                    write.Image = "rbxassetid://3926307971"
                    write.ImageColor3 = themeList.SchemeColor
                    write.ImageRectOffset = Vector2.new(404, 164)
                    write.ImageRectSize = Vector2.new(36, 36)

                    val.Name = "val"
                    val.Parent = sliderElement
                    val.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    val.BackgroundTransparency = 1.000
                    val.Position = UDim2.new(0.352386296, 0, 0.272727281, 0)
                    val.Size = UDim2.new(0, 41, 0, 14)
                    val.Font = Enum.Font.GothamSemibold
                    val.Text = minvalue
                    val.TextColor3 = themeList.TextColor
                    val.TextSize = 14.000
                    val.TextTransparency = 1.000
                    val.TextXAlignment = Enum.TextXAlignment.Right

                    local moreInfo = Instance.new("TextLabel")
                    local UICorner = Instance.new("UICorner")

                    moreInfo.Name = "TipMore"
                    moreInfo.Parent = infoContainer
                    moreInfo.BackgroundColor3 = Color3.fromRGB(themeList.SchemeColor.r * 255 - 14, themeList.SchemeColor.g * 255 - 17, themeList.SchemeColor.b * 255 - 13)
                    moreInfo.Position = UDim2.new(0, 0, 2, 0)
                    moreInfo.Size = UDim2.new(0, 353, 0, 33)
                    moreInfo.ZIndex = 9
                    moreInfo.Font = Enum.Font.GothamSemibold
                    moreInfo.Text = "  "..slidTip
                    moreInfo.TextColor3 = themeList.TextColor
                    moreInfo.TextSize = 14.000
                    moreInfo.RichText = true
                    moreInfo.TextXAlignment = Enum.TextXAlignment.Left

                    UICorner.CornerRadius = UDim.new(0, 4)
                    UICorner.Parent = moreInfo

                    if themeList.SchemeColor == Color3.fromRGB(255,255,255) then
                        Utility:TweenObject(moreInfo, {TextColor3 = Color3.fromRGB(0,0,0)}, 0.2)
                    end 
                    if themeList.SchemeColor == Color3.fromRGB(0,0,0) then
                        Utility:TweenObject(moreInfo, {TextColor3 = Color3.fromRGB(255,255,255)}, 0.2)
                    end 


                                    updateSectionFrame()
                    UpdateSize()
                    local mouse = game:GetService("Players").LocalPlayer:GetMouse();

                    local ms = game.Players.LocalPlayer:GetMouse()
                    local uis = game:GetService("UserInputService")
                    local btn = sliderElement
                    local infBtn = viewInfo
                    local hovering = false
                    btn.MouseEnter:Connect(function()
                        if not focusing then
                            game.TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
                                BackgroundColor3 = Color3.fromRGB(themeList.ElementColor.r * 255 + 8, themeList.ElementColor.g * 255 + 9, themeList.ElementColor.b * 255 + 10)
                            }):Play()
                            hovering = true
                        end 
                    end)
                    btn.MouseLeave:Connect(function()
                        if not focusing then
                            game.TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
                                BackgroundColor3 = themeList.ElementColor
                            }):Play()
                            hovering = false
                        end
                    end)        

                    do
    if not hovering then
                                sliderElement.BackgroundColor3 = themeList.ElementColor
                            end
                            moreInfo.TextColor3 = themeList.TextColor
                            moreInfo.BackgroundColor3 = Color3.fromRGB(themeList.SchemeColor.r * 255 - 14, themeList.SchemeColor.g * 255 - 17, themeList.SchemeColor.b * 255 - 13)
                            val.TextColor3 = themeList.TextColor
                            write.ImageColor3 = themeList.SchemeColor
                            togName.TextColor3 = themeList.TextColor
                            viewInfo.ImageColor3 = themeList.SchemeColor
                            sliderBtn.BackgroundColor3 = Color3.fromRGB(themeList.ElementColor.r * 255 + 5, themeList.ElementColor.g * 255 + 5, themeList.ElementColor.b * 255  + 5)
                            sliderDrag.BackgroundColor3 = themeList.SchemeColor
    end

                    local Value
                    sliderBtn.MouseButton1Down:Connect(function()
                        if not focusing then
                            game.TweenService:Create(val, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
                                TextTransparency = 0
                            }):Play()
                            Value = math.floor((((tonumber(maxvalue) - tonumber(minvalue)) / 149) * sliderDrag.AbsoluteSize.X) + tonumber(minvalue)) or 0
                            pcall(function()
                                callback(Value)
                            end)
                            sliderDrag:TweenSize(UDim2.new(0, math.clamp(mouse.X - sliderDrag.AbsolutePosition.X, 0, 149), 0, 6), "InOut", "Linear", 0.05, true)
                            moveconnection = mouse.Move:Connect(function()
                                val.Text = Value
                                Value = math.floor((((tonumber(maxvalue) - tonumber(minvalue)) / 149) * sliderDrag.AbsoluteSize.X) + tonumber(minvalue))
                                pcall(function()
                                    callback(Value)
                                end)
                                sliderDrag:TweenSize(UDim2.new(0, math.clamp(mouse.X - sliderDrag.AbsolutePosition.X, 0, 149), 0, 6), "InOut", "Linear", 0.05, true)
                            end)
                            releaseconnection = uis.InputEnded:Connect(function(Mouse)
                                if Mouse.UserInputType == Enum.UserInputType.MouseButton1 then
                                    Value = math.floor((((tonumber(maxvalue) - tonumber(minvalue)) / 149) * sliderDrag.AbsoluteSize.X) + tonumber(minvalue))
                                    pcall(function()
                                        callback(Value)
                                    end)
                                    val.Text = Value
                                    game.TweenService:Create(val, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
                                        TextTransparency = 1
                                    }):Play()
                                    sliderDrag:TweenSize(UDim2.new(0, math.clamp(mouse.X - sliderDrag.AbsolutePosition.X, 0, 149), 0, 6), "InOut", "Linear", 0.05, true)
                                    moveconnection:Disconnect()
                                    releaseconnection:Disconnect()
                                end
                            end)
                        else
                            for i,v in next, infoContainer:GetChildren() do
                                Utility:TweenObject(v, {Position = UDim2.new(0,0,2,0)}, 0.2)
                                focusing = false
                            end
                            Utility:TweenObject(blurFrame, {BackgroundTransparency = 1}, 0.2)
                        end
                    end)
                    viewInfo.MouseButton1Click:Connect(function()
                        if not viewDe then
                            viewDe = true
                            focusing = true
                            for i,v in next, infoContainer:GetChildren() do
                                if v ~= moreInfo then
                                    Utility:TweenObject(v, {Position = UDim2.new(0,0,2,0)}, 0.2)
                                end
                            end
                            Utility:TweenObject(moreInfo, {Position = UDim2.new(0,0,0,0)}, 0.2)
                            Utility:TweenObject(blurFrame, {BackgroundTransparency = 0.5}, 0.2)
                            Utility:TweenObject(btn, {BackgroundColor3 = themeList.ElementColor}, 0.2)
                            task.wait(1.5)
                            focusing = false
                            Utility:TweenObject(moreInfo, {Position = UDim2.new(0,0,2,0)}, 0.2)
                            Utility:TweenObject(blurFrame, {BackgroundTransparency = 1}, 0.2)
                            task.wait(0)
                            viewDe = false
                        end
                    end)        
                end

                function Elements:NewDropdown(dropname, dropinf, list, callback)
                    local DropFunction = {}
                    dropname = dropname or "Dropdown"
                    list = list or {}
                    dropinf = dropinf or "Dropdown info"
                    callback = callback or function() end   

                    local opened = false
                    local DropYSize = 33


                    local dropFrame = Instance.new("Frame")
                    local dropOpen = Instance.new("TextButton")
                    local listImg = Instance.new("ImageLabel")
                    local itemTextbox = Instance.new("TextLabel")
                    local viewInfo = Instance.new("ImageButton")
                    local UICorner = Instance.new("UICorner")
                    local UIListLayout = Instance.new("UIListLayout")
                    local Sample = Instance.new("ImageLabel")

                    local ms = game.Players.LocalPlayer:GetMouse()
                    Sample.Name = "Sample"
                    Sample.Parent = dropOpen
                    Sample.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    Sample.BackgroundTransparency = 1.000
                    Sample.Image = "http://www.roblox.com/asset/?id=4560909609"
                    Sample.ImageColor3 = themeList.SchemeColor
                    Sample.ImageTransparency = 0.600

                    dropFrame.Name = "dropFrame"
                    dropFrame.Parent = sectionInners
                    dropFrame.BackgroundColor3 = themeList.Background
                    dropFrame.BorderSizePixel = 0
                    dropFrame.Position = UDim2.new(0, 0, 1.23571432, 0)
                    dropFrame.Size = UDim2.new(0, 352, 0, 33)
                    dropFrame.ClipsDescendants = true
                    local sample = Sample
                    local btn = dropOpen
                    dropOpen.Name = "dropOpen"
                    dropOpen.Parent = dropFrame
                    dropOpen.BackgroundColor3 = themeList.ElementColor
                    dropOpen.Size = UDim2.new(0, 352, 0, 33)
                    dropOpen.AutoButtonColor = false
                    dropOpen.Font = Enum.Font.SourceSans
                    dropOpen.Text = ""
                    dropOpen.TextColor3 = Color3.fromRGB(0, 0, 0)
                    dropOpen.TextSize = 14.000
                    dropOpen.ClipsDescendants = true
                    dropOpen.MouseButton1Click:Connect(function()
                        if not focusing then
                            if opened then
                                opened = false
                                dropFrame:TweenSize(UDim2.new(0, 352, 0, 33), "InOut", "Linear", 0.08)
                                task.wait(0.1)
                                updateSectionFrame()
                                UpdateSize()
                                local c = sample:Clone()
                                c.Parent = btn
                                local x, y = (ms.X - c.AbsolutePosition.X), (ms.Y - c.AbsolutePosition.Y)
                                c.Position = UDim2.new(0, x, 0, y)
                                local len, size = 0.35, nil
                                if btn.AbsoluteSize.X >= btn.AbsoluteSize.Y then
                                    size = (btn.AbsoluteSize.X * 1.5)
                                else
                                    size = (btn.AbsoluteSize.Y * 1.5)
                                end
                                c:TweenSizeAndPosition(UDim2.new(0, size, 0, size), UDim2.new(0.5, (-size / 2), 0.5, (-size / 2)), 'Out', 'Quad', len, true, nil)
                                for i = 1, 10 do
                                    c.ImageTransparency = c.ImageTransparency + 0.05
                                    task.wait(len / 12)
                                end
                                c:Destroy()
                            else
                                opened = true
                                dropFrame:TweenSize(UDim2.new(0, 352, 0, UIListLayout.AbsoluteContentSize.Y), "InOut", "Linear", 0.08, true)
                                task.wait(0.1)
                                updateSectionFrame()
                                UpdateSize()
                                local c = sample:Clone()
                                c.Parent = btn
                                local x, y = (ms.X - c.AbsolutePosition.X), (ms.Y - c.AbsolutePosition.Y)
                                c.Position = UDim2.new(0, x, 0, y)
                                local len, size = 0.35, nil
                                if btn.AbsoluteSize.X >= btn.AbsoluteSize.Y then
                                    size = (btn.AbsoluteSize.X * 1.5)
                                else
                                    size = (btn.AbsoluteSize.Y * 1.5)
                                end
                                c:TweenSizeAndPosition(UDim2.new(0, size, 0, size), UDim2.new(0.5, (-size / 2), 0.5, (-size / 2)), 'Out', 'Quad', len, true, nil)
                                for i = 1, 10 do
                                    c.ImageTransparency = c.ImageTransparency + 0.05
                                    task.wait(len / 12)
                                end
                                c:Destroy()
                            end
                        else
                            for i,v in next, infoContainer:GetChildren() do
                                Utility:TweenObject(v, {Position = UDim2.new(0,0,2,0)}, 0.2)
                                focusing = false
                            end
                            Utility:TweenObject(blurFrame, {BackgroundTransparency = 1}, 0.2)
                        end
                    end)

                    listImg.Name = "listImg"
                    listImg.Parent = dropOpen
                    listImg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    listImg.BackgroundTransparency = 1.000
                    listImg.BorderColor3 = Color3.fromRGB(27, 42, 53)
                    listImg.Position = UDim2.new(0.0199999996, 0, 0.180000007, 0)
                    listImg.Size = UDim2.new(0, 21, 0, 21)
                    listImg.Image = "rbxassetid://3926305904"
                    listImg.ImageColor3 = themeList.SchemeColor
                    listImg.ImageRectOffset = Vector2.new(644, 364)
                    listImg.ImageRectSize = Vector2.new(36, 36)

                    itemTextbox.Name = "itemTextbox"
                    itemTextbox.Parent = dropOpen
                    itemTextbox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    itemTextbox.BackgroundTransparency = 1.000
                    itemTextbox.Position = UDim2.new(0.0970000029, 0, 0.273000002, 0)
                    itemTextbox.Size = UDim2.new(0, 138, 0, 14)
                    itemTextbox.Font = Enum.Font.GothamSemibold
                    itemTextbox.Text = dropname
                    itemTextbox.RichText = true
                    itemTextbox.TextColor3 = themeList.TextColor
                    itemTextbox.TextSize = 14.000
                    itemTextbox.TextXAlignment = Enum.TextXAlignment.Left

                    viewInfo.Name = "viewInfo"
                    viewInfo.Parent = dropOpen
                    viewInfo.BackgroundTransparency = 1.000
                    viewInfo.LayoutOrder = 9
                    viewInfo.Position = UDim2.new(0.930000007, 0, 0.151999995, 0)
                    viewInfo.Size = UDim2.new(0, 23, 0, 23)
                    viewInfo.ZIndex = 2
                    viewInfo.Image = "rbxassetid://3926305904"
                    viewInfo.ImageColor3 = themeList.SchemeColor
                    viewInfo.ImageRectOffset = Vector2.new(764, 764)
                    viewInfo.ImageRectSize = Vector2.new(36, 36)

                    UICorner.CornerRadius = UDim.new(0, 4)
                    UICorner.Parent = dropOpen

                    local Sample = Instance.new("ImageLabel")

                    Sample.Name = "Sample"
                    Sample.Parent = dropOpen
                    Sample.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    Sample.BackgroundTransparency = 1.000
                    Sample.Image = "http://www.roblox.com/asset/?id=4560909609"
                    Sample.ImageColor3 = themeList.SchemeColor
                    Sample.ImageTransparency = 0.600

                    UIListLayout.Parent = dropFrame
                    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                    UIListLayout.Padding = UDim.new(0, 3)

                    updateSectionFrame() 
                    UpdateSize()

                    local ms = game.Players.LocalPlayer:GetMouse()
                    local uis = game:GetService("UserInputService")
                    local infBtn = viewInfo

                    local moreInfo = Instance.new("TextLabel")
                    local UICorner = Instance.new("UICorner")

                    moreInfo.Name = "TipMore"
                    moreInfo.Parent = infoContainer
                    moreInfo.BackgroundColor3 = Color3.fromRGB(themeList.SchemeColor.r * 255 - 14, themeList.SchemeColor.g * 255 - 17, themeList.SchemeColor.b * 255 - 13)
                    moreInfo.Position = UDim2.new(0, 0, 2, 0)
                    moreInfo.Size = UDim2.new(0, 353, 0, 33)
                    moreInfo.ZIndex = 9
                    moreInfo.RichText = true
                    moreInfo.Font = Enum.Font.GothamSemibold
                    moreInfo.Text = "  "..dropinf
                    moreInfo.TextColor3 = themeList.TextColor
                    moreInfo.TextSize = 14.000
                    moreInfo.TextXAlignment = Enum.TextXAlignment.Left

                    local hovering = false
                    btn.MouseEnter:Connect(function()
                        if not focusing then
                            game.TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
                                BackgroundColor3 = Color3.fromRGB(themeList.ElementColor.r * 255 + 8, themeList.ElementColor.g * 255 + 9, themeList.ElementColor.b * 255 + 10)
                            }):Play()
                            hovering = true
                        end 
                    end)
                    btn.MouseLeave:Connect(function()
                        if not focusing then
                            game.TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
                                BackgroundColor3 = themeList.ElementColor
                            }):Play()
                            hovering = false
                        end
                    end)        
                    do
    if not hovering then
                                dropOpen.BackgroundColor3 = themeList.ElementColor
                            end
                            Sample.ImageColor3 = themeList.SchemeColor
                            dropFrame.BackgroundColor3 = themeList.Background
                            listImg.ImageColor3 = themeList.SchemeColor
                            itemTextbox.TextColor3 = themeList.TextColor
                            viewInfo.ImageColor3 = themeList.SchemeColor
                            moreInfo.BackgroundColor3 = Color3.fromRGB(themeList.SchemeColor.r * 255 - 14, themeList.SchemeColor.g * 255 - 17, themeList.SchemeColor.b * 255 - 13)
                            moreInfo.TextColor3 = themeList.TextColor
    end
                    UICorner.CornerRadius = UDim.new(0, 4)
                    UICorner.Parent = moreInfo

                    if themeList.SchemeColor == Color3.fromRGB(255,255,255) then
                        Utility:TweenObject(moreInfo, {TextColor3 = Color3.fromRGB(0,0,0)}, 0.2)
                    end 
                    if themeList.SchemeColor == Color3.fromRGB(0,0,0) then
                        Utility:TweenObject(moreInfo, {TextColor3 = Color3.fromRGB(255,255,255)}, 0.2)
                    end 

                    viewInfo.MouseButton1Click:Connect(function()
                        if not viewDe then
                            viewDe = true
                            focusing = true
                            for i,v in next, infoContainer:GetChildren() do
                                if v ~= moreInfo then
                                    Utility:TweenObject(v, {Position = UDim2.new(0,0,2,0)}, 0.2)
                                end
                            end
                            Utility:TweenObject(moreInfo, {Position = UDim2.new(0,0,0,0)}, 0.2)
                            Utility:TweenObject(blurFrame, {BackgroundTransparency = 0.5}, 0.2)
                            Utility:TweenObject(btn, {BackgroundColor3 = themeList.ElementColor}, 0.2)
                            task.wait(1.5)
                            focusing = false
                            Utility:TweenObject(moreInfo, {Position = UDim2.new(0,0,2,0)}, 0.2)
                            Utility:TweenObject(blurFrame, {BackgroundTransparency = 1}, 0.2)
                            task.wait(0)
                            viewDe = false
                        end
                    end)     

                    for i,v in next, list do
                        local optionSelect = Instance.new("TextButton")
                        local UICorner_2 = Instance.new("UICorner")
                        local Sample1 = Instance.new("ImageLabel")

                        local ms = game.Players.LocalPlayer:GetMouse()
                        Sample1.Name = "Sample1"
                        Sample1.Parent = optionSelect
                        Sample1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        Sample1.BackgroundTransparency = 1.000
                        Sample1.Image = "http://www.roblox.com/asset/?id=4560909609"
                        Sample1.ImageColor3 = themeList.SchemeColor
                        Sample1.ImageTransparency = 0.600

                        local sample1 = Sample1
                        DropYSize = DropYSize + 33
                        optionSelect.Name = "optionSelect"
                        optionSelect.Parent = dropFrame
                        optionSelect.BackgroundColor3 = themeList.ElementColor
                        optionSelect.Position = UDim2.new(0, 0, 0.235294119, 0)
                        optionSelect.Size = UDim2.new(0, 352, 0, 33)
                        optionSelect.AutoButtonColor = false
                        optionSelect.Font = Enum.Font.GothamSemibold
                        optionSelect.Text = "  "..v
                        optionSelect.TextColor3 = Color3.fromRGB(themeList.TextColor.r * 255 - 6, themeList.TextColor.g * 255 - 6, themeList.TextColor.b * 255 - 6)
                        optionSelect.TextSize = 14.000
                        optionSelect.TextXAlignment = Enum.TextXAlignment.Left
                        optionSelect.ClipsDescendants = true
                        optionSelect.MouseButton1Click:Connect(function()
                            if not focusing then
                                opened = false
                                callback(v)
                                itemTextbox.Text = v
                                dropFrame:TweenSize(UDim2.new(0, 352, 0, 33), 'InOut', 'Linear', 0.08)
                                task.wait(0.1)
                                updateSectionFrame()
                                UpdateSize()
                                local c = sample1:Clone()
                                c.Parent = optionSelect
                                local x, y = (ms.X - c.AbsolutePosition.X), (ms.Y - c.AbsolutePosition.Y)
                                c.Position = UDim2.new(0, x, 0, y)
                                local len, size = 0.35, nil
                                if optionSelect.AbsoluteSize.X >= optionSelect.AbsoluteSize.Y then
                                    size = (optionSelect.AbsoluteSize.X * 1.5)
                                else
                                    size = (optionSelect.AbsoluteSize.Y * 1.5)
                                end
                                c:TweenSizeAndPosition(UDim2.new(0, size, 0, size), UDim2.new(0.5, (-size / 2), 0.5, (-size / 2)), 'Out', 'Quad', len, true, nil)
                                for i = 1, 10 do
                                    c.ImageTransparency = c.ImageTransparency + 0.05
                                    task.wait(len / 12)
                                end
                                c:Destroy()         
                            else
                                for i,v in next, infoContainer:GetChildren() do
                                    Utility:TweenObject(v, {Position = UDim2.new(0,0,2,0)}, 0.2)
                                    focusing = false
                                end
                                Utility:TweenObject(blurFrame, {BackgroundTransparency = 1}, 0.2)
                            end
                        end)

                        UICorner_2.CornerRadius = UDim.new(0, 4)
                        UICorner_2.Parent = optionSelect

                        local oHover = false
                        optionSelect.MouseEnter:Connect(function()
                            if not focusing then
                                game.TweenService:Create(optionSelect, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
                                    BackgroundColor3 = Color3.fromRGB(themeList.ElementColor.r * 255 + 8, themeList.ElementColor.g * 255 + 9, themeList.ElementColor.b * 255 + 10)
                                }):Play()
                                oHover = true
                            end 
                        end)
                        optionSelect.MouseLeave:Connect(function()
                            if not focusing then
                                game.TweenService:Create(optionSelect, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
                                    BackgroundColor3 = themeList.ElementColor
                                }):Play()
                                oHover = false
                            end
                        end)   
                        do
    if not oHover then
                                    optionSelect.BackgroundColor3 = themeList.ElementColor
                                end
                                optionSelect.TextColor3 = Color3.fromRGB(themeList.TextColor.r * 255 - 6, themeList.TextColor.g * 255 - 6, themeList.TextColor.b * 255 - 6)
                                Sample1.ImageColor3 = themeList.SchemeColor
    end
                    end

                    function DropFunction:Refresh(newList)
                        newList = newList or {}
                        for i,v in next, dropFrame:GetChildren() do
                            if v.Name == "optionSelect" then
                                v:Destroy()
                            end
                        end
                        for i,v in next, newList do
                            local optionSelect = Instance.new("TextButton")
                            local UICorner_2 = Instance.new("UICorner")
                            local Sample11 = Instance.new("ImageLabel")
                            local ms = game.Players.LocalPlayer:GetMouse()
                            Sample11.Name = "Sample11"
                            Sample11.Parent = optionSelect
                            Sample11.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                            Sample11.BackgroundTransparency = 1.000
                            Sample11.Image = "http://www.roblox.com/asset/?id=4560909609"
                            Sample11.ImageColor3 = themeList.SchemeColor
                            Sample11.ImageTransparency = 0.600

                            local sample11 = Sample11
                            DropYSize = DropYSize + 33
                            optionSelect.Name = "optionSelect"
                            optionSelect.Parent = dropFrame
                            optionSelect.BackgroundColor3 = themeList.ElementColor
                            optionSelect.Position = UDim2.new(0, 0, 0.235294119, 0)
                            optionSelect.Size = UDim2.new(0, 352, 0, 33)
                            optionSelect.AutoButtonColor = false
                            optionSelect.Font = Enum.Font.GothamSemibold
                            optionSelect.Text = "  "..v
                            optionSelect.TextColor3 = Color3.fromRGB(themeList.TextColor.r * 255 - 6, themeList.TextColor.g * 255 - 6, themeList.TextColor.b * 255 - 6)
                            optionSelect.TextSize = 14.000
                            optionSelect.TextXAlignment = Enum.TextXAlignment.Left
                            optionSelect.ClipsDescendants = true
                            UICorner_2.CornerRadius = UDim.new(0, 4)
                            UICorner_2.Parent = optionSelect
                            optionSelect.MouseButton1Click:Connect(function()
                                if not focusing then
                                    opened = false
                                    callback(v)
                                    itemTextbox.Text = v
                                    dropFrame:TweenSize(UDim2.new(0, 352, 0, 33), 'InOut', 'Linear', 0.08)
                                    task.wait(0.1)
                                    updateSectionFrame()
                                    UpdateSize()
                                    local c = sample11:Clone()
                                    c.Parent = optionSelect
                                    local x, y = (ms.X - c.AbsolutePosition.X), (ms.Y - c.AbsolutePosition.Y)
                                    c.Position = UDim2.new(0, x, 0, y)
                                    local len, size = 0.35, nil
                                    if optionSelect.AbsoluteSize.X >= optionSelect.AbsoluteSize.Y then
                                        size = (optionSelect.AbsoluteSize.X * 1.5)
                                    else
                                        size = (optionSelect.AbsoluteSize.Y * 1.5)
                                    end
                                    c:TweenSizeAndPosition(UDim2.new(0, size, 0, size), UDim2.new(0.5, (-size / 2), 0.5, (-size / 2)), 'Out', 'Quad', len, true, nil)
                                    for i = 1, 10 do
                                        c.ImageTransparency = c.ImageTransparency + 0.05
                                        task.wait(len / 12)
                                    end
                                    c:Destroy()         
                                else
                                    for i,v in next, infoContainer:GetChildren() do
                                        Utility:TweenObject(v, {Position = UDim2.new(0,0,2,0)}, 0.2)
                                        focusing = false
                                    end
                                    Utility:TweenObject(blurFrame, {BackgroundTransparency = 1}, 0.2)
                                end
                            end)
                                            updateSectionFrame()
                    UpdateSize()
                            local hov = false
                            optionSelect.MouseEnter:Connect(function()
                                if not focusing then
                                    game.TweenService:Create(optionSelect, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
                                        BackgroundColor3 = Color3.fromRGB(themeList.ElementColor.r * 255 + 8, themeList.ElementColor.g * 255 + 9, themeList.ElementColor.b * 255 + 10)
                                    }):Play()
                                    hov = true
                                end 
                            end)
                            optionSelect.MouseLeave:Connect(function()
                                if not focusing then
                                    game.TweenService:Create(optionSelect, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
                                        BackgroundColor3 = themeList.ElementColor
                                    }):Play()
                                    hov = false
                                end
                            end)   
                            do
    if not oHover then
                                        optionSelect.BackgroundColor3 = themeList.ElementColor
                                    end
                                    optionSelect.TextColor3 = Color3.fromRGB(themeList.TextColor.r * 255 - 6, themeList.TextColor.g * 255 - 6, themeList.TextColor.b * 255 - 6)
                                    Sample11.ImageColor3 = themeList.SchemeColor
    end
                        end
                        if opened then 
                            dropFrame:TweenSize(UDim2.new(0, 352, 0, UIListLayout.AbsoluteContentSize.Y), "InOut", "Linear", 0.08, true)
                            task.wait(0.1)
                            updateSectionFrame()
                            UpdateSize()
                        else
                            dropFrame:TweenSize(UDim2.new(0, 352, 0, 33), "InOut", "Linear", 0.08)
                            task.wait(0.1)
                            updateSectionFrame()
                            UpdateSize()
                        end
                    end
                    return DropFunction
                end
                function Elements:NewKeybind(keytext, keyinf, first, callback)
                    keytext = keytext or "KeybindText"
                    keyinf = keyinf or "KebindInfo"
                    callback = callback or function() end
                    local oldKey = first.Name
                    local keybindElement = Instance.new("TextButton")
                    local UICorner = Instance.new("UICorner")
                    local togName = Instance.new("TextLabel")
                    local viewInfo = Instance.new("ImageButton")
                    local touch = Instance.new("ImageLabel")
                    local Sample = Instance.new("ImageLabel")
                    local togName_2 = Instance.new("TextLabel")

                    local ms = game.Players.LocalPlayer:GetMouse()
                    local uis = game:GetService("UserInputService")
                    local infBtn = viewInfo

                    local moreInfo = Instance.new("TextLabel")
                    local UICorner1 = Instance.new("UICorner")

                    local sample = Sample

                    keybindElement.Name = "keybindElement"
                    keybindElement.Parent = sectionInners
                    keybindElement.BackgroundColor3 = themeList.ElementColor
                    keybindElement.ClipsDescendants = true
                    keybindElement.Size = UDim2.new(0, 352, 0, 33)
                    keybindElement.AutoButtonColor = false
                    keybindElement.Font = Enum.Font.SourceSans
                    keybindElement.Text = ""
                    keybindElement.TextColor3 = Color3.fromRGB(0, 0, 0)
                    keybindElement.TextSize = 14.000
                    keybindElement.MouseButton1Click:connect(function(e) 
                        if not focusing then
                            togName_2.Text = ". . ."
                            local a, b = game:GetService('UserInputService').InputBegan:Wait();
                            if a.KeyCode.Name ~= "Unknown" then
                                togName_2.Text = a.KeyCode.Name
                                oldKey = a.KeyCode.Name;
                            end
                            local c = sample:Clone()
                            c.Parent = keybindElement
                            local x, y = (ms.X - c.AbsolutePosition.X), (ms.Y - c.AbsolutePosition.Y)
                            c.Position = UDim2.new(0, x, 0, y)
                            local len, size = 0.35, nil
                            if keybindElement.AbsoluteSize.X >= keybindElement.AbsoluteSize.Y then
                                size = (keybindElement.AbsoluteSize.X * 1.5)
                            else
                                size = (keybindElement.AbsoluteSize.Y * 1.5)
                            end
                            c:TweenSizeAndPosition(UDim2.new(0, size, 0, size), UDim2.new(0.5, (-size / 2), 0.5, (-size / 2)), 'Out', 'Quad', len, true, nil)
                            for i = 1, 10 do
                            c.ImageTransparency = c.ImageTransparency + 0.05
                                task.wait(len / 12)
                            end
                        else
                            for i,v in next, infoContainer:GetChildren() do
                                Utility:TweenObject(v, {Position = UDim2.new(0,0,2,0)}, 0.2)
                                focusing = false
                            end
                            Utility:TweenObject(blurFrame, {BackgroundTransparency = 1}, 0.2)
                        end
                    end)

                    game:GetService("UserInputService").InputBegan:connect(function(current, ok) 
                        if current.KeyCode.Name == oldKey then 
                            callback()
                        end
                    end)

                    moreInfo.Name = "TipMore"
                    moreInfo.Parent = infoContainer
                    moreInfo.BackgroundColor3 = Color3.fromRGB(themeList.SchemeColor.r * 255 - 14, themeList.SchemeColor.g * 255 - 17, themeList.SchemeColor.b * 255 - 13)
                    moreInfo.Position = UDim2.new(0, 0, 2, 0)
                    moreInfo.Size = UDim2.new(0, 353, 0, 33)
                    moreInfo.ZIndex = 9
                    moreInfo.RichText = true
                    moreInfo.Font = Enum.Font.GothamSemibold
                    moreInfo.Text = "  "..keyinf
                    moreInfo.TextColor3 = themeList.TextColor
                    moreInfo.TextSize = 14.000
                    moreInfo.TextXAlignment = Enum.TextXAlignment.Left

                    Sample.Name = "Sample"
                    Sample.Parent = keybindElement
                    Sample.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    Sample.BackgroundTransparency = 1.000
                    Sample.Image = "http://www.roblox.com/asset/?id=4560909609"
                    Sample.ImageColor3 = themeList.SchemeColor
                    Sample.ImageTransparency = 0.600


                    togName.Name = "togName"
                    togName.Parent = keybindElement
                    togName.BackgroundColor3 = themeList.TextColor
                    togName.BackgroundTransparency = 1.000
                    togName.Position = UDim2.new(0.096704483, 0, 0.272727281, 0)
                    togName.Size = UDim2.new(0, 222, 0, 14)
                    togName.Font = Enum.Font.GothamSemibold
                    togName.Text = keytext
                    togName.RichText = true
                    togName.TextColor3 = themeList.TextColor
                    togName.TextSize = 14.000
                    togName.TextXAlignment = Enum.TextXAlignment.Left

                    viewInfo.Name = "viewInfo"
                    viewInfo.Parent = keybindElement
                    viewInfo.BackgroundTransparency = 1.000
                    viewInfo.LayoutOrder = 9
                    viewInfo.Position = UDim2.new(0.930000007, 0, 0.151999995, 0)
                    viewInfo.Size = UDim2.new(0, 23, 0, 23)
                    viewInfo.ZIndex = 2
                    viewInfo.Image = "rbxassetid://3926305904"
                    viewInfo.ImageColor3 = themeList.SchemeColor
                    viewInfo.ImageRectOffset = Vector2.new(764, 764)
                    viewInfo.ImageRectSize = Vector2.new(36, 36)
                    viewInfo.MouseButton1Click:Connect(function()
                        if not viewDe then
                            viewDe = true
                            focusing = true
                            for i,v in next, infoContainer:GetChildren() do
                                if v ~= moreInfo then
                                    Utility:TweenObject(v, {Position = UDim2.new(0,0,2,0)}, 0.2)
                                end
                            end
                            Utility:TweenObject(moreInfo, {Position = UDim2.new(0,0,0,0)}, 0.2)
                            Utility:TweenObject(blurFrame, {BackgroundTransparency = 0.5}, 0.2)
                            Utility:TweenObject(keybindElement, {BackgroundColor3 = themeList.ElementColor}, 0.2)
                            task.wait(1.5)
                            focusing = false
                            Utility:TweenObject(moreInfo, {Position = UDim2.new(0,0,2,0)}, 0.2)
                            Utility:TweenObject(blurFrame, {BackgroundTransparency = 1}, 0.2)
                            task.wait(0)
                            viewDe = false
                        end
                    end)  
                                    updateSectionFrame()
                    UpdateSize()
                    local oHover = false
                    keybindElement.MouseEnter:Connect(function()
                        if not focusing then
                            game.TweenService:Create(keybindElement, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
                                BackgroundColor3 = Color3.fromRGB(themeList.ElementColor.r * 255 + 8, themeList.ElementColor.g * 255 + 9, themeList.ElementColor.b * 255 + 10)
                            }):Play()
                            oHover = true
                        end 
                    end)
                    keybindElement.MouseLeave:Connect(function()
                        if not focusing then
                            game.TweenService:Create(keybindElement, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
                                BackgroundColor3 = themeList.ElementColor
                            }):Play()
                            oHover = false
                        end
                    end)        

                    UICorner1.CornerRadius = UDim.new(0, 4)
                    UICorner1.Parent = moreInfo

                    if themeList.SchemeColor == Color3.fromRGB(255,255,255) then
                        Utility:TweenObject(moreInfo, {TextColor3 = Color3.fromRGB(0,0,0)}, 0.2)
                    end 
                    if themeList.SchemeColor == Color3.fromRGB(0,0,0) then
                        Utility:TweenObject(moreInfo, {TextColor3 = Color3.fromRGB(255,255,255)}, 0.2)
                    end 

                    UICorner.CornerRadius = UDim.new(0, 4)
                    UICorner.Parent = keybindElement

                    touch.Name = "touch"
                    touch.Parent = keybindElement
                    touch.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    touch.BackgroundTransparency = 1.000
                    touch.BorderColor3 = Color3.fromRGB(27, 42, 53)
                    touch.Position = UDim2.new(0.0199999996, 0, 0.180000007, 0)
                    touch.Size = UDim2.new(0, 21, 0, 21)
                    touch.Image = "rbxassetid://3926305904"
                    touch.ImageColor3 = themeList.SchemeColor
                    touch.ImageRectOffset = Vector2.new(364, 284)
                    touch.ImageRectSize = Vector2.new(36, 36)

                    togName_2.Name = "togName"
                    togName_2.Parent = keybindElement
                    togName_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    togName_2.BackgroundTransparency = 1.000
                    togName_2.Position = UDim2.new(0.727386296, 0, 0.272727281, 0)
                    togName_2.Size = UDim2.new(0, 70, 0, 14)
                    togName_2.Font = Enum.Font.GothamSemibold
                    togName_2.Text = oldKey
                    togName_2.TextColor3 = themeList.SchemeColor
                    togName_2.TextSize = 14.000
                    togName_2.TextXAlignment = Enum.TextXAlignment.Right   

                    do
    if not oHover then
                                keybindElement.BackgroundColor3 = themeList.ElementColor
                            end
                            togName_2.TextColor3 = themeList.SchemeColor
                            touch.ImageColor3 = themeList.SchemeColor
                            viewInfo.ImageColor3 = themeList.SchemeColor
                            togName.BackgroundColor3 = themeList.TextColor
                            togName.TextColor3 = themeList.TextColor
                            Sample.ImageColor3 = themeList.SchemeColor
                            moreInfo.TextColor3 = themeList.TextColor
                            moreInfo.BackgroundColor3 = Color3.fromRGB(themeList.SchemeColor.r * 255 - 14, themeList.SchemeColor.g * 255 - 17, themeList.SchemeColor.b * 255 - 13)
    end
                end

                function Elements:NewColorPicker(colText, colInf, defcolor, callback)
                    colText = colText or "ColorPicker"
                    callback = callback or function() end
                    defcolor = defcolor or Color3.fromRGB(1,1,1)
                    local h, s, v = Color3.toHSV(defcolor)
                    local ms = game.Players.LocalPlayer:GetMouse()
                    local colorOpened = false
                    local colorElement = Instance.new("TextButton")
                    local UICorner = Instance.new("UICorner")
                    local colorHeader = Instance.new("Frame")
                    local UICorner_2 = Instance.new("UICorner")
                    local touch = Instance.new("ImageLabel")
                    local togName = Instance.new("TextLabel")
                    local viewInfo = Instance.new("ImageButton")
                    local colorCurrent = Instance.new("Frame")
                    local UICorner_3 = Instance.new("UICorner")
                    local UIListLayout = Instance.new("UIListLayout")
                    local colorInners = Instance.new("Frame")
                    local UICorner_4 = Instance.new("UICorner")
                    local rgb = Instance.new("ImageButton")
                    local UICorner_5 = Instance.new("UICorner")
                    local rbgcircle = Instance.new("ImageLabel")
                    local darkness = Instance.new("ImageButton")
                    local UICorner_6 = Instance.new("UICorner")
                    local darkcircle = Instance.new("ImageLabel")
                    local toggleDisabled = Instance.new("ImageLabel")
                    local toggleEnabled = Instance.new("ImageLabel")
                    local onrainbow = Instance.new("TextButton")
                    local togName_2 = Instance.new("TextLabel")

                    --Properties:
                    local Sample = Instance.new("ImageLabel")
                    Sample.Name = "Sample"
                    Sample.Parent = colorHeader
                    Sample.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    Sample.BackgroundTransparency = 1.000
                    Sample.Image = "http://www.roblox.com/asset/?id=4560909609"
                    Sample.ImageColor3 = themeList.SchemeColor
                    Sample.ImageTransparency = 0.600

                    local btn = colorHeader
                    local sample = Sample

                    colorElement.Name = "colorElement"
                    colorElement.Parent = sectionInners
                    colorElement.BackgroundColor3 = themeList.ElementColor
                    colorElement.BackgroundTransparency = 1.000
                    colorElement.ClipsDescendants = true
                    colorElement.Position = UDim2.new(0, 0, 0.566834569, 0)
                    colorElement.Size = UDim2.new(0, 352, 0, 33)
                    colorElement.AutoButtonColor = false
                    colorElement.Font = Enum.Font.SourceSans
                    colorElement.Text = ""
                    colorElement.TextColor3 = Color3.fromRGB(0, 0, 0)
                    colorElement.TextSize = 14.000
                    colorElement.MouseButton1Click:Connect(function()
                        if not focusing then
                            if colorOpened then
                                colorOpened = false
                                colorElement:TweenSize(UDim2.new(0, 352, 0, 33), "InOut", "Linear", 0.08)
                                task.wait(0.1)
                                updateSectionFrame()
                                UpdateSize()
                                local c = sample:Clone()
                                c.Parent = btn
                                local x, y = (ms.X - c.AbsolutePosition.X), (ms.Y - c.AbsolutePosition.Y)
                                c.Position = UDim2.new(0, x, 0, y)
                                local len, size = 0.35, nil
                                if btn.AbsoluteSize.X >= btn.AbsoluteSize.Y then
                                    size = (btn.AbsoluteSize.X * 1.5)
                                else
                                    size = (btn.AbsoluteSize.Y * 1.5)
                                end
                                c:TweenSizeAndPosition(UDim2.new(0, size, 0, size), UDim2.new(0.5, (-size / 2), 0.5, (-size / 2)), 'Out', 'Quad', len, true, nil)
                                for i = 1, 10 do
                                    c.ImageTransparency = c.ImageTransparency + 0.05
                                    task.wait(len / 12)
                                end
                                c:Destroy()
                            else
                                colorOpened = true
                                colorElement:TweenSize(UDim2.new(0, 352, 0, 141), "InOut", "Linear", 0.08, true)
                                task.wait(0.1)
                                updateSectionFrame()
                                UpdateSize()
                                local c = sample:Clone()
                                c.Parent = btn
                                local x, y = (ms.X - c.AbsolutePosition.X), (ms.Y - c.AbsolutePosition.Y)
                                c.Position = UDim2.new(0, x, 0, y)
                                local len, size = 0.35, nil
                                if btn.AbsoluteSize.X >= btn.AbsoluteSize.Y then
                                    size = (btn.AbsoluteSize.X * 1.5)
                                else
                                    size = (btn.AbsoluteSize.Y * 1.5)
                                end
                                c:TweenSizeAndPosition(UDim2.new(0, size, 0, size), UDim2.new(0.5, (-size / 2), 0.5, (-size / 2)), 'Out', 'Quad', len, true, nil)
                                for i = 1, 10 do
                                    c.ImageTransparency = c.ImageTransparency + 0.05
                                    task.wait(len / 12)
                                end
                                c:Destroy()
                            end
                        else
                            for i,v in next, infoContainer:GetChildren() do
                                Utility:TweenObject(v, {Position = UDim2.new(0,0,2,0)}, 0.2)
                                focusing = false
                            end
                            Utility:TweenObject(blurFrame, {BackgroundTransparency = 1}, 0.2)
                        end
                    end)
                    UICorner.CornerRadius = UDim.new(0, 4)
                    UICorner.Parent = colorElement

                    colorHeader.Name = "colorHeader"
                    colorHeader.Parent = colorElement
                    colorHeader.BackgroundColor3 = themeList.ElementColor
                    colorHeader.Size = UDim2.new(0, 352, 0, 33)
                    colorHeader.ClipsDescendants = true

                    UICorner_2.CornerRadius = UDim.new(0, 4)
                    UICorner_2.Parent = colorHeader

                    touch.Name = "touch"
                    touch.Parent = colorHeader
                    touch.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    touch.BackgroundTransparency = 1.000
                    touch.BorderColor3 = Color3.fromRGB(27, 42, 53)
                    touch.Position = UDim2.new(0.0199999996, 0, 0.180000007, 0)
                    touch.Size = UDim2.new(0, 21, 0, 21)
                    touch.Image = "rbxassetid://3926305904"
                    touch.ImageColor3 = themeList.SchemeColor
                    touch.ImageRectOffset = Vector2.new(44, 964)
                    touch.ImageRectSize = Vector2.new(36, 36)

                    togName.Name = "togName"
                    togName.Parent = colorHeader
                    togName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    togName.BackgroundTransparency = 1.000
                    togName.Position = UDim2.new(0.096704483, 0, 0.272727281, 0)
                    togName.Size = UDim2.new(0, 288, 0, 14)
                    togName.Font = Enum.Font.GothamSemibold
                    togName.Text = colText
                    togName.TextColor3 = themeList.TextColor
                    togName.TextSize = 14.000
                    togName.RichText = true
                    togName.TextXAlignment = Enum.TextXAlignment.Left

                    local moreInfo = Instance.new("TextLabel")
                    local UICorner = Instance.new("UICorner")

                    moreInfo.Name = "TipMore"
                    moreInfo.Parent = infoContainer
                    moreInfo.BackgroundColor3 = Color3.fromRGB(themeList.SchemeColor.r * 255 - 14, themeList.SchemeColor.g * 255 - 17, themeList.SchemeColor.b * 255 - 13)
                    moreInfo.Position = UDim2.new(0, 0, 2, 0)
                    moreInfo.Size = UDim2.new(0, 353, 0, 33)
                    moreInfo.ZIndex = 9
                    moreInfo.Font = Enum.Font.GothamSemibold
                    moreInfo.Text = "  "..colInf
                    moreInfo.TextColor3 = themeList.TextColor
                    moreInfo.TextSize = 14.000
                    moreInfo.RichText = true
                    moreInfo.TextXAlignment = Enum.TextXAlignment.Left

                    UICorner.CornerRadius = UDim.new(0, 4)
                    UICorner.Parent = moreInfo

                    viewInfo.Name = "viewInfo"
                    viewInfo.Parent = colorHeader
                    viewInfo.BackgroundTransparency = 1.000
                    viewInfo.LayoutOrder = 9
                    viewInfo.Position = UDim2.new(0.930000007, 0, 0.151999995, 0)
                    viewInfo.Size = UDim2.new(0, 23, 0, 23)
                    viewInfo.ZIndex = 2
                    viewInfo.Image = "rbxassetid://3926305904"
                    viewInfo.ImageColor3 = themeList.SchemeColor
                    viewInfo.ImageRectOffset = Vector2.new(764, 764)
                    viewInfo.ImageRectSize = Vector2.new(36, 36)
                    viewInfo.MouseButton1Click:Connect(function()
                        if not viewDe then
                            viewDe = true
                            focusing = true
                            for i,v in next, infoContainer:GetChildren() do
                                if v ~= moreInfo then
                                    Utility:TweenObject(v, {Position = UDim2.new(0,0,2,0)}, 0.2)
                                end
                            end
                            Utility:TweenObject(moreInfo, {Position = UDim2.new(0,0,0,0)}, 0.2)
                            Utility:TweenObject(blurFrame, {BackgroundTransparency = 0.5}, 0.2)
                            Utility:TweenObject(colorElement, {BackgroundColor3 = themeList.ElementColor}, 0.2)
                            task.wait(1.5)
                            focusing = false
                            Utility:TweenObject(moreInfo, {Position = UDim2.new(0,0,2,0)}, 0.2)
                            Utility:TweenObject(blurFrame, {BackgroundTransparency = 1}, 0.2)
                            task.wait(0)
                            viewDe = false
                        end
                    end)   

                    colorCurrent.Name = "colorCurrent"
                    colorCurrent.Parent = colorHeader
                    colorCurrent.BackgroundColor3 = defcolor
                    colorCurrent.Position = UDim2.new(0.792613626, 0, 0.212121218, 0)
                    colorCurrent.Size = UDim2.new(0, 42, 0, 18)

                    UICorner_3.CornerRadius = UDim.new(0, 4)
                    UICorner_3.Parent = colorCurrent

                    UIListLayout.Parent = colorElement
                    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                    UIListLayout.Padding = UDim.new(0, 3)

                    colorInners.Name = "colorInners"
                    colorInners.Parent = colorElement
                    colorInners.BackgroundColor3 = themeList.ElementColor
                    colorInners.Position = UDim2.new(0, 0, 0.255319148, 0)
                    colorInners.Size = UDim2.new(0, 352, 0, 105)

                    UICorner_4.CornerRadius = UDim.new(0, 4)
                    UICorner_4.Parent = colorInners

                    rgb.Name = "rgb"
                    rgb.Parent = colorInners
                    rgb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    rgb.BackgroundTransparency = 1.000
                    rgb.Position = UDim2.new(0.0198863633, 0, 0.0476190485, 0)
                    rgb.Size = UDim2.new(0, 211, 0, 93)
                    rgb.Image = "http://www.roblox.com/asset/?id=6523286724"

                    UICorner_5.CornerRadius = UDim.new(0, 4)
                    UICorner_5.Parent = rgb

                    rbgcircle.Name = "rbgcircle"
                    rbgcircle.Parent = rgb
                    rbgcircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    rbgcircle.BackgroundTransparency = 1.000
                    rbgcircle.Size = UDim2.new(0, 14, 0, 14)
                    rbgcircle.Image = "rbxassetid://3926309567"
                    rbgcircle.ImageColor3 = Color3.fromRGB(0, 0, 0)
                    rbgcircle.ImageRectOffset = Vector2.new(628, 420)
                    rbgcircle.ImageRectSize = Vector2.new(48, 48)

                    darkness.Name = "darkness"
                    darkness.Parent = colorInners
                    darkness.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    darkness.BackgroundTransparency = 1.000
                    darkness.Position = UDim2.new(0.636363626, 0, 0.0476190485, 0)
                    darkness.Size = UDim2.new(0, 18, 0, 93)
                    darkness.Image = "http://www.roblox.com/asset/?id=6523291212"

                    UICorner_6.CornerRadius = UDim.new(0, 4)
                    UICorner_6.Parent = darkness

                    darkcircle.Name = "darkcircle"
                    darkcircle.Parent = darkness
                    darkcircle.AnchorPoint = Vector2.new(0.5, 0)
                    darkcircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    darkcircle.BackgroundTransparency = 1.000
                    darkcircle.Size = UDim2.new(0, 14, 0, 14)
                    darkcircle.Image = "rbxassetid://3926309567"
                    darkcircle.ImageColor3 = Color3.fromRGB(0, 0, 0)
                    darkcircle.ImageRectOffset = Vector2.new(628, 420)
                    darkcircle.ImageRectSize = Vector2.new(48, 48)

                    toggleDisabled.Name = "toggleDisabled"
                    toggleDisabled.Parent = colorInners
                    toggleDisabled.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    toggleDisabled.BackgroundTransparency = 1.000
                    toggleDisabled.Position = UDim2.new(0.704659104, 0, 0.0657142699, 0)
                    toggleDisabled.Size = UDim2.new(0, 21, 0, 21)
                    toggleDisabled.Image = "rbxassetid://3926309567"
                    toggleDisabled.ImageColor3 = themeList.SchemeColor
                    toggleDisabled.ImageRectOffset = Vector2.new(628, 420)
                    toggleDisabled.ImageRectSize = Vector2.new(48, 48)

                    toggleEnabled.Name = "toggleEnabled"
                    toggleEnabled.Parent = colorInners
                    toggleEnabled.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    toggleEnabled.BackgroundTransparency = 1.000
                    toggleEnabled.Position = UDim2.new(0.704999983, 0, 0.0659999996, 0)
                    toggleEnabled.Size = UDim2.new(0, 21, 0, 21)
                    toggleEnabled.Image = "rbxassetid://3926309567"
                    toggleEnabled.ImageColor3 = themeList.SchemeColor
                    toggleEnabled.ImageRectOffset = Vector2.new(784, 420)
                    toggleEnabled.ImageRectSize = Vector2.new(48, 48)
                    toggleEnabled.ImageTransparency = 1.000

                    onrainbow.Name = "onrainbow"
                    onrainbow.Parent = toggleEnabled
                    onrainbow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    onrainbow.BackgroundTransparency = 1.000
                    onrainbow.Position = UDim2.new(2.90643607e-06, 0, 0, 0)
                    onrainbow.Size = UDim2.new(1, 0, 1, 0)
                    onrainbow.Font = Enum.Font.SourceSans
                    onrainbow.Text = ""
                    onrainbow.TextColor3 = Color3.fromRGB(0, 0, 0)
                    onrainbow.TextSize = 14.000

                    togName_2.Name = "togName"
                    togName_2.Parent = colorInners
                    togName_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    togName_2.BackgroundTransparency = 1.000
                    togName_2.Position = UDim2.new(0.779999971, 0, 0.100000001, 0)
                    togName_2.Size = UDim2.new(0, 278, 0, 14)
                    togName_2.Font = Enum.Font.GothamSemibold
                    togName_2.Text = "Rainbow"
                    togName_2.TextColor3 = themeList.TextColor
                    togName_2.TextSize = 14.000
                    togName_2.TextXAlignment = Enum.TextXAlignment.Left

                    if themeList.SchemeColor == Color3.fromRGB(255,255,255) then
                        Utility:TweenObject(moreInfo, {TextColor3 = Color3.fromRGB(0,0,0)}, 0.2)
                    end 
                    if themeList.SchemeColor == Color3.fromRGB(0,0,0) then
                        Utility:TweenObject(moreInfo, {TextColor3 = Color3.fromRGB(255,255,255)}, 0.2)
                    end 
                    local hovering = false

                    colorElement.MouseEnter:Connect(function()
                        if not focusing then
                            game.TweenService:Create(colorElement, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
                                BackgroundColor3 = Color3.fromRGB(themeList.ElementColor.r * 255 + 8, themeList.ElementColor.g * 255 + 9, themeList.ElementColor.b * 255 + 10)
                            }):Play()
                            hovering = true
                        end 
                    end)
                    colorElement.MouseLeave:Connect(function()
                        if not focusing then
                            game.TweenService:Create(colorElement, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
                                BackgroundColor3 = themeList.ElementColor
                            }):Play()
                            hovering = false
                        end
                    end)        

                    if themeList.SchemeColor == Color3.fromRGB(255,255,255) then
                        Utility:TweenObject(moreInfo, {TextColor3 = Color3.fromRGB(0,0,0)}, 0.2)
                    end 
                    if themeList.SchemeColor == Color3.fromRGB(0,0,0) then
                        Utility:TweenObject(moreInfo, {TextColor3 = Color3.fromRGB(255,255,255)}, 0.2)
                    end 
                    do
    if not hovering then
                                colorElement.BackgroundColor3 = themeList.ElementColor
                            end
                            touch.ImageColor3 = themeList.SchemeColor
                            colorHeader.BackgroundColor3 = themeList.ElementColor
                            togName.TextColor3 = themeList.TextColor
                            moreInfo.BackgroundColor3 = Color3.fromRGB(themeList.SchemeColor.r * 255 - 14, themeList.SchemeColor.g * 255 - 17, themeList.SchemeColor.b * 255 - 13)
                            moreInfo.TextColor3 = themeList.TextColor
                            viewInfo.ImageColor3 = themeList.SchemeColor
                            colorInners.BackgroundColor3 = themeList.ElementColor
                            toggleDisabled.ImageColor3 = themeList.SchemeColor
                            toggleEnabled.ImageColor3 = themeList.SchemeColor
                            togName_2.TextColor3 = themeList.TextColor
                            Sample.ImageColor3 = themeList.SchemeColor
    end
                    updateSectionFrame()
                    UpdateSize()
                    local plr = game.Players.LocalPlayer
                    local mouse = plr:GetMouse()
                    local uis = game:GetService('UserInputService')
                    local rs = game:GetService("RunService")
                    local colorpicker = false
                    local darknesss = false
                    local dark = false
                    local rgb = rgb    
                    local dark = darkness    
                    local cursor = rbgcircle
                    local cursor2 = darkcircle
                    local color = {1,1,1}
                    local rainbow = false
                    local rainbowconnection
                    local counter = 0
                    --
                    local function zigzag(X) return math.acos(math.cos(X*math.pi))/math.pi end
                    counter = 0
                    local function mouseLocation()
                        return plr:GetMouse()
                    end
                    local function cp()
                        if colorpicker then
                            local ml = mouseLocation()
                            local x,y = ml.X - rgb.AbsolutePosition.X,ml.Y - rgb.AbsolutePosition.Y
                            local maxX,maxY = rgb.AbsoluteSize.X,rgb.AbsoluteSize.Y
                            if x<0 then x=0 end
                            if x>maxX then x=maxX end
                            if y<0 then y=0 end
                            if y>maxY then y=maxY end
                            x = x/maxX
                            y = y/maxY
                            local cx = cursor.AbsoluteSize.X/2
                            local cy = cursor.AbsoluteSize.Y/2
                            cursor.Position = UDim2.new(x,-cx,y,-cy)
                            color = {1-x,1-y,color[3]}
                            local realcolor = Color3.fromHSV(color[1],color[2],color[3])
                            colorCurrent.BackgroundColor3 = realcolor
                            callback(realcolor)
                        end
                        if darknesss then
                            local ml = mouseLocation()
                            local y = ml.Y - dark.AbsolutePosition.Y
                            local maxY = dark.AbsoluteSize.Y
                            if y<0 then y=0 end
                            if y>maxY then y=maxY end
                            y = y/maxY
                            local cy = cursor2.AbsoluteSize.Y/2
                            cursor2.Position = UDim2.new(0.5,0,y,-cy)
                            cursor2.ImageColor3 = Color3.fromHSV(0,0,y)
                            color = {color[1],color[2],1-y}
                            local realcolor = Color3.fromHSV(color[1],color[2],color[3])
                            colorCurrent.BackgroundColor3 = realcolor
                            callback(realcolor)
                        end
                    end

                    local function setcolor(tbl)
                        local cx = cursor.AbsoluteSize.X/2
                        local cy = cursor.AbsoluteSize.Y/2
                        color = {tbl[1],tbl[2],tbl[3]}
                        cursor.Position = UDim2.new(color[1],-cx,color[2]-1,-cy)
                        cursor2.Position = UDim2.new(0.5,0,color[3]-1,-cy)
                        local realcolor = Color3.fromHSV(color[1],color[2],color[3])
                        colorCurrent.BackgroundColor3 = realcolor
                    end
                    local function setrgbcolor(tbl)
                        local cx = cursor.AbsoluteSize.X/2
                        local cy = cursor.AbsoluteSize.Y/2
                        color = {tbl[1],tbl[2],color[3]}
                        cursor.Position = UDim2.new(color[1],-cx,color[2]-1,-cy)
                        local realcolor = Color3.fromHSV(color[1],color[2],color[3])
                        colorCurrent.BackgroundColor3 = realcolor
                        callback(realcolor)
                    end
                    local function togglerainbow()
                        if rainbow then
                            game.TweenService:Create(toggleEnabled, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
                                ImageTransparency = 1
                            }):Play()
                            rainbow = false
                            rainbowconnection:Disconnect()
                        else
                            game.TweenService:Create(toggleEnabled, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
                                ImageTransparency = 0
                            }):Play()
                            rainbow = true
                            rainbowconnection = rs.RenderStepped:Connect(function()
                                setrgbcolor({zigzag(counter),1,1})
                                counter = counter + 0.01
                            end)
                        end
                    end

                    onrainbow.MouseButton1Click:Connect(togglerainbow)
                    --
                    mouse.Move:connect(cp)
                    rgb.MouseButton1Down:connect(function()colorpicker=true end)
                    dark.MouseButton1Down:connect(function()darknesss=true end)
                    uis.InputEnded:Connect(function(input)
                        if input.UserInputType.Name == 'MouseButton1' then
                            if darknesss then darknesss = false end
                            if colorpicker then colorpicker = false end
                        end
                    end)
                    setcolor({h,s,v})
                end

                function Elements:NewLabel(title)
                	local labelFunctions = {}
                	local label = Instance.new("TextLabel")
                	local UICorner = Instance.new("UICorner")
                	label.Name = "label"
                	label.Parent = sectionInners
                	label.BackgroundColor3 = themeList.SchemeColor
                	label.BorderSizePixel = 0
    				label.ClipsDescendants = true
                	label.Text = title
               		label.Size = UDim2.new(0, 352, 0, 33)
    	            label.Font = Enum.Font.Gotham
    	            label.Text = "  "..title
    	            label.RichText = true
    	            label.TextColor3 = themeList.TextColor
    	            Objects[label] = "TextColor3"
    	            label.TextSize = 14.000
    	            label.TextXAlignment = Enum.TextXAlignment.Left

    	           	UICorner.CornerRadius = UDim.new(0, 4)
                    UICorner.Parent = label

    	            if themeList.SchemeColor == Color3.fromRGB(255,255,255) then
    	                Utility:TweenObject(label, {TextColor3 = Color3.fromRGB(0,0,0)}, 0.2)
    	            end 
    	            if themeList.SchemeColor == Color3.fromRGB(0,0,0) then
    	                Utility:TweenObject(label, {TextColor3 = Color3.fromRGB(255,255,255)}, 0.2)
    	            end 

    		        do
    label.BackgroundColor3 = themeList.SchemeColor
    		                label.TextColor3 = themeList.TextColor
    end
                    updateSectionFrame()
                    UpdateSize()
                    function labelFunctions:UpdateLabel(newText)
                    	if label.Text ~= "  "..newText then
                    		label.Text = "  "..newText
                    	end
                    end	
                    return labelFunctions
                end	
                return Elements
            end
            return Sections
        end  
        return Tabs
    end
    return Kavo
    end)()

    if not Library then
        warn("[R1] Critical: Failed to initialize embedded Kavo UI!")
        return
    end

    -- CFG table
    local CFG = {
        ESP=true, Box=true, Name=true, HP=true, Dist=true, Tracer=false,
        NoRecoil=true, MaxDist=900,
    }

    -- Create Window (Themes: DarkTheme, BloodTheme, GrapeTheme, Ocean, Midnight, Sentinel, Synapse)
    local Window = Library.CreateLib("R1 Battle Royale  " .. CHEAT_VER, "BloodTheme")

    -- Tabs
    local ESPTab    = Window:NewTab("ESP")
    local CombatTab = Window:NewTab("Combat")
    local ConfigTab = Window:NewTab("Config")

    -- ─── ESP Tab ───
    local VisualSection   = ESPTab:NewSection("Visuals")
    local SettingsSection = ESPTab:NewSection("Settings")

    VisualSection:NewToggle("ESP Enable", "Toggle ESP visibility", function(v)
        CFG.ESP = v
    end)
    VisualSection:NewToggle("Box ESP", "Draw 2D Box", function(v)
        CFG.Box = v
    end)
    VisualSection:NewToggle("Name Tag", "Show player username", function(v)
        CFG.Name = v
    end)
    VisualSection:NewToggle("HP Bar", "Show health bar", function(v)
        CFG.HP = v
    end)
    VisualSection:NewToggle("Distance", "Show distance", function(v)
        CFG.Dist = v
    end)
    VisualSection:NewToggle("Tracer", "Draw snapline to player", function(v)
        CFG.Tracer = v
    end)

    SettingsSection:NewSlider("Max Distance", "ESP render distance (Studs)", 2000, 100, function(v)
        CFG.MaxDist = v
    end)

    -- ─── Combat Tab ───
    local WeaponSection = CombatTab:NewSection("Weapon")

    WeaponSection:NewToggle("No Recoil", "Eliminate recoil", function(v)
        CFG.NoRecoil = v
        if v then patchRecoil() end
    end)

    -- ─── Config Tab ───
    local MenuSection = ConfigTab:NewSection("Menu Config")

    MenuSection:NewKeybind("Toggle UI Key", "Hotkey to open/close menu", Enum.KeyCode.F10, function()
        Library:ToggleUI()
    end)

    -- F10 hotkey fallback (unconditional so F10 toggles even when menu/game has input focus)
    local f10Conn = UIS.InputBegan:Connect(function(i, gp)
        if i.KeyCode == Enum.KeyCode.F10 then
            Library:ToggleUI()
        end
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
    local descAddedConn = workspace.DescendantAdded:Connect(function(obj)
        if obj.ClassName=="Humanoid" then task.defer(function() addModel(obj.Parent) end) end
    end)
    local descRemovedConn = workspace.DescendantRemoving:Connect(function(obj)
        if obj.ClassName=="HumanoidRootPart" and obj.Parent then
            task.defer(function() removeModel(obj.Parent) end)
        end
    end)

    local maxDistSq = CFG.MaxDist*CFG.MaxDist
    local heartbeatConn = RunService.Heartbeat:Connect(function()
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
    local renderConn = RunService.RenderStepped:Connect(function()
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

    -- Store active references for cleanup & persistence
    env.R1_entries = entries
    env.R1_CFG = CFG
    env.R1_PatchRecoil = patchRecoil

    env.R1_Unload = function()
        pcall(function() if f10Conn then f10Conn:Disconnect() end end)
        pcall(function() if descAddedConn then descAddedConn:Disconnect() end end)
        pcall(function() if descRemovedConn then descRemovedConn:Disconnect() end end)
        pcall(function() if heartbeatConn then heartbeatConn:Disconnect() end end)
        pcall(function() if renderConn then renderConn:Disconnect() end end)
        pcall(function()
            for _, e in ipairs(entries or {}) do
                if e.dr then
                    for _, d in pairs(e.dr) do pcall(function() d:Remove() end) end
                end
            end
        end)
        cleanupOldGuis()
        env.R1_Loaded = false
    end

    print("[R1 Cheat] Loaded | " .. #entries .. " players")
end

-- ============================================================
-- ENTRY POINT — session persistence via env
-- ============================================================
local function startCheat()
    if env.R1_Loaded then
        warn("[R1 Cheat] Already active — running recoil patch on existing session.")
        if type(env.R1_PatchRecoil) == "function" then
            pcall(env.R1_PatchRecoil)
        end
        return
    end
    env.R1_Loaded = true

    loadCheat()

    -- Safe character respawn handler: NEVER re-injects UI or duplicates loops!
    lp.CharacterAdded:Connect(function(chr)
        task.wait(0.5) -- wait for weapons/character to populate
        if env.R1_CFG and env.R1_CFG.NoRecoil and type(env.R1_PatchRecoil) == "function" then
            pcall(env.R1_PatchRecoil)
        end
        cam = workspace.CurrentCamera or cam
    end)
end

local okMain, errMain = pcall(function()
    startCheat()
end)

if not okMain then
    warn("[R1 Cheat Startup Error]: " .. tostring(errMain))
end
