--[[==========================================================================
    ██╗   ██╗ ██████╗ ██╗  ██╗███████╗██╗         ██████╗  █████╗ ██████╗  █████╗ ██████╗
    ██║   ██║██╔═══██╗╚██╗██╔╝██╔════╝██║         ██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗
    ██║   ██║██║   ██║ ╚███╔╝ █████╗  ██║         ██████╔╝███████║███╔╝██║███████║██║  ██║
    ╚██╗ ██╔╝██║   ██║ ██╔██╗ ██╔══╝  ██║         ██╔══██╗██╔══██║██╔═██╗ ██╔══██║██║  ██║
     ╚████╔╝ ╚██████╔╝██╔╝ ██╗███████╗███████╗    ██║  ██║██║  ██║██║  ██╗██║  ██║██████╔╝
      ╚═══╝   ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝    ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝
    --------------------------------------------------------------------------
    VOXEL RADAR  v8.0   |  universal enemy vision  |  Linoria UI
    --------------------------------------------------------------------------
    STEALTH CONTRACT
      * zero console output
      * zero static instance names (ทุกชื่อสุ่มใหม่ทุก session)
      * Highlight อยู่ใน Lighting ไม่ใช่ Workspace -> ไม่ติดสแกน descendant
      * GUI อยู่ใน gethui()/CoreGui + protect_gui
      * ไม่มี HTTP request, ไม่มี _G pollution (เหลือ key เดียวไว้ purge)
      * target scan 4Hz, drawing reuse pool, ไม่มี allocation ต่อเฟรมเกินจำเป็น
    HOTKEYS
      RightShift / RightControl = เปิด-ปิดเมนู
      Z = เปิด-ปิด Chams
    ==========================================================================]]

-- (Drawing ไม่จำเป็นต่อการรัน: ถ้าไม่มี ระบบแถบเลือดจะปิดตัวเองเงียบ ๆ)

