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
