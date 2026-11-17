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