local _ok, _err = pcall(function()
--[[==========================================================================
    VOXEL RADAR // CORE ENGINE  v8.0   (silent build)
    --------------------------------------------------------------------------
    No prints. No workspace traces. No static instance names.
    Everything that can be cached is cached. Nothing runs at 60Hz that
    doesn't have to.
==========================================================================]]

local Core = (function()

	local WS       = game:GetService("Workspace")
	local Players  = game:GetService("Players")
	local RS       = game:GetService("RunService")
	local UIS      = game:GetService("UserInputService")
	local Lighting = game:GetService("Lighting")
	local LP       = Players.LocalPlayer

	local genv = (getgenv and getgenv()) or _G
	local now  = os.clock

	math.randomseed((os.time() % 2147483) + math.floor(now() * 1000))

	-- random lowercase/digit name: nothing in the tree is ever called "Chams"
	local function rid(n)
		n = n or 8
		local out, r = {}, nil
		for i = 1, n do
			r = math.random(1, 36)
			out[i] = (r <= 26) and string.char(96 + r) or tostring(r - 27)
		end
		return table.concat(out)
	end

	-- =====================================================================
	-- SETTINGS
	-- =====================================================================
	local S = {
		Profile = "Legit",          -- Legit | Rage | Custom
		Panic   = false,
		Keys = {
			Panic = "Delete",
		},
		Chams = {
			Enabled   = true,
			Color     = Color3.fromRGB(255, 45, 65),
			Fill      = 0.55,
			Outline   = 0.00,
			Depth     = "XRay",      -- "XRay" | "Glow"
			MaxCount  = 32,
			MaxDist   = 1200,
		},
		Skeleton = {
			Enabled  = false,
			MaxCount = 8,
			MaxDist  = 250,
			Thickness = 1,
		},
		Bars = {
			Enabled   = true,
			ShowName  = true,
			ShowHP    = true,
			ShowDist  = true,
			MaxDist   = 900,
		},
		Recoil = {
			Enabled   = false,
			Strength  = 3.0,
			Smooth    = 2,
		},
		Detect = {
			Mode          = "Auto",   -- Auto | FFA | Strict
			Bots          = true,
			WorkspaceScan = true,
			Teamless      = false,    -- ไฮไลต์คนที่ยังไม่มีทีม (lobby / รอเลือกฝั่ง)
		},
		Human = {
			Enabled = true,
			MinGap  = 45,             -- วินาที: ห่างขั้นต่ำระหว่างการ "กะพริบ"
			MaxGap  = 130,
			MinHold = 0.15,           -- กะพริบนานกี่วินาที
			MaxHold = 0.60,
		},
		Fps = {
			Enabled = false,
		},
	}

	-- preset ต่อโหมด
	local PROFILES = {
		Legit = {
			Chams    = { MaxCount = 12, MaxDist = 450, Fill = 0.72, Outline = 0.55, Depth = "Glow" },
			Skeleton = { Enabled = false, MaxCount = 6, MaxDist = 200 },
			Bars     = { Enabled = true, MaxDist = 400 },
			Human    = { Enabled = true, MinGap = 35, MaxGap = 90, MinHold = 0.2, MaxHold = 0.7 },
		},
		Rage = {
			Chams    = { MaxCount = 48, MaxDist = 1800, Fill = 0.45, Outline = 0.0, Depth = "XRay" },
			Skeleton = { Enabled = true, MaxCount = 10, MaxDist = 350 },
			Bars     = { Enabled = true, MaxDist = 1200 },
			Human    = { Enabled = false },
		},
	}

	-- ค่าเริ่มต้นต่อเกม (ถ้าไม่มี config ที่เซฟไว้)
	local PRESET_BY_PLACE = {
		[78884249003161] = "Legit",   -- Voxel Wars
	}

	-- =====================================================================
	-- LEGACY PURGE (previous versions of this script)
	-- =====================================================================
	local function purgeLegacy()
		if type(genv.__vx) == "table" and type(genv.__vx.destroy) == "function" then
			pcall(genv.__vx.destroy)
		end
		if genv.__vx_gui then
			pcall(function() genv.__vx_gui:Destroy() end)
			genv.__vx_gui = nil
		end
		local pg = LP:FindFirstChildOfClass("PlayerGui")
		for _, n in ipairs({ "FullMapChamsGui", "UniversalChamsGui", "SentinelChamsGui", "TitaniumSentinel" }) do
			local g = pg and pg:FindFirstChild(n)
			if g then pcall(function() g:Destroy() end) end
		end
		local n = 0
		local function sweep(model)
			if not model then return end
			for _, d in ipairs(model:GetDescendants()) do
				if d:IsA("Highlight") then
					local on = d.Name
					if on:find("Sentinel") or on:find("Universal") or on:find("Chams") then
						pcall(function() d:Destroy() end)
					end
				end
				n = n + 1
				if n % 800 == 0 then task.wait() end
			end
		end

		for _, p in ipairs(Players:GetPlayers()) do sweep(p.Character) end
		for _, fname in ipairs({ "Characters", "BotRigs", "Bots", "Units", "Rigs", "Enemies", "NPCs", "Mobs" }) do
			local f = WS:FindFirstChild(fname)
			if f then
				for _, m in ipairs(f:GetChildren()) do sweep(m) end
			end
		end
		for _, c in ipairs(Lighting:GetChildren()) do
			if c:IsA("Highlight") then pcall(function() c:Destroy() end) end
		end
	end
	purgeLegacy()

	-- =====================================================================
	-- CHARACTER / PROP CLASSIFICATION
	-- =====================================================================
	local IGNORE = {
		vehiclehulls = true, vehicles = true, cars = true, tanks = true,
		helicopters = true, helis = true, planes = true, boats = true,
		thirdpersonweaponstash = true, debris = true, map = true, maps = true,
		droppedweapons = true, droppeditems = true, ragdolls = true, ragdoll = true,
		botguns = true, camera = true, effects = true, props = true, prop = true,
		interactables = true, baseparts = true, hitboxes = true, projectiles = true,
	}

	local CT = { idf = 1, fbi = 1, sas = 1, swat = 1, gign = 1, seal = 1, gsg9 = 1 }
	local TT = { phoenix = 1, ["elite crew"] = 1, anarchist = 1, balkan = 1, pirate = 1, professional = 1, zombie = 1 }

	local function norm(v)
		if type(v) == "string" then
			if #v > 0 then return v:lower() end
			return nil
		end
		if typeof(v) == "EnumItem" then return v.Name:lower() end
		return nil
	end

	local function identity(model)
		local n = norm(model:GetAttribute("CharacterName")) or norm(model:GetAttribute("Faction"))
		if not n then return nil end
		if CT[n] then return "ct" end
		if TT[n] then return "t" end
		return nil
	end

	local my = { teamName = nil, teamAttr = nil, faction = nil, neutral = false, color = nil }

	local function refreshMy()
		local t = LP.Team
		my.teamName = t and norm(t.Name) or nil
		my.teamAttr = norm(LP:GetAttribute("Team")) or norm(LP:GetAttribute("TeamName")) or norm(LP:GetAttribute("Faction"))
		my.neutral = LP.Neutral == true
		my.color   = LP.TeamColor
		my.faction = (LP.Character and identity(LP.Character)) or nil
	end

	local function looksLikeCharacter(model)
		if not model:IsA("Model") then return false end
		if model == LP.Character then return false end

		local hum  = model:FindFirstChildOfClass("Humanoid")
		local root = model:FindFirstChild("HumanoidRootPart")
			or model:FindFirstChild("Head")
			or model:FindFirstChild("UpperTorso")
			or model.PrimaryPart
		local hasAttr = model:GetAttribute("Health") ~= nil
		if not (hum or hasAttr) then return false end
		if not root then return false end

		-- deep vehicle test only when there's no humanoid (cheap in the common case)
		if not hum and model:FindFirstChildWhichIsA("VehicleSeat", true) then return false end

		if IGNORE[model.Name:lower()] then return false end
		local p1 = model.Parent
		if p1 and p1 ~= WS then
			if IGNORE[p1.Name:lower()] then return false end
			local p2 = p1.Parent
			if p2 and p2 ~= WS and IGNORE[p2.Name:lower()] then return false end
		end
		return true
	end

	-- =====================================================================
	-- RELATION (enemy / ally)
	-- =====================================================================
	local function relation(model, plr)
		if S.Detect.Mode == "FFA" then return true end

		if plr then
			local t    = plr.Team
			local tn   = t and norm(t.Name) or nil
			local ta   = norm(plr:GetAttribute("Team")) or norm(plr:GetAttribute("TeamName")) or norm(plr:GetAttribute("Faction"))
			local neut = plr.Neutral == true

			if my.teamName and tn and not my.neutral and not neut then
				return my.teamName ~= tn
			end
			if my.teamAttr and ta then
				return my.teamAttr ~= ta
			end
			local mf, tf = my.faction, identity(model)
			if mf and tf then return mf ~= tf end
			if my.color and plr.TeamColor
				and my.color.Name ~= "White"
				and plr.TeamColor.Name ~= "White" then
				return my.color ~= plr.TeamColor
			end
			-- เรามีทีมอยู่ แต่เป้ายังไม่มีทีมเลย (lobby / ยังไม่เลือกฝั่ง)
			if (my.teamName or my.teamAttr) and not tn and not ta then
				return S.Detect.Teamless == true
			end
			return S.Detect.Mode ~= "Strict"
		end

		-- rigs / bots
		if not S.Detect.Bots then return false end
		local bt = norm(model:GetAttribute("Team")) or norm(model:GetAttribute("TeamName")) or norm(model:GetAttribute("Faction"))
		if bt then
			if my.teamName then return my.teamName ~= bt end
			if my.teamAttr then return my.teamAttr ~= bt end
			if my.faction then return my.faction ~= bt end
		end
		local mf, bf = my.faction, identity(model)
		if mf and bf then return mf ~= bf end
		return S.Detect.Mode ~= "Strict"
	end

	-- =====================================================================
	-- HEALTH RESOLVER
	-- =====================================================================
	local function healthOf(model, info)
		local dead = model:GetAttribute("Dead") == true or model:GetAttribute("Alive") == false
		local a, m = model:GetAttribute("Health"), model:GetAttribute("MaxHealth") or model:GetAttribute("MaxHP")

		local hum = (info and info.hum and info.hum.Parent == model and info.hum) or model:FindFirstChildOfClass("Humanoid")
		if hum then
			if info then info.hum = hum end
			if hum.Health <= 0 or dead then return 0, math.max(hum.MaxHealth, 1) end
			if a ~= nil and tonumber(a) then
				return tonumber(a), tonumber(m) or math.max(hum.MaxHealth, 1)
			end
			return hum.Health, math.max(hum.MaxHealth, 1)
		end
		if a ~= nil and tonumber(a) then
			return tonumber(a), tonumber(m) or 100
		end
		if dead then return 0, 1 end
		return nil, nil -- rig without health: chams only, no bar
	end

	-- =====================================================================
	-- REGISTRY  (refresh 4Hz, never per frame)
	-- =====================================================================
	local Reg = {}

	-- โครงกระดูก: ลำดับชื่อ R15/R6 ก่อน -> AnimationConstraint -> Motor6D -> root/head
	local LINKS = {
		{ "HumanoidRootPart", "LowerTorso" },
		{ "LowerTorso", "UpperTorso" },
		{ "UpperTorso", "Head" },
		{ "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" },
		{ "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
		{ "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" },
		{ "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" },
		{ "Torso", "Head" }, { "Torso", "Left Arm" }, { "Torso", "Right Arm" },
		{ "Torso", "Left Leg" }, { "Torso", "Right Leg" },
	}

	local function buildBones(model)
		local bones = {}

		for _, link in ipairs(LINKS) do
			local a, b = model:FindFirstChild(link[1]), model:FindFirstChild(link[2])
			if a and b and a:IsA("BasePart") and b:IsA("BasePart") then
				bones[#bones + 1] = { a = a, b = b }
			end
		end
		if #bones > 0 then return bones end

		-- rig ใหม่ (AnimationConstraint + Attachment)
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("AnimationConstraint") then
				local a0 = d.Attachment0 and d.Attachment0.Parent
				local a1 = d.Attachment1 and d.Attachment1.Parent
				if a0 and a1 and a0:IsA("BasePart") and a1:IsA("BasePart") then
					bones[#bones + 1] = { a = a0, b = a1 }
					if #bones >= 20 then return bones end
				end
			end
		end
		if #bones > 0 then return bones end

		-- rig เก่า (Motor6D)
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("Motor6D") and d.Part0 and d.Part1 then
				bones[#bones + 1] = { a = d.Part0, b = d.Part1 }
				if #bones >= 16 then return bones end
			end
		end
		if #bones > 0 then return bones end

		local root, head = model:FindFirstChild("HumanoidRootPart"), model:FindFirstChild("Head")
		if root and head then bones[1] = { a = root, b = head } end
		return bones
	end

	local SOURCES = { "Characters", "BotRigs", "Bots", "Units", "Rigs", "Enemies", "NPCs", "Mobs" }

	local function refresh()
		refreshMy()
		local alive = {}

		local function consider(model, plr)
			if not model or alive[model] then return end
			alive[model] = true
			if not looksLikeCharacter(model) then return end

			local info = Reg[model]
			if not info then
				info = { model = model }
				Reg[model] = info
			end
			info.plr    = plr or Players:GetPlayerFromCharacter(model)
			info.enemy  = relation(model, info.plr)
			info.root   = model:FindFirstChild("HumanoidRootPart")
				or model:FindFirstChild("Head")
				or model:FindFirstChild("UpperTorso")
				or model.PrimaryPart
			info.head   = model:FindFirstChild("Head")
			info.hum    = model:FindFirstChildOfClass("Humanoid")

			-- bones refresh ~1Hz (4 refreshes)
			info.age = (info.age or 0) + 1
			if info.bones == nil or info.age % 4 == 0 then
				info.bones = buildBones(model)
			end
		end

		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP and p.Character then consider(p.Character, p) end
		end

		for _, fname in ipairs(SOURCES) do
			local f = WS:FindFirstChild(fname)
			if f then
				for _, m in ipairs(f:GetChildren()) do
					if m:IsA("Model") then
						consider(m)
					elseif m:IsA("Folder") then
						for _, mm in ipairs(m:GetChildren()) do
							if mm:IsA("Model") then consider(mm) end
						end
					end
				end
			end
		end

		if S.Detect.WorkspaceScan then
			for _, m in ipairs(WS:GetChildren()) do
				if m:IsA("Model") then consider(m) end
			end
		end

		for model in pairs(Reg) do
			if not alive[model] or not model.Parent then Reg[model] = nil end
		end
	end

	-- =====================================================================
	-- HIGHLIGHT POOL  (fixed size, lives in Lighting - never in Workspace)
	-- =====================================================================
	local Pool = {}

	local function styleOne(hl)
		hl.FillColor          = S.Chams.Color
		hl.OutlineColor       = S.Chams.Color
		hl.FillTransparency   = S.Chams.Fill
		hl.OutlineTransparency= S.Chams.Outline
		hl.DepthMode          = (S.Chams.Depth == "XRay")
			and Enum.HighlightDepthMode.AlwaysOnTop
			or  Enum.HighlightDepthMode.Occluded
	end

	local function ensurePool(n)
		for i = #Pool + 1, n do
			local hl = Instance.new("Highlight")
			hl.Name       = rid(9)
			hl.Archivable = false
			hl.Enabled    = false
			styleOne(hl)
			hl.Parent     = Lighting
			Pool[i]       = hl
		end
		for i = n + 1, #Pool do
			Pool[i].Enabled = false
			Pool[i].Adornee = nil
		end
	end

	local function applyStyle()
		for _, hl in ipairs(Pool) do styleOne(hl) end
	end

	-- =====================================================================
	-- DRAWING BAR POOL
	-- =====================================================================
	local canDraw = false
	do
		local ok = pcall(function()
			local d = Drawing.new("Square")
			d.Visible = false
			d:Remove()
		end)
		canDraw = ok
	end

	local MAX_BARS = 120
	local Bars = {}

	local function getBar(i)
		local b = Bars[i]
		if b then return b end
		if not canDraw then return nil end

		local ok, res = pcall(function()
			local bg = Drawing.new("Square")
			bg.Thickness = 1
			bg.Filled    = true
			bg.Color     = Color3.fromRGB(8, 8, 12)
			bg.Visible   = false

			local fill = Drawing.new("Square")
			fill.Thickness = 1
			fill.Filled    = true
			fill.Visible   = false

			local txt = Drawing.new("Text")
			txt.Center  = true
			txt.Outline = true
			txt.Font    = 2
			txt.Size    = 13
			txt.Visible = false
			pcall(function() txt.OutlineColor = Color3.fromRGB(0, 0, 0) end)

			return { bg = bg, fill = fill, txt = txt, lastText = "", lastT = 0 }
		end)

		if not ok or type(res) ~= "table" then
			canDraw = false
			return nil
		end
		Bars[i] = res
		return res
	end

	local function hpColor(p)
		if p > 0.60 then return Color3.fromRGB(60, 220, 90)
		elseif p > 0.30 then return Color3.fromRGB(245, 190, 40)
		else return Color3.fromRGB(255, 45, 60) end
	end

	-- =====================================================================
	-- SKELETON ESP  (Drawing.Line เท่านั้น - ไม่มี Instance ใน DataModel)
	-- =====================================================================
	local MAX_LINES   = 220
	local Lines       = {}
	local lineApi     = nil
	local linesDrawn  = 0

	local function getLine(i)
		local l = Lines[i]
		if l then return l end
		local ok, obj = pcall(function()
			local d = Drawing.new("Line")
			d.Thickness = S.Skeleton.Thickness
			d.Visible   = false
			return d
		end)
		if not ok or not obj then return nil end

		if not lineApi then
			if pcall(function() obj.From = Vector2.new(0, 0); obj.To = Vector2.new(0, 0) end) then
				lineApi = "ft"
			elseif pcall(function() obj.PointA = Vector2.new(0, 0); obj.PointB = Vector2.new(0, 0) end) then
				lineApi = "pt"
			else
				pcall(function() obj:Remove() end)
				return nil
			end
		end

		Lines[i] = obj
		return obj
	end

	local function setLine(l, a, b)
		if lineApi == "ft" then
			l.From = a
			l.To   = b
		else
			l.PointA = a
			l.PointB = b
		end
	end

	-- =====================================================================
	-- RECOIL
	-- =====================================================================
	local firing = false
	local recoilAcc = 0
	local moveRel = (type(mousemoverel) == "function") and mousemoverel or nil

	local function applyRecoil(cam, dt)
		if not (S.Recoil.Enabled and firing) then
			recoilAcc = 0
			return
		end
		local rate = S.Recoil.Strength * 60 / math.max(1, S.Recoil.Smooth)
		recoilAcc = recoilAcc + rate * dt
		local steps = math.floor(recoilAcc)
		if steps <= 0 then return end
		recoilAcc = recoilAcc - steps
		if moveRel then
			pcall(moveRel, 0, steps)
		else
			cam.CFrame = cam.CFrame * CFrame.Angles(-steps * 0.0016, 0, 0)
		end
	end

	-- =====================================================================
	-- RENDER
	-- =====================================================================
	local bindName = "vx_" .. rid(7)
	local running  = true
	local conns    = {}
	local barsDrawn = 0

	local function track(c)
		conns[#conns + 1] = c
		return c
	end

	-- performance meter + humanizer + panic state
	local perf = { fps = 60, acc = 0, frames = 0, scale = 1 }
	local hum  = { next = 0, untilT = 0 }
	local panicCleared = false

	local function hideAll()
		for _, hl in ipairs(Pool) do hl.Enabled = false end
		for i = 1, #Lines do Lines[i].Visible = false end
		for i = 1, #Bars do
			local b = Bars[i]
			b.bg.Visible = false
			b.fill.Visible = false
			b.txt.Visible = false
		end
		linesDrawn = 0
		barsDrawn  = 0
	end

	local function onRender(dt)
		local cam = WS.CurrentCamera
		if not cam then return end

		-- ---- panic kill-switch -----------------------------------------
		if S.Panic then
			if not panicCleared then
				hideAll()
				panicCleared = true
			end
			return
		end
		panicCleared = false

		-- ---- fps meter + adaptive budget -------------------------------
		perf.acc = perf.acc + dt
		perf.frames = perf.frames + 1
		if perf.acc >= 1 then
			perf.fps = perf.frames / perf.acc
			perf.acc, perf.frames = 0, 0
			if perf.fps < 45 then
				perf.scale = math.max(0.35, perf.scale - 0.2)
			elseif perf.fps > 55 then
				perf.scale = math.min(1, perf.scale + 0.1)
			end
		end

		-- ---- humanizer (กะพริบ chams เป็นช่วง ๆ) ----------------------
		local nowT = now()
		if S.Human.Enabled then
			if nowT >= hum.next then
				hum.untilT = nowT + S.Human.MinHold + math.random() * (S.Human.MaxHold - S.Human.MinHold)
				hum.next   = nowT + S.Human.MinGap + math.random() * (S.Human.MaxGap - S.Human.MinGap)
			end
		else
			hum.untilT = 0
		end
		local blink = nowT < hum.untilT

		-- pool size follows the slider
		local want = math.clamp(math.floor(S.Chams.MaxCount), 1, 64)
		if #Pool ~= want then ensurePool(want) end

		applyRecoil(cam, dt)

		local camPos = cam.CFrame.Position
		local look   = cam.CFrame.LookVector
		local maxD   = math.max(S.Chams.MaxDist, S.Bars.MaxDist)
		local list   = {}

		for model, info in pairs(Reg) do
			if info.enemy and info.root and info.root.Parent then
				local rel = info.root.Position - camPos
				local d = rel.Magnitude
				if d <= maxD then
					local hp, maxhp = healthOf(model, info)
					if hp ~= 0 then
						list[#list + 1] = {
							info = info, model = model, root = info.root, d = d,
							hp = hp or 100, maxhp = maxhp or 100,
							front = rel:Dot(look) > 0,
						}
					end
				end
			end
		end

		if #list > 1 then
			table.sort(list, function(a, b) return a.d < b.d end)
		end

		-- ---- chams (adaptive budget + blink) ---------------------------
		local budget = math.max(1, math.floor(S.Chams.MaxCount * perf.scale))
		local chamCount = 0
		if S.Chams.Enabled and not blink then
			chamCount = math.min(#list, S.Chams.MaxCount, budget)
		end
		for i = 1, #Pool do
			local hl = Pool[i]
			local model = (i <= chamCount) and list[i].model or nil
			if hl.Adornee ~= model then hl.Adornee = model end
			local vis = model ~= nil
			if hl.Enabled ~= vis then hl.Enabled = vis end
		end

		-- ---- bars ------------------------------------------------------
		local used = 0
		if S.Bars.Enabled and canDraw and #list > 0 then
			local t0 = now()
			for i = 1, #list do
				local t = list[i]
				if t.d > S.Bars.MaxDist or used >= MAX_BARS then break end

				if t.front then
					local anchor = t.info.head or t.root
					local off = (anchor == t.info.head) and 1.1 or 2.6
					local sp, onScreen = cam:WorldToViewportPoint(anchor.Position + Vector3.new(0, off, 0))

					if onScreen and sp.Z > 0.5 then
						used = used + 1
						local b = getBar(used)
						if b then
	-- pct / bar text uses hp+maxhp guaranteed by the list defaults
							local pct = math.clamp(t.hp / t.maxhp, 0, 1)
							local col = hpColor(pct)
							local w = math.clamp(1500 / sp.Z, 30, 78)
							local h = 4
							local x = sp.X - w * 0.5
							local y = sp.Y

							b.bg.Size     = Vector2.new(w + 2, h + 2)
							b.bg.Position = Vector2.new(x - 1, y - 1)
							b.bg.Visible  = true

							b.fill.Size     = Vector2.new(math.max(w * pct, 1), h)
							b.fill.Position = Vector2.new(x, y)
							b.fill.Color    = col
							b.fill.Visible  = true

							local showText = S.Bars.ShowName or S.Bars.ShowHP or S.Bars.ShowDist
							if showText then
								if t0 - b.lastT > 0.10 then
									b.lastT = t0
									local parts = {}
									if S.Bars.ShowName then parts[#parts + 1] = t.model.Name end
									if S.Bars.ShowHP then
										parts[#parts + 1] = string.format("%d", math.floor(t.hp))
									end
									if S.Bars.ShowDist then
										parts[#parts + 1] = string.format("%dm", math.floor(t.d))
									end
									local s = table.concat(parts, "  ")
									if s ~= b.lastText then
										b.lastText = s
										b.txt.Text = s
									end
								end
								b.txt.Position = Vector2.new(sp.X, y - 17)
								b.txt.Color    = col
								b.txt.Visible  = true
							else
								b.txt.Visible = false
							end
						end
					end
				end
			end
		end

		for i = used + 1, barsDrawn do
			local b = Bars[i]
			if b then
				b.bg.Visible = false
				b.fill.Visible = false
				b.txt.Visible = false
			end
		end
		barsDrawn = used

		-- ---- skeleton (Drawing เท่านั้น) -------------------------------
		local lineN = 0
		if S.Skeleton.Enabled and canDraw and #list > 0 then
			local cap = math.min(#list, math.floor(S.Skeleton.MaxCount),
				math.max(1, math.floor(S.Skeleton.MaxCount * perf.scale)))
			for i = 1, cap do
				local t = list[i]
				if t.d > S.Skeleton.MaxDist then break end
				if t.front and t.info.bones then
					for _, bone in ipairs(t.info.bones) do
						local pa0, pb0 = bone.a, bone.b
						if pa0.Parent and pb0.Parent then
							local pa, oa = cam:WorldToViewportPoint(pa0.Position)
							local pb, ob = cam:WorldToViewportPoint(pb0.Position)
							if oa and ob then
								lineN = lineN + 1
								if lineN > MAX_LINES then break end
								local l = getLine(lineN)
								if l then
									setLine(l, Vector2.new(pa.X, pa.Y), Vector2.new(pb.X, pb.Y))
									l.Color   = S.Chams.Color
									l.Thickness = S.Skeleton.Thickness
									l.Visible = true
								end
							end
						end
					end
				end
				if lineN >= MAX_LINES then break end
			end
		end

		for i = lineN + 1, linesDrawn do
			local l = Lines[i]
			if l then l.Visible = false end
		end
		linesDrawn = lineN

		-- debug state (อ่านได้จากภายนอก ไม่มีผลต่อการทำงาน)
		local dbg = genv.__vx_dbg
		if not dbg then
			dbg = {}
			genv.__vx_dbg = dbg
		end
		dbg.enemies = #list
		dbg.chams   = chamCount
		dbg.bars    = used
		dbg.lines   = lineN
		dbg.fps     = perf.fps
		dbg.scale   = perf.scale
		dbg.blink   = blink
	end

	-- =====================================================================
	-- FPS MODE
	-- =====================================================================
	local fpsSaved = nil

	local function setFps(on)
		if on then
			if fpsSaved then return end
			fpsSaved = {
				shadows = Lighting.GlobalShadows,
				fogEnd  = Lighting.FogEnd,
				effects = {},
				emitters= {},
			}
			Lighting.GlobalShadows = false
			Lighting.FogEnd = 1e6
			for _, v in ipairs(Lighting:GetChildren()) do
				if v:IsA("PostEffect") and v.Enabled then
					fpsSaved.effects[#fpsSaved.effects + 1] = v
					v.Enabled = false
				end
			end
			task.spawn(function()
				local n = 0
				for _, d in ipairs(WS:GetDescendants()) do
					if not running then break end
					if d:IsA("ParticleEmitter") or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles") then
						if d.Enabled then
							fpsSaved.emitters[#fpsSaved.emitters + 1] = d
							d.Enabled = false
						end
					end
					n = n + 1
					if n % 600 == 0 then task.wait() end
				end
			end)
		else
			if not fpsSaved then return end
			Lighting.GlobalShadows = fpsSaved.shadows
			Lighting.FogEnd = fpsSaved.fogEnd
			for _, v in ipairs(fpsSaved.effects) do pcall(function() v.Enabled = true end) end
			for _, v in ipairs(fpsSaved.emitters) do pcall(function() v.Enabled = true end) end
			fpsSaved = nil
		end
		S.Fps.Enabled = on
	end

	-- =====================================================================
	-- LIFECYCLE
	-- =====================================================================
	local function destroy()
		if not running then return end
		running = false
		pcall(function() RS:UnbindFromRenderStep(bindName) end)
		for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
		conns = {}
		for _, hl in ipairs(Pool) do pcall(function() hl:Destroy() end) end
		Pool = {}
		for _, b in ipairs(Bars) do
			pcall(function()
				b.bg:Remove()
				b.fill:Remove()
				b.txt:Remove()
			end)
		end
		Bars = {}
		for _, l in ipairs(Lines) do pcall(function() l:Remove() end) end
		Lines = {}
		setFps(false)
		if type(genv.__vx) == "table" and genv.__vx.destroy == destroy then
			genv.__vx = nil
		end
		genv.__vx_dbg = nil
	end

	-- =====================================================================
	-- PANIC + PROFILES
	-- =====================================================================
	local function setPanic(on)
		S.Panic = (on == true)
		local gui = genv.__vx_gui
		if gui then pcall(function() gui.Enabled = not S.Panic end) end
		if S.Panic then hideAll() end
	end

	local syncHook = nil

	local function applyProfile(name)
		local p = PROFILES[name]
		if not p then return end
		S.Profile = name
		for group, values in pairs(p) do
			local target = S[group]
			if target then
				for k, v in pairs(values) do target[k] = v end
			end
		end
		applyStyle()
		if #Pool ~= math.clamp(math.floor(S.Chams.MaxCount), 1, 64) then
			ensurePool(math.clamp(math.floor(S.Chams.MaxCount), 1, 64))
		end
		if syncHook then pcall(syncHook) end
	end

	track(UIS.InputBegan:Connect(function(input, processed)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and not processed then
			firing = true
		end
		if not processed and input.KeyCode and input.KeyCode.Name == S.Keys.Panic then
			setPanic(not S.Panic)
		end
	end))
	track(UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			firing = false
		end
	end))
	track(Players.PlayerAdded:Connect(function() task.delay(0.5, refresh) end))
	track(Players.PlayerRemoving:Connect(function(p)
		if p.Character then Reg[p.Character] = nil end
	end))

	applyProfile(PRESET_BY_PLACE[game.PlaceId] or S.Profile)
	refresh()
	ensurePool(math.clamp(math.floor(S.Chams.MaxCount), 1, 64))
	RS:BindToRenderStep(bindName, Enum.RenderPriority.Camera.Value + 1, onRender)

	task.spawn(function()
		while running do
			pcall(refresh)
			task.wait(0.25)
		end
	end)

	genv.__vx = { version = 8, destroy = destroy }
	genv.__vx_api = {
		panic   = setPanic,
		profile = applyProfile,
		refresh = refresh,
		destroy = destroy,
	}

	return {
		Settings   = S,
		Refresh    = refresh,
		ApplyStyle = applyStyle,
		SetFps     = setFps,
		Destroy    = destroy,
		CanDraw    = canDraw,
		ApplyProfile = applyProfile,
		SetPanic     = setPanic,
		SetSync      = function(fn) syncHook = fn end,
		Fps        = function() return perf.fps end,
		Scale      = function() return perf.scale end,
		Stats = function()
			local n, e = 0, 0
			for _, info in pairs(Reg) do
				n = n + 1
				if info.enemy then e = e + 1 end
			end
			return n, e
		end,
	}
end)()

-- =====================================================================
-- UI LIBRARY : Linoria (embedded, patched for CoreGui protect + unload)
-- =====================================================================
local Library = (function()
local InputService = game:GetService('UserInputService');
local TextService = game:GetService('TextService');
local TweenService = game:GetService('TweenService');
local CoreGui = game:GetService('CoreGui');
local RenderStepped = game:GetService('RunService').RenderStepped;
local LocalPlayer = game:GetService('Players').LocalPlayer;
local Mouse = LocalPlayer:GetMouse();

local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end);

local ScreenGui = Instance.new('ScreenGui');
do
    local _a = 'abcdefghijklmnopqrstuvwxyz';
    local _n = '';
    for _ = 1, 7 do
        local _i = math.random(1, #_a);
        _n = _n .. _a:sub(_i, _i);
    end;
    ScreenGui.Name = _n;
end;
ScreenGui.ResetOnSpawn = false;
ScreenGui.IgnoreGuiInset = true;
ProtectGui(ScreenGui);

ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
do
    local _t = (gethui and gethui()) or (get_hidden_gui and get_hidden_gui()) or CoreGui;
    local _ok = pcall(function() ScreenGui.Parent = _t end);
    if (not _ok) or (not ScreenGui.Parent) then
        pcall(function() ScreenGui.Parent = LocalPlayer:WaitForChild('PlayerGui', 10) end);
    end;
end;

local Toggles = {};
local Options = {};

getgenv().Toggles = Toggles;
getgenv().Options = Options;

local Library = {
    Registry = {};
    RegistryMap = {};

    HudRegistry = {};

    FontColor = Color3.fromRGB(255, 255, 255);
    MainColor = Color3.fromRGB(28, 28, 28);
    BackgroundColor = Color3.fromRGB(20, 20, 20);
    AccentColor = Color3.fromRGB(0, 85, 255);
    OutlineColor = Color3.fromRGB(50, 50, 50);

    Black = Color3.new(0, 0, 0);

    OpenedFrames = {};
};

task.spawn(function()
    local Tick = tick();
    local Hue = 0;

    while RenderStepped:Wait() do
        if Library.Unloaded or (not ScreenGui.Parent) then break end;
        if tick() - Tick >= (1 / 60) then
            Hue = Hue + (1 / 400);

            if Hue > 1 then
                Hue = 0;
            end;

            Library.CurrentRainbowHue = Hue;
            Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1);

            Tick = tick();
        end;
    end;
end);

function Library:AttemptSave()
    if Library.SaveManager then
        Library.SaveManager:Save();
    end;
end;

function Library:Create(Class, Properties)
    local _Instance = Class;

    if type(Class) == 'string' then
        _Instance = Instance.new(Class);
    end;

    for Property, Value in next, Properties do
        _Instance[Property] = Value;
    end;

    if Library.FontFace and (
        _Instance:IsA('TextLabel') or _Instance:IsA('TextButton') or _Instance:IsA('TextBox')
    ) then
        pcall(function() _Instance.FontFace = Library.FontFace end);
    end;

    return _Instance;
end;

function Library:CreateLabel(Properties, IsHud)
    local _Instance = Library:Create('TextLabel', {
        BackgroundTransparency = 1;
        Font = Enum.Font.Code;
        TextColor3 = Library.FontColor;
        TextSize = 16;
        TextStrokeTransparency = 0;
    });

    Library:AddToRegistry(_Instance, {
        TextColor3 = 'FontColor';
    }, IsHud);

    return Library:Create(_Instance, Properties);
end;

function Library:MakeDraggable(Instance, Cutoff)
    Instance.Active = true;

    Instance.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            local ObjPos = Vector2.new(
                Mouse.X - Instance.AbsolutePosition.X,
                Mouse.Y - Instance.AbsolutePosition.Y
            );

            if ObjPos.Y > (Cutoff or 40) then
                return;
            end;

            while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                Instance.Position = UDim2.new(
                    0,
                    Mouse.X - ObjPos.X + (Instance.Size.X.Offset * Instance.AnchorPoint.X),
                    0,
                    Mouse.Y - ObjPos.Y + (Instance.Size.Y.Offset * Instance.AnchorPoint.Y)
                );

                RenderStepped:Wait();
            end;
        end;
    end);
end;

function Library:OnHighlight(HighlightInstance, Instance, Properties, PropertiesDefault)
    HighlightInstance.MouseEnter:Connect(function()
        local Reg = Library.RegistryMap[Instance];

        for Property, ColorIdx in next, Properties do
            Instance[Property] = Library[ColorIdx] or ColorIdx;

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx;
            end;
        end;
    end);

    HighlightInstance.MouseLeave:Connect(function()
        local Reg = Library.RegistryMap[Instance];

        for Property, ColorIdx in next, PropertiesDefault do
            Instance[Property] = Library[ColorIdx] or ColorIdx;

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx;
            end;
        end;
    end);
end;

function Library:MouseIsOverOpenedFrame()
    for Frame, _ in next, Library.OpenedFrames do
        local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;

        if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
            and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then

            return true;
        end;
    end;
end;

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
    return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB;
end;

function Library:GetTextBounds(Text, Font, Size)
    return TextService:GetTextSize(Text, Size, Font, Vector2.new(1920, 1080)).X;
end;

function Library:GetDarkerColor(Color)
    local H, S, V = Color3.toHSV(Color);
    return Color3.fromHSV(H, S, V / 1.5);
end; Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor);

function Library:AddToRegistry(Instance, Properties, IsHud)
    local Idx = #Library.Registry + 1;
    local Data = {
        Instance = Instance;
        Properties = Properties;
        Idx = Idx;
    };

    table.insert(Library.Registry, Data);
    Library.RegistryMap[Instance] = Data;

    if IsHud then
        table.insert(Library.HudRegistry, Data);
    end;
end;

function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance];

    if Data then
        for Idx = #Library.Registry, 1, -1 do
            if Library.Registry[Idx] == Data then
                table.remove(Library.Registry, Idx);
            end;
        end;

        for Idx = #Library.HudRegistry, 1, -1 do
            if Library.HudRegistry[Idx] == Data then
                table.remove(Library.HudRegistry, Idx);
            end;
        end;

        Library.RegistryMap[Instance] = nil;
    end;
end;

ScreenGui.DescendantRemoving:Connect(function(Instance)
    if Library.RegistryMap[Instance] then
        Library:RemoveFromRegistry(Instance);
    end;
end);

function Library:UpdateColorsUsingRegistry()
    -- TODO: Could have an 'active' list of objects
    -- where the active list only contains Visible objects.

    -- IMPL: Could setup .Changed events on the AddToRegistry function
    -- that listens for the 'Visible' propert being changed.
    -- Visible: true => Add to active list, and call UpdateColors function
    -- Visible: false => Remove from active list.

    -- The above would be especially efficient for a rainbow menu color or live color-changing.

    for Idx, Object in next, Library.Registry do
        for Property, ColorIdx in next, Object.Properties do
            Object.Instance[Property] = Library[ColorIdx];
        end;
    end;
end;

local BaseAddons = {};

do
    local Funcs = {};

    function Funcs:AddColorPicker(Idx, Info)
        local ToggleLabel = self.TextLabel;
        local Container = self.Container;

        local ColorPicker = {
            Value = Info.Default;
            Type = 'ColorPicker';
        };

        function ColorPicker:SetHSVFromRGB(Color)
            local H, S, V = Color3.toHSV(Color);

            ColorPicker.Hue = H;
            ColorPicker.Sat = S;
            ColorPicker.Vib = V;
        end;

        ColorPicker:SetHSVFromRGB(ColorPicker.Value);

        local DisplayFrame = Library:Create('Frame', {
            BackgroundColor3 = ColorPicker.Value;
            BorderColor3 = Library:GetDarkerColor(ColorPicker.Value);
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(0, 28, 0, 14);
            ZIndex = 6;
            Parent = ToggleLabel;
        });

        local RelativeOffset = 0;

        for _, Element in next, Container:GetChildren() do
            if not Element:IsA('UIListLayout') then
                RelativeOffset = RelativeOffset + Element.Size.Y.Offset;
            end;
        end;

        local PickerFrameOuter = Library:Create('Frame', {
            Name = 'Color';
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 4, 0, 20 + RelativeOffset + 1);
            Size = UDim2.new(1, -4, 0, 234);
            Visible = false;
            ZIndex = 15;
            Parent = Container.Parent;
        });

        local PickerFrameInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 16;
            Parent = PickerFrameOuter;
        });

        Library:AddToRegistry(PickerFrameInner, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });

        local Highlight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 0, 2);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        Library:AddToRegistry(Highlight, {
            BackgroundColor3 = 'AccentColor';
        });

        local SatVibMapOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 4, 0, 6);
            Size = UDim2.new(0, 200, 0, 200);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local SatVibMapInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = SatVibMapOuter;
        });

        Library:AddToRegistry(SatVibMapInner, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });

        local SatVibMap = Library:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Image = 'rbxassetid://4155801252';
            Parent = SatVibMapInner;
        });

        local HueSelectorOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 211, 0, 7);
            Size = UDim2.new(0, 15, 0, 198);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local HueSelectorInner = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = HueSelectorOuter;
        });

        local HueTextSize = Library:GetTextBounds('Hex color', Enum.Font.Code, 16) + 3
        local RgbTextSize = Library:GetTextBounds('255, 255, 255', Enum.Font.Code, 16) + 3

        local HueBoxOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(4, 209),
            Size = UDim2.new(0.5, -6, 0, 20),
            ZIndex = 18,
            Parent = PickerFrameInner;
        });

        local HueBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18,
            Parent = HueBoxOuter;
        });

        Library:AddToRegistry(HueBoxInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = HueBoxInner;
        });

        local HueBox = Library:Create('TextBox', {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);
            Font = Enum.Font.Code;
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
            PlaceholderText = 'Hex color',
            Text = '#FFFFFF',
            TextColor3 = Library.FontColor;
            TextSize = 14;
            TextStrokeTransparency = 0;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 20,
            Parent = HueBoxInner;
        });

        local RgbBoxBase = Library:Create(HueBoxOuter:Clone(), {
            Position = UDim2.new(0.5, 2, 0, 209),
            Size = UDim2.new(0.5, -6, 0, 20),
            Parent = PickerFrameInner
        })  

        Library:AddToRegistry(RgbBoxBase.Frame, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local RgbBox = Library:Create(RgbBoxBase.Frame:FindFirstChild('TextBox'), {
            Text = '255, 255, 255',
            PlaceholderText = 'RGB color',
        })

        local SequenceTable = {};

        for Hue = 0, 1, 0.1 do
            table.insert(SequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)));
        end;

        local HueSelectorGradient = Library:Create('UIGradient', {
            Color = ColorSequence.new(SequenceTable);
            Rotation = 90;
            Parent = HueSelectorInner;
        });

        HueBox.FocusLost:Connect(function(enter)
            if enter then
                local success, result = pcall(Color3.fromHex, HueBox.Text)
                if success and typeof(result) == 'Color3' then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(result)
                end
            end

            ColorPicker:Display()
        end)

        RgbBox.FocusLost:Connect(function(enter)
            if enter then
                local r, g, b = RgbBox.Text:match('(%d+),%s*(%d+),%s*(%d+)')
                if r and g and b then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(Color3.fromRGB(r, g, b))
                end
            end

            ColorPicker:Display()
        end)

        function ColorPicker:Display()
            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib);
            SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1);

            Library:Create(DisplayFrame, {
                BackgroundColor3 = ColorPicker.Value;
                BorderColor3 = Library:GetDarkerColor(ColorPicker.Value);
            });

            HueBox.Text = '#' .. ColorPicker.Value:ToHex()
            RgbBox.Text = table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ', ')

            if ColorPicker.Changed then
                ColorPicker.Changed();
            end;
        end;

        function ColorPicker:OnChanged(Func)
            ColorPicker.Changed = Func;
            Func();
        end;

        function ColorPicker:Show()
            for Frame, Val in next, Library.OpenedFrames do
                if Frame.Name == 'Color' then
                    Frame.Visible = false;
                    Library.OpenedFrames[Frame] = nil;
                end;
            end;

            PickerFrameOuter.Visible = true;
            Library.OpenedFrames[PickerFrameOuter] = true;
        end;

        function ColorPicker:Hide()
            PickerFrameOuter.Visible = false;
            Library.OpenedFrames[PickerFrameOuter] = nil;
        end;

        function ColorPicker:SetValue(HSV)
            local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3]);

            ColorPicker:SetHSVFromRGB(Color);
            ColorPicker:Display();
        end;

        function ColorPicker:SetValueRGB(Color)
            ColorPicker:SetHSVFromRGB(Color);
            ColorPicker:Display();
        end;

        SatVibMap.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local MinX = SatVibMap.AbsolutePosition.X;
                    local MaxX = MinX + SatVibMap.AbsoluteSize.X;
                    local MouseX = math.clamp(Mouse.X, MinX, MaxX);

                    local MinY = SatVibMap.AbsolutePosition.Y;
                    local MaxY = MinY + SatVibMap.AbsoluteSize.Y;
                    local MouseY = math.clamp(Mouse.Y, MinY, MaxY);

                    ColorPicker.Sat = (MouseX - MinX) / (MaxX - MinX);
                    ColorPicker.Vib = 1 - ((MouseY - MinY) / (MaxY - MinY));
                    ColorPicker:Display();

                    RenderStepped:Wait();
                end;

                Library:AttemptSave();
            end;
        end);

        HueSelectorInner.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local MinY = HueSelectorInner.AbsolutePosition.Y;
                    local MaxY = MinY + HueSelectorInner.AbsoluteSize.Y;
                    local MouseY = math.clamp(Mouse.Y, MinY, MaxY);

                    ColorPicker.Hue = ((MouseY - MinY) / (MaxY - MinY));
                    ColorPicker:Display();

                    RenderStepped:Wait();
                end;

                Library:AttemptSave();
            end;
        end);

        DisplayFrame.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                if PickerFrameOuter.Visible then
                    ColorPicker:Hide();
                else
                    ColorPicker:Show();
                end;
            end;
        end);

        InputService.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local AbsPos, AbsSize = PickerFrameOuter.AbsolutePosition, PickerFrameOuter.AbsoluteSize;

                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

                    ColorPicker:Hide();
                end;
            end;
        end);

        ColorPicker:Display();

        Options[Idx] = ColorPicker;

        return self;
    end;

    function Funcs:AddKeyPicker(Idx, Info)
        local ToggleLabel = self.TextLabel;
        local Container = self.Container;

        local KeyPicker = {
            Value = Info.Default;
            Toggled = false;
            Mode = Info.Mode or 'Toggle'; -- Always, Toggle, Hold
            Type = 'KeyPicker';
        };

        local RelativeOffset = 0;

        for _, Element in next, Container:GetChildren() do
            if not Element:IsA('UIListLayout') then
                RelativeOffset = RelativeOffset + Element.Size.Y.Offset;
            end;
        end;

        local PickOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 28, 0, 15);
            ZIndex = 6;
            Parent = ToggleLabel;
        });

        local PickInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 7;
            Parent = PickOuter;
        });

        Library:AddToRegistry(PickInner, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = 13;
            Text = Info.Default;
            TextWrapped = true;
            ZIndex = 8;
            Parent = PickInner;
        });

        local ModeSelectOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(1, 0, 0, RelativeOffset + 1);
            Size = UDim2.new(0, 60, 0, 45 + 2);
            Visible = false;
            ZIndex = 14;
            Parent = Container.Parent;
        });

        local ModeSelectInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 15;
            Parent = ModeSelectOuter;
        });

        Library:AddToRegistry(ModeSelectInner, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });

        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ModeSelectInner;
        });

        local ContainerLabel = Library:CreateLabel({
            TextXAlignment = Enum.TextXAlignment.Left;
            Size = UDim2.new(1, 0, 0, 18);
            TextSize = 13;
            Visible = false;
            ZIndex = 110;
            Parent = Library.KeybindContainer;
        },  true);

        local Modes = Info.Modes or { 'Always', 'Toggle', 'Hold' };
        local ModeButtons = {};

        for Idx, Mode in next, Modes do
            local ModeButton = {};

            local Label = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 15);
                TextSize = 13;
                Text = Mode;
                ZIndex = 16;
                Parent = ModeSelectInner;
            });

            function ModeButton:Select()
                for _, Button in next, ModeButtons do
                    Button:Deselect();
                end;

                KeyPicker.Mode = Mode;

                Label.TextColor3 = Library.AccentColor;
                Library.RegistryMap[Label].Properties.TextColor3 = 'AccentColor';

                ModeSelectOuter.Visible = false;
            end;

            function ModeButton:Deselect()
                KeyPicker.Mode = nil;

                Label.TextColor3 = Library.FontColor;
                Library.RegistryMap[Label].Properties.TextColor3 = 'FontColor';
            end;

            Label.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    ModeButton:Select();
                    Library:AttemptSave();
                end;
            end);

            if Mode == KeyPicker.Mode then
                ModeButton:Select();
            end;

            ModeButtons[Mode] = ModeButton;
        end;

        function KeyPicker:Update()
            if Info.NoUI then
                return;
            end;

            local State = KeyPicker:GetState();

            ContainerLabel.Text = string.format('[%s] %s (%s)', KeyPicker.Value, Info.Text, KeyPicker.Mode);
            ContainerLabel.Visible = true;
            ContainerLabel.TextColor3 = State and Library.AccentColor or Library.FontColor;

            Library.RegistryMap[ContainerLabel].Properties.TextColor3 = State and 'AccentColor' or 'FontColor';

            local YSize = 0;

            for _, Label in next, Library.KeybindContainer:GetChildren() do
                if not Label:IsA('UIListLayout') then
                    if Label.Visible then
                        YSize = YSize + 18;
                    end;
                end;
            end;

            Library.KeybindFrame.Size = UDim2.new(0, 210, 0, 20 + YSize);
        end;

        function KeyPicker:GetState()
            if KeyPicker.Mode == 'Always' then
                return true;
            elseif KeyPicker.Mode == 'Hold' then
                local Key = KeyPicker.Value;

                if Key == 'MB1' or Key == 'MB2' then
                    return Key == 'MB1' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                        or Key == 'MB2' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2);
                else
                    return InputService:IsKeyDown(Enum.KeyCode[KeyPicker.Value]);
                end;
            else
                return KeyPicker.Toggled;
            end;
        end;

        function KeyPicker:SetValue(Data)
            local Key, Mode = Data[1], Data[2];
            DisplayLabel.Text = Key;
            KeyPicker.Value = Key;
            ModeButtons[Mode]:Select();
            KeyPicker:Update();
        end;

        function KeyPicker:OnClick(Callback)
            KeyPicker.Clicked = Callback
        end

        function KeyPicker:DoClick()
            if KeyPicker.Clicked then
                KeyPicker.Clicked()
            end
        end

        local Picking = false;

        PickOuter.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                Picking = true;

                DisplayLabel.Text = '';

                local Break;
                local Text = '';

                task.spawn(function()
                    while (not Break) do
                        if Text == '...' then
                            Text = '';
                        end;

                        Text = Text .. '.';
                        DisplayLabel.Text = Text;

                        wait(0.4);
                    end;
                end);

                wait(0.2);

                local Event;
                Event = InputService.InputBegan:Connect(function(Input)
                    local Key;

                    if Input.UserInputType == Enum.UserInputType.Keyboard then
                        Key = Input.KeyCode.Name;
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Key = 'MB1';
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                        Key = 'MB2';
                    end;

                    Break = true;
                    Picking = false;

                    DisplayLabel.Text = Key;
                    KeyPicker.Value = Key;

                    Library:AttemptSave();

                    Event:Disconnect();
                end);
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                ModeSelectOuter.Visible = true;
            end;
        end);

        InputService.InputBegan:Connect(function(Input)
            if (not Picking) then
                if KeyPicker.Mode == 'Toggle' then
                    local Key = KeyPicker.Value;

                    if Key == 'MB1' or Key == 'MB2' then
                        if Key == 'MB1' and Input.UserInputType == Enum.UserInputType.MouseButton1
                        or Key == 'MB2' and Input.UserInputType == Enum.UserInputType.MouseButton2 then
                            KeyPicker.Toggled = not KeyPicker.Toggled
                            KeyPicker:DoClick()
                        end;
                    elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                        if Input.KeyCode.Name == Key then
                            KeyPicker.Toggled = not KeyPicker.Toggled;
                            KeyPicker:DoClick()
                        end;
                    end;
                end;

                KeyPicker:Update();
            end;

            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local AbsPos, AbsSize = ModeSelectOuter.AbsolutePosition, ModeSelectOuter.AbsoluteSize;

                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

                    ModeSelectOuter.Visible = false;
                end;
            end;
        end);

        InputService.InputEnded:Connect(function(Input)
            if (not Picking) then
                KeyPicker:Update();
            end;
        end);

        KeyPicker:Update();

        Options[Idx] = KeyPicker;

        return self;
    end;

    BaseAddons.__index = Funcs;
    BaseAddons.__namecall = function(Table, Key, ...)
        return Funcs[Key](...);
    end;
end;

local BaseGroupbox = {};

do
    local Funcs = {};

    function Funcs:AddBlank(Size)
        local Groupbox = self;
        local Container = Groupbox.Container;

        Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, Size);
            ZIndex = 1;
            Parent = Container;
        });
    end;

    function Funcs:AddLabel(Text)
        local Label = {};

        local Groupbox = self;
        local Container = Groupbox.Container;

        local TextLabel = Library:CreateLabel({
            Size = UDim2.new(1, -4, 0, 15);
            TextSize = 14;
            Text = Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = Container;
        });

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 4);
            FillDirection = Enum.FillDirection.Horizontal;
            HorizontalAlignment = Enum.HorizontalAlignment.Right;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = TextLabel;
        });

        Label.TextLabel = TextLabel;
        Label.Container = Container;
        setmetatable(Label, BaseAddons);

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        return Label;
    end;

    function Funcs:AddButton(Text, Func)
        local Button = {};

        local Groupbox = self;
        local Container = Groupbox.Container;

        local ButtonOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 20);
            ZIndex = 5;
            Parent = Container;
        });

        Library:AddToRegistry(ButtonOuter, {
            BorderColor3 = 'Black';
        });

        local ButtonInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = ButtonOuter;
        });

        Library:AddToRegistry(ButtonInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = ButtonInner;
        });

        local ButtonLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = 14;
            Text = Text;
            ZIndex = 6;
            Parent = ButtonInner;
        });

        Library:OnHighlight(ButtonOuter, ButtonOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );

        ButtonOuter.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                Func();
            end;
        end);

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        return Button;
    end;

    function Funcs:AddInput(Idx, Info)
        local Textbox = {
            Value = Info.Default or '';
            Type = 'Input';
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local InputLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 15);
            TextSize = 14;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = Container;
        });

        Groupbox:AddBlank(1);

        local TextBoxOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 20);
            ZIndex = 5;
            Parent = Container;
        });

        local TextBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = TextBoxOuter;
        });

        Library:AddToRegistry(TextBoxInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = TextBoxInner;
        });

        local Box = Library:Create('TextBox', {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);
            Font = Enum.Font.Code;
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
            PlaceholderText = Info.Placeholder or '';
            Text = Info.Default or '';
            TextColor3 = Library.FontColor;
            TextSize = 14;
            TextStrokeTransparency = 0;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 7;
            Parent = TextBoxInner;
        });

        function Textbox:SetValue(Text)
            if Info.MaxLength and #Text > Info.MaxLength then
                Text = Text:sub(1, Info.MaxLength);
            end;

            if Textbox.Changed then
                Textbox.Changed();
            end;

            Textbox.Value = Text;
            Box.Text = Text;
        end;

        Box:GetPropertyChangedSignal('Text'):Connect(function()
            Textbox:SetValue(Box.Text);
            Library:AttemptSave();
        end);

        Library:AddToRegistry(Box, {
            TextColor3 = 'FontColor';
        });

        function Textbox:OnChanged(Func)
            Textbox.Changed = Func;
            Func();
        end;

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        Options[Idx] = Textbox;

        return Textbox;
    end;

    function Funcs:AddToggle(Idx, Info)
        local Toggle = {
            Value = Info.Default or false;
            Type = 'Toggle';
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local ToggleOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 13, 0, 13);
            ZIndex = 5;
            Parent = Container;
        });

        Library:AddToRegistry(ToggleOuter, {
            BorderColor3 = 'Black';
        });

        local ToggleInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = ToggleOuter;
        });

        Library:AddToRegistry(ToggleInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local ToggleLabel = Library:CreateLabel({
            Size = UDim2.new(0, 216, 1, 0);
            Position = UDim2.new(1, 6, 0, 0);
            TextSize = 14;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 6;
            Parent = ToggleInner;
        });

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 4);
            FillDirection = Enum.FillDirection.Horizontal;
            HorizontalAlignment = Enum.HorizontalAlignment.Right;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ToggleLabel;
        });

        local ToggleRegion = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(0, 170, 1, 0);
            ZIndex = 8;
            Parent = ToggleOuter;
        });

        Library:OnHighlight(ToggleRegion, ToggleOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );

        function Toggle:UpdateColors()
            Toggle:Display();
        end;

        function Toggle:Display()
            ToggleInner.BackgroundColor3 = Toggle.Value and Library.AccentColor or Library.MainColor;
            ToggleInner.BorderColor3 = Toggle.Value and Library.AccentColorDark or Library.OutlineColor;

            Library.RegistryMap[ToggleInner].Properties.BackgroundColor3 = Toggle.Value and 'AccentColor' or 'MainColor';
            Library.RegistryMap[ToggleInner].Properties.BorderColor3 = Toggle.Value and 'AccentColorDark' or 'OutlineColor';
        end;

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func;
            Func();
        end;

        function Toggle:SetValue(Bool)
            Toggle.Value = Bool;
            Toggle:Display();

            if Toggle.Changed then
                Toggle.Changed();
            end;
        end;

        ToggleRegion.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                Toggle.Value = not Toggle.Value;
                Toggle:Display();

                if Toggle.Changed then
                    Toggle.Changed();
                end;

                Library:AttemptSave();
            end;
        end);

        Toggle:Display();
        Groupbox:AddBlank(Info.BlankSize or 5 + 2);
        Groupbox:Resize();

        Toggle.TextLabel = ToggleLabel;
        Toggle.Container = Container;
        setmetatable(Toggle, BaseAddons);

        Toggles[Idx] = Toggle;

        return Toggle;
    end;

    function Funcs:AddSlider(Idx, Info)
        assert(Info.Default and Info.Text and Info.Min and Info.Max and Info.Rounding, 'Bad Slider Data');

        local Slider = {
            Value = Info.Default;
            Min = Info.Min;
            Max = Info.Max;
            Rounding = Info.Rounding;
            MaxSize = 232;
            Type = 'Slider';
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        if not Info.Compact then
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10);
                TextSize = 14;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                ZIndex = 5;
                Parent = Container;
            });

            Groupbox:AddBlank(3);
        end

        local SliderOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 13);
            ZIndex = 5;
            Parent = Container;
        });

        Library:AddToRegistry(SliderOuter, {
            BorderColor3 = 'Black';
        });

        local SliderInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = SliderOuter;
        });

        Library:AddToRegistry(SliderInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local Fill = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderColor3 = Library.AccentColorDark;
            Size = UDim2.new(0, 0, 1, 0);
            ZIndex = 7;
            Parent = SliderInner;
        });

        Library:AddToRegistry(Fill, {
            BackgroundColor3 = 'AccentColor';
            BorderColor3 = 'AccentColorDark';
        });

        local HideBorderRight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Position = UDim2.new(1, 0, 0, 0);
            Size = UDim2.new(0, 1, 1, 0);
            ZIndex = 8;
            Parent = Fill;
        });

        Library:AddToRegistry(HideBorderRight, {
            BackgroundColor3 = 'AccentColor';
        });

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = 14;
            Text = 'Infinite';
            ZIndex = 9;
            Parent = SliderInner;
        });

        Library:OnHighlight(SliderOuter, SliderOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );

        function Slider:UpdateColors()
            Fill.BackgroundColor3 = Library.AccentColor;
            Fill.BorderColor3 = Library.AccentColorDark;
        end;

        function Slider:Display()
            local Suffix = Info.Suffix or '';
            DisplayLabel.Text = string.format('%s/%s', Slider.Value .. Suffix, Slider.Max .. Suffix);

            local X = math.ceil(Library:MapValue(Slider.Value, Slider.Min, Slider.Max, 0, Slider.MaxSize));
            Fill.Size = UDim2.new(0, X, 1, 0);

            HideBorderRight.Visible = not (X == Slider.MaxSize or X == 0);
        end;

        function Slider:OnChanged(Func)
            Slider.Changed = Func;
            Func();
        end;

        local function Round(Value)
            if Slider.Rounding == 0 then
                return math.floor(Value);
            end;

            local Str = Value .. '';
            local Dot = Str:find('%.');

            return Dot and tonumber(Str:sub(1, Dot + Slider.Rounding)) or Value;
        end;

        function Slider:GetValueFromXOffset(X)
            return Round(Library:MapValue(X, 0, Slider.MaxSize, Slider.Min, Slider.Max));
        end;

        function Slider:SetValue(Str)
            local Num = tonumber(Str);

            if (not Num) then
                return;
            end;

            Num = math.clamp(Num, Slider.Min, Slider.Max);

            Slider.Value = Num;
            Slider:Display();

            if Slider.Changed then
                Slider.Changed();
            end;
        end;

        SliderInner.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                local mPos = Mouse.X;
                local gPos = Fill.Size.X.Offset;
                local Diff = mPos - (Fill.AbsolutePosition.X + gPos);

                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local nMPos = Mouse.X;
                    local nX = math.clamp(gPos + (nMPos - mPos) + Diff, 0, Slider.MaxSize);

                    local nValue = Slider:GetValueFromXOffset(nX);
                    local OldValue = Slider.Value;
                    Slider.Value = nValue;

                    Slider:Display();

                    if nValue ~= OldValue and Slider.Changed then
                        Slider.Changed();
                    end;

                    RenderStepped:Wait();
                end;

                Library:AttemptSave();
            end;
        end);

        Slider:Display();
        Groupbox:AddBlank(Info.BlankSize or 6);
        Groupbox:Resize();

        Options[Idx] = Slider;

        return Slider;
    end;

    function Funcs:AddDropdown(Idx, Info)
        assert(Info.Text and Info.Values, 'Bad Dropdown Data');

        local Dropdown = {
            Values = Info.Values;
            Value = Info.Multi and {};
            Multi = Info.Multi;
            Type = 'Dropdown';
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local RelativeOffset = 0;

        local DropdownLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 10);
            TextSize = 14;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            TextYAlignment = Enum.TextYAlignment.Bottom;
            ZIndex = 5;
            Parent = Container;
        });

        Groupbox:AddBlank(3);

        for _, Element in next, Container:GetChildren() do
            if not Element:IsA('UIListLayout') then
                RelativeOffset = RelativeOffset + Element.Size.Y.Offset;
            end;
        end;

        local DropdownOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 20);
            ZIndex = 5;
            Parent = Container;
        });

        Library:AddToRegistry(DropdownOuter, {
            BorderColor3 = 'Black';
        });

        local DropdownInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = DropdownOuter;
        });

        Library:AddToRegistry(DropdownInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = DropdownInner;
        });

        local DropdownArrow = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0, 0.5);
            BackgroundTransparency = 1;
            Position = UDim2.new(1, -16, 0.5, 0);
            Size = UDim2.new(0, 12, 0, 12);
            Image = 'http://www.roblox.com/asset/?id=6282522798';
            ZIndex = 7;
            Parent = DropdownInner;
        });

        local ItemList = Library:CreateLabel({
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);
            TextSize = 14;
            Text = '--';
            TextXAlignment = Enum.TextXAlignment.Left;
            TextWrapped = true;
            ZIndex = 7;
            Parent = DropdownInner;
        });

        Library:OnHighlight(DropdownOuter, DropdownOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );

        local MAX_DROPDOWN_ITEMS = 8;

        local ListOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 4, 0, 20 + RelativeOffset + 1 + 20);
            Size = UDim2.new(1, -8, 0, MAX_DROPDOWN_ITEMS * 20 + 2);
            ZIndex = 20;
            Visible = false;
            Parent = Container.Parent;
        });

        local ListInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListOuter;
        });

        Library:AddToRegistry(ListInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local Scrolling = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            CanvasSize = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListInner;
        });

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 0);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Scrolling;
        });

        function Dropdown:Display()
            local Values = Dropdown.Values;
            local Str = '';

            if Info.Multi then
                for Idx, Value in next, Values do
                    if Dropdown.Value[Value] then
                        Str = Str .. Value .. ', ';
                    end;
                end;

                Str = Str:sub(1, #Str - 2);
            else
                Str = Dropdown.Value or '';
            end;

            ItemList.Text = (Str == '' and '--' or Str);
        end;

        function Dropdown:GetActiveValues()
            if Info.Multi then
                local T = {};

                for Value, Bool in next, Dropdown.Value do
                    table.insert(T, Value);
                end;

                return T;
            else
                return Dropdown.Value and 1 or 0;
            end;
        end;

        function Dropdown:SetValues()
            local Values = Dropdown.Values;
            local Buttons = {};

            for _, Element in next, Scrolling:GetChildren() do
                if not Element:IsA('UIListLayout') then
                    -- Library:RemoveFromRegistry(Element);
                    Element:Destroy();
                end;
            end;

            local Count = 0;

            for Idx, Value in next, Values do
                local Table = {};

                Count = Count + 1;

                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor;
                    BorderColor3 = Library.OutlineColor;
                    BorderMode = Enum.BorderMode.Middle;
                    Size = UDim2.new(1, -1, 0, 20);
                    ZIndex = 23;
                    Parent = Scrolling;
                });

                Library:AddToRegistry(Button, {
                    BackgroundColor3 = 'MainColor';
                    BorderColor3 = 'OutlineColor';
                });

                local ButtonLabel = Library:CreateLabel({
                    Size = UDim2.new(1, -6, 1, 0);
                    Position = UDim2.new(0, 6, 0, 0);
                    TextSize = 14;
                    Text = Value;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    ZIndex = 25;
                    Parent = Button;
                });

                Library:OnHighlight(Button, Button,
                    { BorderColor3 = 'AccentColor', ZIndex = 24 },
                    { BorderColor3 = 'OutlineColor', ZIndex = 23 }
                );

                local Selected;

                if Info.Multi then
                    Selected = Dropdown.Value[Value];
                else
                    Selected = Dropdown.Value == Value;
                end;

                function Table:UpdateButton()
                    if Info.Multi then
                        Selected = Dropdown.Value[Value];
                    else
                        Selected = Dropdown.Value == Value;
                    end;

                    ButtonLabel.TextColor3 = Selected and Library.AccentColor or Library.FontColor;
                    Library.RegistryMap[ButtonLabel].Properties.TextColor3 = Selected and 'AccentColor' or 'FontColor';
                end;

                ButtonLabel.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        local Try = not Selected;

                        if Dropdown:GetActiveValues() == 1 and (not Try) and (not Info.AllowNull) then
                        else
                            if Info.Multi then
                                Selected = Try;

                                if Selected then
                                    Dropdown.Value[Value] = true;
                                else
                                    Dropdown.Value[Value] = nil;
                                end;
                            else
                                Selected = Try;

                                if Selected then
                                    Dropdown.Value = Value;
                                else
                                    Dropdown.Value = nil;
                                end;

                                for _, OtherButton in next, Buttons do
                                    OtherButton:UpdateButton();
                                end;
                            end;

                            Table:UpdateButton();
                            Dropdown:Display();

                            if Dropdown.Changed then
                                Dropdown.Changed();
                            end;

                            Library:AttemptSave();
                        end;
                    end;
                end);

                Table:UpdateButton();
                Dropdown:Display();

                Buttons[Button] = Table;
            end;

            local Y = math.clamp(Count * 20, 0, MAX_DROPDOWN_ITEMS * 20) + 1;
            ListOuter.Size = UDim2.new(1, -8, 0, Y);
            Scrolling.CanvasSize = UDim2.new(0, 0, 0, Count * 20);

            -- ListOuter.Size = UDim2.new(1, -8, 0, (#Values * 20) + 2);
        end;

        function Dropdown:OpenDropdown()
            ListOuter.Visible = true;
            Library.OpenedFrames[ListOuter] = true;
            DropdownArrow.Rotation = 180;
        end;

        function Dropdown:CloseDropdown()
            ListOuter.Visible = false;
            Library.OpenedFrames[ListOuter] = nil;
            DropdownArrow.Rotation = 0;
        end;

        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func;
            Func();
        end;

        function Dropdown:SetValue(Val)
            if Dropdown.Multi then
                local nTable = {};

                for Value, Bool in next, Val do
                    if table.find(Dropdown.Values, Value) then
                        nTable[Value] = true
                    end;
                end;

                Dropdown.Value = nTable;
            else
                if (not Val) then
                    Dropdown.Value = nil;
                elseif table.find(Dropdown.Values, Val) then
                    Dropdown.Value = Val;
                end;
            end;

            Dropdown:SetValues();
            Dropdown:Display();
        end;

        DropdownOuter.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                if ListOuter.Visible then
                    Dropdown:CloseDropdown();
                else
                    Dropdown:OpenDropdown();
                end;
            end;
        end);

        InputService.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local AbsPos, AbsSize = ListOuter.AbsolutePosition, ListOuter.AbsoluteSize;

                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

                    Dropdown:CloseDropdown();
                end;
            end;
        end);

        Dropdown:SetValues();
        Dropdown:Display();

        if type(Info.Default) == 'string' then
            Info.Default = table.find(Dropdown.Values, Info.Default)
        end

        if Info.Default then
            if Info.Multi then
                Dropdown.Value[Dropdown.Values[Info.Default]] = true;
            else
                Dropdown.Value = Dropdown.Values[Info.Default];
            end;

            Dropdown:SetValues();
            Dropdown:Display();
        end;

        Groupbox:AddBlank(Info.BlankSize or 5);
        Groupbox:Resize();

        Options[Idx] = Dropdown;

        return Dropdown;
    end;

    BaseGroupbox.__index = Funcs;
    BaseGroupbox.__namecall = function(Table, Key, ...)
        return Funcs[Key](...);
    end;
end;

-- < Create other UI elements >
do
    Library.NotificationArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 0, 0, 40);
        Size = UDim2.new(0, 300, 0, 200);
        ZIndex = 100;
        Parent = ScreenGui;
    });

    Library:Create('UIListLayout', {
        Padding = UDim.new(0, 4);
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = Library.NotificationArea;
    });



    local WatermarkOuter = Library:Create('Frame', {
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 100, 0, -25);
        Size = UDim2.new(0, 213, 0, 20);
        ZIndex = 200;
        Visible = false;
        Parent = ScreenGui;
    });

    local WatermarkInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.AccentColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 201;
        Parent = WatermarkOuter;
    });

    Library:AddToRegistry(WatermarkInner, {
        BorderColor3 = 'AccentColor';
    });

    local InnerFrame = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 202;
        Parent = WatermarkInner;
    });

    Library:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(27, 27, 27)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(52, 52, 52))
        });
        Rotation = -90;
        Parent = InnerFrame;
    });

    local WatermarkLabel = Library:CreateLabel({
        Position = UDim2.new(0, 4, 0, 0);
        Size = UDim2.new(1, -4, 1, 0);
        TextSize = 14;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 203;
        Parent = InnerFrame;
    });

    Library.Watermark = WatermarkOuter;
    Library.WatermarkText = WatermarkLabel;
    Library:MakeDraggable(Library.Watermark);



    local KeybindOuter = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0, 0.5);
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 10, 0.5, 0);
        Size = UDim2.new(0, 210, 0, 20);
        Visible = false;
        ZIndex = 100;
        Parent = ScreenGui;
    });

    local KeybindInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 101;
        Parent = KeybindOuter;
    });

    Library:AddToRegistry(KeybindInner, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    }, true);

    local ColorFrame = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Size = UDim2.new(1, 0, 0, 2);
        ZIndex = 102;
        Parent = KeybindInner;
    });

    Library:AddToRegistry(ColorFrame, {
        BackgroundColor3 = 'AccentColor';
    }, true);

    local KeybindLabel = Library:CreateLabel({
        Size = UDim2.new(1, 0, 0, 20);
        Text = 'Keybinds';
        ZIndex = 104;
        Parent = KeybindInner;
    });

    local KeybindContainer = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Size = UDim2.new(1, 0, 1, -20);
        Position = UDim2.new(0, 0, 0, 20);
        ZIndex = 1;
        Parent = KeybindInner;
    });

    Library:Create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = KeybindContainer;
    });

    Library.KeybindFrame = KeybindOuter;
    Library.KeybindContainer = KeybindContainer;
    Library:MakeDraggable(KeybindOuter);
end;

function Library:SetWatermarkVisibility(Bool)
    Library.Watermark.Visible = Bool;
end;

function Library:SetWatermark(Text)
    local Size = Library:GetTextBounds(Text, Enum.Font.Code, 14);
    Library.Watermark.Size = UDim2.new(0, Size + 8 + 2, 0, 20);
    Library:SetWatermarkVisibility(true)

    Library.WatermarkText.Text = Text;
end;

function Library:Notify(Text, Time)
    local MaxSize = Library:GetTextBounds(Text, Enum.Font.Code, 14);

    local NotifyOuter = Library:Create('Frame', {
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 100, 0, 10);
        Size = UDim2.new(0, 0, 0, 20);
        ClipsDescendants = true;
        ZIndex = 100;
        Parent = Library.NotificationArea;
    });

    local NotifyInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 101;
        Parent = NotifyOuter;
    });

    Library:AddToRegistry(NotifyInner, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    }, true);

    local InnerFrame = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 102;
        Parent = NotifyInner;
    });

    Library:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(27, 27, 27)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(52, 52, 52))
        });
        Rotation = -90;
        Parent = InnerFrame;
    });

    local NotifyLabel = Library:CreateLabel({
        Position = UDim2.new(0, 4, 0, 0);
        Size = UDim2.new(1, -4, 1, 0);
        Text = Text;
        TextXAlignment = Enum.TextXAlignment.Left;
        TextSize = 14;
        ZIndex = 103;
        Parent = InnerFrame;
    });

    local LeftColor = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Position = UDim2.new(0, -1, 0, -1);
        Size = UDim2.new(0, 3, 1, 2);
        ZIndex = 104;
        Parent = NotifyOuter;
    });

    Library:AddToRegistry(LeftColor, {
        BackgroundColor3 = 'AccentColor';
    }, true);

    NotifyOuter:TweenSize(UDim2.new(0, MaxSize + 8 + 4, 0, 20), 'Out', 'Quad', 0.4, true);

    task.spawn(function()
        wait(5 or Time);

        NotifyOuter:TweenSize(UDim2.new(0, 0, 0, 20), 'Out', 'Quad', 0.4, true);

        wait(0.4);

        NotifyOuter:Destroy();
    end);
end;

function Library:CreateWindow(WindowTitle)
    local Window = {
        Tabs = {};
    };

    local Outer = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(0, 0, 0);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 175, 0, 50);
        Size = UDim2.new(0, 550, 0, 600);
        Visible = false;
        ZIndex = 1;
        Parent = ScreenGui;
    });

    Library:MakeDraggable(Outer, 25);

    local Inner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.AccentColor;
        BorderMode = Enum.BorderMode.Inset;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 1;
        Parent = Outer;
    });

    Library:AddToRegistry(Inner, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'AccentColor';
    });

    local WindowLabel = Library:CreateLabel({
        Position = UDim2.new(0, 7, 0, 0);
        Size = UDim2.new(0, 0, 0, 25);
        Text = WindowTitle or '';
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 1;
        Parent = Inner;
    });

    local MainSectionOuter = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Library.OutlineColor;
        Position = UDim2.new(0, 8, 0, 25);
        Size = UDim2.new(1, -16, 1, -33);
        ZIndex = 1;
        Parent = Inner;
    });

    Library:AddToRegistry(MainSectionOuter, {
        BackgroundColor3 = 'BackgroundColor';
        BorderColor3 = 'OutlineColor';
    });

    local MainSectionInner = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Color3.new(0, 0, 0);
        BorderMode = Enum.BorderMode.Inset;
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 1;
        Parent = MainSectionOuter;
    });

    Library:AddToRegistry(MainSectionInner, {
        BackgroundColor3 = 'BackgroundColor';
    });

    local TabArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 8, 0, 8);
        Size = UDim2.new(1, -16, 0, 21);
        ZIndex = 1;
        Parent = MainSectionInner;
    });

    Library:Create('UIListLayout', {
        Padding = UDim.new(0, 0);
        FillDirection = Enum.FillDirection.Horizontal;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = TabArea;
    });

    local TabContainer = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        Position = UDim2.new(0, 8, 0, 30);
        Size = UDim2.new(1, -16, 1, -38);
        ZIndex = 2;
        Parent = MainSectionInner;
    });

    Library:AddToRegistry(TabContainer, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    });

    function Window:SetWindowTitle(Title)
        WindowLabel.Text = Title;
    end;

    function Window:AddTab(Name)
        local Tab = {
            Groupboxes = {};
            Tabboxes = {};
        };

        local TabButtonWidth = Library:GetTextBounds(Name, Enum.Font.Code, 16);

        local TabButton = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            Size = UDim2.new(0, TabButtonWidth + 8 + 4, 1, 0);
            ZIndex = 1;
            Parent = TabArea;
        });

        Library:AddToRegistry(TabButton, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });

        local TabButtonLabel = Library:CreateLabel({
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, -1);
            Text = Name;
            ZIndex = 1;
            Parent = TabButton;
        });

        local Blocker = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 0, 1, 0);
            Size = UDim2.new(1, 0, 0, 1);
            BackgroundTransparency = 1;
            ZIndex = 3;
            Parent = TabButton;
        });

        Library:AddToRegistry(Blocker, {
            BackgroundColor3 = 'MainColor';
        });

        local TabFrame = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            Visible = false;
            ZIndex = 2;
            Parent = TabContainer;
        });

        local LeftSide = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 8, 0, 8);
            Size = UDim2.new(0.5, -12, 0, 507);
            ZIndex = 2;
            Parent = TabFrame;
        });

        local RightSide = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Position = UDim2.new(0.5, 4, 0, 8);
            Size = UDim2.new(0.5, -12, 0, 507);
            ZIndex = 2;
            Parent = TabFrame;
        });

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = LeftSide;
        });

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = RightSide;
        });

        function Tab:ShowTab()
            for _, Tab in next, Window.Tabs do
                Tab:HideTab();
            end;

            Blocker.BackgroundTransparency = 0;
            TabButton.BackgroundColor3 = Library.MainColor;
            TabFrame.Visible = true;
        end;

        function Tab:HideTab()
            Blocker.BackgroundTransparency = 1;
            TabButton.BackgroundColor3 = Library.BackgroundColor;
            TabFrame.Visible = false;
        end;

        function Tab:AddGroupbox(Info)
            local Groupbox = {};

            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                Size = UDim2.new(1, 0, 0, 507);
                ZIndex = 2;
                Parent = Info.Side == 1 and LeftSide or RightSide;
            });

            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = 'BackgroundColor';
                BorderColor3 = 'OutlineColor';
            });

            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Color3.new(0, 0, 0);
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 4;
                Parent = BoxOuter;
            });

            Library:AddToRegistry(BoxInner, {
                BackgroundColor3 = 'BackgroundColor';
            });

            local Highlight = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 2);
                ZIndex = 5;
                Parent = BoxInner;
            });

            Library:AddToRegistry(Highlight, {
                BackgroundColor3 = 'AccentColor';
            });

            local GroupboxLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 18);
                Position = UDim2.new(0, 4, 0, 2);
                TextSize = 14;
                Text = Info.Name;
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex = 5;
                Parent = BoxInner;
            });

            local Container = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 4, 0, 20);
                Size = UDim2.new(1, -4, 1, -20);
                ZIndex = 1;
                Parent = BoxInner;
            });

            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = Container;
            });

            function Groupbox:Resize()
                local Size = 0;

                for _, Element in next, Groupbox.Container:GetChildren() do
                    if not Element:IsA('UIListLayout') then
                        Size = Size + Element.Size.Y.Offset;
                    end;
                end;

                BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2);
            end;

            Groupbox.Container = Container;
            setmetatable(Groupbox, BaseGroupbox);

            Groupbox:AddBlank(3);
            Groupbox:Resize();

            Tab.Groupboxes[Info.Name] = Groupbox;

            return Groupbox;
        end;

        function Tab:AddLeftGroupbox(Name)
            return Tab:AddGroupbox({ Side = 1; Name = Name; });
        end;

        function Tab:AddRightGroupbox(Name)
            return Tab:AddGroupbox({ Side = 2; Name = Name; });
        end;

        function Tab:AddTabbox(Info)
            local Tabbox = {
                Tabs = {};
            };

            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                Size = UDim2.new(1, 0, 0, 0);
                ZIndex = 2;
                Parent = Info.Side == 1 and LeftSide or RightSide;
            });

            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = 'BackgroundColor';
                BorderColor3 = 'OutlineColor';
            });

            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Color3.new(0, 0, 0);
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 4;
                Parent = BoxOuter;
            });

            Library:AddToRegistry(BoxInner, {
                BackgroundColor3 = 'BackgroundColor';
            });

            local Highlight = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 2);
                ZIndex = 10;
                Parent = BoxInner;
            });

            Library:AddToRegistry(Highlight, {
                BackgroundColor3 = 'AccentColor';
            });

            local TabboxButtons = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 0, 0, 1);
                Size = UDim2.new(1, 0, 0, 18);
                ZIndex = 5;
                Parent = BoxInner;
            });

            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Left;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TabboxButtons;
            });

            function Tabbox:AddTab(Name)
                local Tab = {};

                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor;
                    BorderColor3 = Color3.new(0, 0, 0);
                    Size = UDim2.new(0.5, 0, 1, 0);
                    ZIndex = 6;
                    Parent = TabboxButtons;
                });

                Library:AddToRegistry(Button, {
                    BackgroundColor3 = 'MainColor';
                });

                local ButtonLabel = Library:CreateLabel({
                    Size = UDim2.new(1, 0, 1, 0);
                    TextSize = 14;
                    Text = Name;
                    TextXAlignment = Enum.TextXAlignment.Center;
                    ZIndex = 7;
                    Parent = Button;
                });

                local Block = Library:Create('Frame', {
                    BackgroundColor3 = Library.BackgroundColor;
                    BorderSizePixel = 0;
                    Position = UDim2.new(0, 0, 1, 0);
                    Size = UDim2.new(1, 0, 0, 1);
                    Visible = false;
                    ZIndex = 9;
                    Parent = Button;
                });

                Library:AddToRegistry(Block, {
                    BackgroundColor3 = 'BackgroundColor';
                });

                local Container = Library:Create('Frame', {
                    Position = UDim2.new(0, 4, 0, 20);
                    Size = UDim2.new(1, -4, 1, -20);
                    ZIndex = 1;
                    Visible = false;
                    Parent = BoxInner;
                });

                Library:Create('UIListLayout', {
                    FillDirection = Enum.FillDirection.Vertical;
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    Parent = Container;
                });

                function Tab:Show()
                    for _, Tab in next, Tabbox.Tabs do
                        Tab:Hide();
                    end;

                    Container.Visible = true;
                    Block.Visible = true;

                    Button.BackgroundColor3 = Library.BackgroundColor;
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'BackgroundColor';
                end;

                function Tab:Hide()
                    Container.Visible = false;
                    Block.Visible = false;

                    Button.BackgroundColor3 = Library.MainColor;
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'MainColor';
                end;

                function Tab:Resize()
                    local TabCount = 0;

                    for _, Tab in next, Tabbox.Tabs do
                        TabCount = TabCount +  1;
                    end;

                    for _, Button in next, TabboxButtons:GetChildren() do
                        if not Button:IsA('UIListLayout') then
                            Button.Size = UDim2.new(1 / TabCount, 0, 1, 0);
                        end;
                    end;

                    local Size = 0;

                    for _, Element in next, Tab.Container:GetChildren() do
                        if not Element:IsA('UIListLayout') then
                            Size = Size + Element.Size.Y.Offset;
                        end;
                    end;

                    if BoxOuter.Size.Y.Offset < 20 + Size + 2 then
                        BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2);
                    end;
                end;

                Button.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                        Tab:Show();
                    end;
                end);

                Tab.Container = Container;
                Tabbox.Tabs[Name] = Tab;

                setmetatable(Tab, BaseGroupbox);

                Tab:AddBlank(3);
                Tab:Resize();

                if #TabboxButtons:GetChildren() == 2 then
                    Tab:Show();
                end;

                return Tab;
            end;

            Tab.Tabboxes[Info.Name or ''] = Tabbox;

            return Tabbox;
        end;

        function Tab:AddLeftTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 1; });
        end;

        function Tab:AddRightTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 2; });
        end;

        TabButton.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                Tab:ShowTab();
            end;
        end);

        -- This was the first tab added, so we show it by default.
        if #TabContainer:GetChildren() == 1 then
            Tab:ShowTab();
        end;

        Window.Tabs[Name] = Tab;
        return Tab;
    end;

    local ModalElement = Library:Create('TextButton', {
        BackgroundTransparency = 1;
        Size = UDim2.new(0, 0, 0, 0);
        Visible = true;
        Text = '';
        Modal = false;
        Parent = ScreenGui;
    });

    Library.MenuToggleConnection = InputService.InputBegan:Connect(function(Input, Processed)
        if Library.Unloaded or (not Outer.Parent) then return end;
        if Input.KeyCode == Enum.KeyCode.RightShift and (not Processed) then
            Outer.Visible = not Outer.Visible;
            ModalElement.Modal = Outer.Visible;

            local oIcon = Mouse.Icon;
            local State = InputService.MouseIconEnabled;

            local Cursor = Drawing.new('Triangle');
            Cursor.Thickness = 1;
            Cursor.Filled = true;

            while Outer.Visible and Outer.Parent and (not Library.Unloaded) do
                local mPos = workspace.CurrentCamera:WorldToViewportPoint(Mouse.Hit.p);

                Cursor.Color = Library.AccentColor;
                Cursor.PointA = Vector2.new(mPos.X, mPos.Y);
                Cursor.PointB = Vector2.new(mPos.X, mPos.Y) + Vector2.new(6, 14);
                Cursor.PointC = Vector2.new(mPos.X, mPos.Y) + Vector2.new(-6, 14);

                Cursor.Visible = not InputService.MouseIconEnabled;

                RenderStepped:Wait();
            end;

            Cursor:Remove();
        end;
    end);

    Window.Holder = Outer;

    return Window;
end;

return Library;
end)()

-- =====================================================================
-- MENU
-- =====================================================================
--[[==========================================================================
    VOXEL RADAR // MENU  (Linoria)
    ทุกคอนโทรลเขียนลง Core.Settings ตรง ๆ ไม่มี state ซ้ำซ้อน
==========================================================================]]

local Menu = (function()

	local S  = Core.Settings
	local M  = {}
	local TG = getgenv().Toggles
	local OP = getgenv().Options
	local syncUI

	pcall(function() Library.FontFace = Font.fromName("Sarabun") end)

	Library.AccentColor = Color3.fromRGB(255, 60, 85)
	Library.Unloaded = false
	pcall(function() Library:UpdateColorsUsingRegistry() end)

	local Window = Library:CreateWindow("VOXEL RADAR")
	pcall(function() Library:SetWatermarkVisibility(false) end)

	local genv = (getgenv and getgenv()) or _G
	if Window.Holder and Window.Holder.Parent then
		genv.__vx_gui = Window.Holder.Parent
	end

	------------------------------------------------------------------ tabs
	local TCombat = Window:AddTab("Combat")
	local TVisual = Window:AddTab("Visual")
	local TTeam   = Window:AddTab("Team")
	local TMisc   = Window:AddTab("Misc")
	local TInfo   = Window:AddTab("Info")

	------------------------------------------------------------ combat / L
	local LeftCombat = TCombat:AddLeftGroupbox("Enemy Vision")

	LeftCombat:AddToggle("VX_Chams", {
		Text = "Enemy Chams",
		Default = S.Chams.Enabled,
		Tooltip = "ไฮไลต์เฉพาะศัตรู (เพื่อนร่วมทีมไม่ติด)",
	})
	TG.VX_Chams:OnChanged(function()
		S.Chams.Enabled = TG.VX_Chams.Value
	end)

	LeftCombat:AddToggle("VX_Bars", {
		Text = "Health Bars",
		Default = S.Bars.Enabled,
		Tooltip = "แถบเลือด + ระยะเหนือหัว",
	})
	TG.VX_Bars:OnChanged(function()
		S.Bars.Enabled = TG.VX_Bars.Value
	end)

	LeftCombat:AddToggle("VX_Skel", {
		Text = "Skeleton ESP (Drawing)",
		Default = S.Skeleton.Enabled,
		Tooltip = "โครงกระดูกจาก Motor6D — ไม่มี Instance ใน DataModel เลย",
	})
	TG.VX_Skel:OnChanged(function()
		S.Skeleton.Enabled = TG.VX_Skel.Value
	end)

	LeftCombat:AddLabel("Chams bind"):AddKeyPicker("VX_ChamsBind", {
		Default = "Z",
		Mode = "Toggle",
		Text = "เปิด/ปิด Enemy Chams",
	})
	OP.VX_ChamsBind:OnClick(function()
		TG.VX_Chams:SetValue(not TG.VX_Chams.Value)
	end)

	------------------------------------------------------------ combat / R
	local RightCombat = TCombat:AddRightGroupbox("Range & Limit")

	RightCombat:AddSlider("VX_MaxCount", {
		Text = "จำนวน Chams สูงสุด",
		Default = S.Chams.MaxCount, Min = 1, Max = 64, Rounding = 0,
	})
	OP.VX_MaxCount:OnChanged(function()
		S.Chams.MaxCount = math.floor(OP.VX_MaxCount.Value)
	end)

	RightCombat:AddSlider("VX_MaxDist", {
		Text = "ระยะ Chams (สตัด)",
		Default = S.Chams.MaxDist, Min = 100, Max = 4000, Rounding = 0,
	})
	OP.VX_MaxDist:OnChanged(function()
		S.Chams.MaxDist = math.floor(OP.VX_MaxDist.Value)
	end)

	RightCombat:AddSlider("VX_BarDist", {
		Text = "ระยะแถบเลือด (สตัด)",
		Default = S.Bars.MaxDist, Min = 100, Max = 4000, Rounding = 0,
	})
	OP.VX_BarDist:OnChanged(function()
		S.Bars.MaxDist = math.floor(OP.VX_BarDist.Value)
	end)

	RightCombat:AddSlider("VX_SkelCount", {
		Text = "จำนวน Skeleton",
		Default = S.Skeleton.MaxCount, Min = 1, Max = 24, Rounding = 0,
	})
	OP.VX_SkelCount:OnChanged(function()
		S.Skeleton.MaxCount = math.floor(OP.VX_SkelCount.Value)
	end)

	RightCombat:AddSlider("VX_SkelDist", {
		Text = "ระยะ Skeleton (สตัด)",
		Default = S.Skeleton.MaxDist, Min = 50, Max = 1200, Rounding = 0,
	})
	OP.VX_SkelDist:OnChanged(function()
		S.Skeleton.MaxDist = math.floor(OP.VX_SkelDist.Value)
	end)

	------------------------------------------------------------ visual / L
	local LeftVisual = TVisual:AddLeftGroupbox("Style")

	LeftVisual:AddLabel("สี Chams"):AddColorPicker("VX_Color", {
		Default = S.Chams.Color,
		Title = "Chams Color",
	})
	OP.VX_Color:OnChanged(function()
		S.Chams.Color = OP.VX_Color.Value
		Core.ApplyStyle()
	end)

	LeftVisual:AddSlider("VX_Fill", {
		Text = "ความโปร่งแสง Fill",
		Default = S.Chams.Fill, Min = 0.1, Max = 0.95, Rounding = 2,
	})
	OP.VX_Fill:OnChanged(function()
		S.Chams.Fill = OP.VX_Fill.Value
		Core.ApplyStyle()
	end)

	LeftVisual:AddSlider("VX_Outline", {
		Text = "ความโปร่งแสง Outline",
		Default = S.Chams.Outline, Min = 0, Max = 1, Rounding = 2,
	})
	OP.VX_Outline:OnChanged(function()
		S.Chams.Outline = OP.VX_Outline.Value
		Core.ApplyStyle()
	end)

	----------------------------------------------------------- visual / R
	local RightVisual = TVisual:AddRightGroupbox("Bars & Depth")

	RightVisual:AddDropdown("VX_Depth", {
		Text = "โหมด Chams",
		Values = { "XRay", "Glow" },
		Default = S.Chams.Depth,
		Tooltip = "XRay = เห็นทะลุกำแพง · Glow = เห็นเฉพาะในสายตา",
	})
	OP.VX_Depth:OnChanged(function()
		S.Chams.Depth = OP.VX_Depth.Value
		Core.ApplyStyle()
	end)

	RightVisual:AddToggle("VX_BName", { Text = "แสดงชื่อ", Default = S.Bars.ShowName })
	TG.VX_BName:OnChanged(function() S.Bars.ShowName = TG.VX_BName.Value end)

	RightVisual:AddToggle("VX_BHP", { Text = "แสดงเลขเลือด", Default = S.Bars.ShowHP })
	TG.VX_BHP:OnChanged(function() S.Bars.ShowHP = TG.VX_BHP.Value end)

	RightVisual:AddToggle("VX_BDist", { Text = "แสดงระยะ", Default = S.Bars.ShowDist })
	TG.VX_BDist:OnChanged(function() S.Bars.ShowDist = TG.VX_BDist.Value end)

	-------------------------------------------------------------- team / L
	local LeftTeam = TTeam:AddLeftGroupbox("Detection")

	LeftTeam:AddDropdown("VX_Mode", {
		Text = "กฎการแยกศัตรู",
		Values = { "Auto", "FFA", "Strict" },
		Default = S.Detect.Mode,
		Tooltip = "Auto = อ่านทีมก่อน · ถ้าเกมไม่มีทีมจะนับทุกคนเป็นศัตรู",
	})
	OP.VX_Mode:OnChanged(function()
		S.Detect.Mode = OP.VX_Mode.Value
		Core.Refresh()
	end)

	LeftTeam:AddToggle("VX_Bots", {
		Text = "ไฮไลต์บอท / Rig",
		Default = S.Detect.Bots,
	})
	TG.VX_Bots:OnChanged(function()
		S.Detect.Bots = TG.VX_Bots.Value
		Core.Refresh()
	end)

	LeftTeam:AddToggle("VX_WS", {
		Text = "สแกน Model ทั้ง Workspace",
		Default = S.Detect.WorkspaceScan,
		Tooltip = "ปิดได้ถ้าเกมมี prop แปลก ๆ ที่ทำให้อ่านผิด",
	})
	TG.VX_WS:OnChanged(function()
		S.Detect.WorkspaceScan = TG.VX_WS.Value
		Core.Refresh()
	end)

	LeftTeam:AddToggle("VX_Teamless", {
		Text = "ไฮไลต์คนที่ยังไม่มีทีม",
		Default = S.Detect.Teamless,
		Tooltip = "ปกติปิดไว้: ตอนอยู่ใน lobby ที่ยังไม่เลือกฝั่ง จะได้ไม่ติดเพื่อนตัวเอง",
	})
	TG.VX_Teamless:OnChanged(function()
		S.Detect.Teamless = TG.VX_Teamless.Value
		Core.Refresh()
	end)

	------------------------------------------------------------- team / R
	local RightTeam = TTeam:AddRightGroupbox("Status")

	RightTeam:AddButton("สแกนใหม่ทันที", function()
		Core.Refresh()
	end)

	local infoLabel = RightTeam:AddLabel("กำลังอ่านข้อมูล...")
	task.spawn(function()
		while not Library.Unloaded do
			local total, enemies = Core.Stats()
			if OP.VX_PanicKey and OP.VX_PanicKey.Value then
				S.Keys.Panic = OP.VX_PanicKey.Value
			end
			pcall(function()
				infoLabel.TextLabel.Text = string.format(
					"ศัตรู %d/%d · %.0f fps · budget %.0f%%",
					enemies, total, Core.Fps(), Core.Scale() * 100
				)
			end)
			task.wait(1)
		end
	end)

	-------------------------------------------------------------- misc / L
	local LeftMisc = TMisc:AddLeftGroupbox("Recoil")

	LeftMisc:AddToggle("VX_Recoil", {
		Text = "Recoil Dampener",
		Default = S.Recoil.Enabled,
		Tooltip = "ดึงเมาส์ลงเบา ๆ ขณะยิง",
	})
	TG.VX_Recoil:OnChanged(function() S.Recoil.Enabled = TG.VX_Recoil.Value end)

	LeftMisc:AddSlider("VX_RStrength", {
		Text = "ความแรง",
		Default = S.Recoil.Strength, Min = 0.5, Max = 8, Rounding = 1,
	})
	OP.VX_RStrength:OnChanged(function() S.Recoil.Strength = OP.VX_RStrength.Value end)

	LeftMisc:AddSlider("VX_RSmooth", {
		Text = "ความนุ่ม (1 = เร็วสุด)",
		Default = S.Recoil.Smooth, Min = 1, Max = 6, Rounding = 0,
	})
	OP.VX_RSmooth:OnChanged(function() S.Recoil.Smooth = math.floor(OP.VX_RSmooth.Value) end)

	LeftMisc:AddBlank(6)

	LeftMisc:AddToggle("VX_Human", {
		Text = "Humanizer (กะพริบเป็นช่วง ๆ)",
		Default = S.Human.Enabled,
		Tooltip = "ปิด Chams สุ่มช่วงสั้น ๆ ให้ pattern ไม่นิ่ง",
	})
	TG.VX_Human:OnChanged(function()
		S.Human.Enabled = TG.VX_Human.Value
	end)

	------------------------------------------------------------- misc / R
	local RightMisc = TMisc:AddRightGroupbox("Performance")

	RightMisc:AddDropdown("VX_Profile", {
		Text = "โปรไฟล์",
		Values = { "Legit", "Rage" },
		Default = (S.Profile == "Rage") and "Rage" or "Legit",
		Tooltip = "Legit = เงียบ ระยะสั้น · Rage = เห็นไกล สีจัด",
	})
	OP.VX_Profile:OnChanged(function()
		local name = OP.VX_Profile.Value
		if name == "Legit" or name == "Rage" then
			Core.ApplyProfile(name)
			if syncUI then syncUI() end
			Library:Notify("ใช้โปรไฟล์ " .. name, 2)
		end
	end)

	RightMisc:AddToggle("VX_Fps", {
		Text = "Potato FPS Mode",
		Default = false,
		Tooltip = "ปิดเงา / effect / particle · คืนค่ากลับได้",
	})
	TG.VX_Fps:OnChanged(function()
		Core.SetFps(TG.VX_Fps.Value)
	end)

	RightMisc:AddLabel("Panic key"):AddKeyPicker("VX_PanicKey", {
		Default = "Delete",
		Mode = "Toggle",
		Text = "Panic — ซ่อนทุกอย่างทันที",
	})
	OP.VX_PanicKey:OnClick(function()
		Core.SetPanic(not S.Panic)
	end)

	RightMisc:AddButton("Panic ทันที (ซ่อน/คืน)", function()
		Core.SetPanic(not S.Panic)
	end)

	RightMisc:AddBlank(6)

	RightMisc:AddButton("บันทึกค่า (Save)", function() M.Save() end)
	RightMisc:AddButton("โหลดค่า (Load)", function() M.Load() end)

	--------------------------------------------------------------- config
	local FILE = "VXR8/settings.json"
	local PLACE_FILE = "VXR8/place_" .. tostring(game.PlaceId) .. ".json"

	syncUI = function()
		pcall(function()
			TG.VX_Chams:SetValue(S.Chams.Enabled)
			TG.VX_Bars:SetValue(S.Bars.Enabled)
			TG.VX_Skel:SetValue(S.Skeleton.Enabled)
			TG.VX_Human:SetValue(S.Human.Enabled)
			TG.VX_Recoil:SetValue(S.Recoil.Enabled)
			OP.VX_MaxCount:SetValue(S.Chams.MaxCount)
			OP.VX_MaxDist:SetValue(S.Chams.MaxDist)
			OP.VX_BarDist:SetValue(S.Bars.MaxDist)
			OP.VX_SkelCount:SetValue(S.Skeleton.MaxCount)
			OP.VX_SkelDist:SetValue(S.Skeleton.MaxDist)
			OP.VX_Fill:SetValue(S.Chams.Fill)
			OP.VX_Outline:SetValue(S.Chams.Outline)
			OP.VX_Depth:SetValue(S.Chams.Depth)
		end)
	end

	pcall(function() Core.SetSync(syncUI) end)

	local function rgb(c)
		return {
			math.floor(c.R * 255 + 0.5),
			math.floor(c.G * 255 + 0.5),
			math.floor(c.B * 255 + 0.5),
		}
	end

	function M.Save()
		if type(writefile) ~= "function" then
			Library:Notify("executor นี้ไม่รองรับ writefile", 3)
			return
		end
		local ok = pcall(function()
			if type(makefolder) == "function" and type(isfolder) == "function" and not isfolder("VXR8") then
				pcall(makefolder, "VXR8")
			end
			local data = {
				profile = S.Profile,
				chams = {
					enabled = S.Chams.Enabled, fill = S.Chams.Fill, outline = S.Chams.Outline,
					depth = S.Chams.Depth, maxCount = S.Chams.MaxCount, maxDist = S.Chams.MaxDist,
					color = rgb(S.Chams.Color),
				},
				skeleton = {
					enabled = S.Skeleton.Enabled, maxCount = S.Skeleton.MaxCount,
					maxDist = S.Skeleton.MaxDist, thickness = S.Skeleton.Thickness,
				},
				bars = {
					enabled = S.Bars.Enabled, name = S.Bars.ShowName, hp = S.Bars.ShowHP,
					dist = S.Bars.ShowDist, maxDist = S.Bars.MaxDist,
				},
				recoil = { enabled = S.Recoil.Enabled, strength = S.Recoil.Strength, smooth = S.Recoil.Smooth },
				detect = {
					mode = S.Detect.Mode, bots = S.Detect.Bots,
					ws = S.Detect.WorkspaceScan, teamless = S.Detect.Teamless,
				},
				human = {
					enabled = S.Human.Enabled, minGap = S.Human.MinGap, maxGap = S.Human.MaxGap,
					minHold = S.Human.MinHold, maxHold = S.Human.MaxHold,
				},
				keys = { panic = S.Keys.Panic },
			}
			local text = game:GetService("HttpService"):JSONEncode(data)
			writefile(FILE, text)
			pcall(writefile, PLACE_FILE, text)
		end)
		Library:Notify(ok and "บันทึกแล้ว (global + เกมนี้)" or "เซฟไม่สำเร็จ", 3)
	end

	function M.Load(silent)
		if type(readfile) ~= "function" or type(isfile) ~= "function" then
			if not silent then Library:Notify("executor ไม่รองรับ readfile", 3) end
			return
		end
		local path = isfile(PLACE_FILE) and PLACE_FILE or FILE
		if not isfile(path) then
			if not silent then Library:Notify("ยังไม่มีไฟล์ config", 3) end
			return
		end
		local ok, data = pcall(function()
			return game:GetService("HttpService"):JSONDecode(readfile(path))
		end)
		if not ok or type(data) ~= "table" then
			Library:Notify("config เสียหาย", 3)
			return
		end

		if type(data.chams) == "table" then
			local c = data.chams
			S.Chams.Fill     = tonumber(c.fill) or S.Chams.Fill
			S.Chams.Outline  = tonumber(c.outline) or S.Chams.Outline
			S.Chams.Depth    = c.depth or S.Chams.Depth
			S.Chams.MaxCount = tonumber(c.maxCount) or S.Chams.MaxCount
			S.Chams.MaxDist  = tonumber(c.maxDist) or S.Chams.MaxDist
			if type(c.color) == "table" then
				S.Chams.Color = Color3.fromRGB(c.color[1] or 255, c.color[2] or 45, c.color[3] or 65)
			end
			pcall(function() OP.VX_Color:SetValueRGB(S.Chams.Color) end)
		end
		if type(data.skeleton) == "table" then
			S.Skeleton.MaxCount = tonumber(data.skeleton.maxCount) or S.Skeleton.MaxCount
			S.Skeleton.MaxDist  = tonumber(data.skeleton.maxDist) or S.Skeleton.MaxDist
		end
		if type(data.bars) == "table" then
			S.Bars.MaxDist = tonumber(data.bars.maxDist) or S.Bars.MaxDist
		end
		if type(data.recoil) == "table" then
			S.Recoil.Strength = tonumber(data.recoil.strength) or S.Recoil.Strength
			S.Recoil.Smooth   = tonumber(data.recoil.smooth) or S.Recoil.Smooth
		end
		if type(data.detect) == "table" then
			if data.detect.mode then
				S.Detect.Mode = data.detect.mode
				pcall(function() OP.VX_Mode:SetValue(S.Detect.Mode) end)
			end
			if data.detect.teamless ~= nil then
				S.Detect.Teamless = data.detect.teamless == true
				pcall(function() TG.VX_Teamless:SetValue(S.Detect.Teamless) end)
			end
		end
		if type(data.human) == "table" then
			S.Human.MinGap  = tonumber(data.human.minGap) or S.Human.MinGap
			S.Human.MaxGap  = tonumber(data.human.maxGap) or S.Human.MaxGap
			S.Human.MinHold = tonumber(data.human.minHold) or S.Human.MinHold
			S.Human.MaxHold = tonumber(data.human.maxHold) or S.Human.MaxHold
		end
		if type(data.keys) == "table" and type(data.keys.panic) == "string" then
			S.Keys.Panic = data.keys.panic
			pcall(function() OP.VX_PanicKey:SetValue({ data.keys.panic, "Toggle" }) end)
		end
		if type(data.profile) == "string" then
			S.Profile = data.profile
		end

		Core.Refresh()
		Core.ApplyStyle()
		if syncUI then syncUI() end
		if not silent then Library:Notify("โหลดค่าแล้ว (เกมนี้)", 3) end
	end

	function M.Unload()
		if Library.Unloaded then return end
		Library.Unloaded = true
		pcall(Core.Destroy)
		if Library.MenuToggleConnection then
			pcall(function() Library.MenuToggleConnection:Disconnect() end)
		end
		local holder = Window.Holder
		if holder and holder.Parent then
			pcall(function() holder.Parent:Destroy() end)
		end
		genv.__vx_gui = nil
	end

	------------------------------------------------------------------ info
	local AboutL = TInfo:AddLeftGroupbox("Hotkeys")
	AboutL:AddLabel("RightShift = เปิด-ปิดเมนู")
	AboutL:AddLabel("Z = เปิด-ปิด Enemy Chams")
	AboutL:AddLabel("Delete = Panic (ซ่อนทุกอย่าง)")
	AboutL:AddLabel("ปิดเมนูแล้วสคริปต์ยังทำงานปกติ")
	AboutL:AddBlank(6)
	AboutL:AddButton("Unload ทั้งหมด", function() M.Unload() end)

	local AboutR = TInfo:AddRightGroupbox("Build")
	AboutR:AddLabel("engine v8.1 · ui Linoria")
	AboutR:AddLabel("skeleton · humanizer · panic")
	AboutR:AddLabel("adaptive budget · auto-config")

	---------------------------------------------------- Thai font enforcement
	local FACE
	pcall(function() FACE = Font.fromName("Sarabun") end)
	if FACE then
		local function fixFonts()
			local root = Window.Holder and Window.Holder.Parent
			if not root or not root.Parent then return end
			for _, d in ipairs(root:GetDescendants()) do
				if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
					if d.FontFace ~= FACE then
						pcall(function() d.FontFace = FACE end)
					end
				end
			end
		end
		fixFonts()
		task.spawn(function()
			while not Library.Unloaded do
				if Window.Holder and Window.Holder.Visible then fixFonts() end
				task.wait(0.35)
			end
		end)
	end

	pcall(function()
		if type(isfile) == "function" and type(readfile) == "function" and isfile(PLACE_FILE) then
			M.Load(true)
		end
	end)

	Library:Notify("โหลดแล้ว · กด RightShift เพื่อเปิดเมนู", 5)

	genv.__vx_menu = { Save = M.Save, Load = M.Load, Unload = M.Unload, sync = syncUI }

	return M
end)()

return Menu
end)
if not _ok then
	local _e = tostring(_err)
	local _g = (getgenv and getgenv()) or _G
	_g.__vx_err = _e
end
