--[[==========================================================================
    VOXEL RADAR — remote loader
    --------------------------------------------------------------------------
    ใช้บรรทัดเดียวใน executor:

        loadstring(game:HttpGet("https://raw.githubusercontent.com/boombadah/r1-scripts/main/Radar_v8/loader.lua"))()

    หรือถ้าอยากโหลดตัวสคริปต์ตรง ๆ (ไม่ผ่าน loader / ไม่มี cache):

        loadstring(game:HttpGet("https://raw.githubusercontent.com/boombadah/r1-scripts/main/Radar_v8/VoxelRadar_v8.lua"))()

    loader ตัวนี้เพิ่มให้:
      * โหลดจากเน็ตก่อนเสมอ (ได้เวอร์ชันล่าสุด) — 1-2 วินาที
      * cache ลงเครื่อง (VXR8/cache.lua) ไว้ fallback เมื่อเน็ตหลุด
      * getgenv().VXR_OFFLINE = true = บังคับใช้ cache (ไม่ยิงเน็ตเลย)
      * กัน http 200 ที่ได้ HTML (เช่นหน้า 404) ด้วยการเช็กขนาด/หัวไฟล์
    ==========================================================================]]

local SRC_URL = "https://raw.githubusercontent.com/boombadah/r1-scripts/main/Radar_v8/VoxelRadar_v8.lua"
local CACHE   = "VXR8/cache.lua"

-- ปกติจะโหลดจากเน็ตก่อนเสมอ (ได้เวอร์ชันล่าสุด) แล้วค่อย fallback ไป cache
-- ถ้าอยากบังคับใช้ cache (เน็ตช้า/ออฟไลน์): getgenv().VXR_OFFLINE = true ก่อนเรียก loader
local OFFLINE = (getgenv and getgenv().VXR_OFFLINE) == true

local function hasFileApi()
	return type(readfile) == "function" and type(writefile) == "function" and type(isfile) == "function"
end

local function isValid(src)
	return type(src) == "string" and #src > 20000 and src:sub(1, 2) == "--"
end

local function readCache()
	if not hasFileApi() then return nil end
	local ok, src = pcall(function() return readfile(CACHE) end)
	if ok and isValid(src) then return src end
	return nil
end

local function writeCache(src)
	if not hasFileApi() then return end
	pcall(function()
		if type(makefolder) == "function" and type(isfolder) == "function" and not isfolder("VXR8") then
			makefolder("VXR8")
		end
		writefile(CACHE, src)
	end)
end

local src = nil

if OFFLINE then
	src = readCache()
end

if not src then
	local ok, res = pcall(function() return game:HttpGet(SRC_URL) end)
	if ok and isValid(res) then
		src = res
		writeCache(src)
	else
		src = readCache()
		if not src then
			warn("[radar] ดาวน์โหลดไม่สำเร็จ และไม่มี cache ในเครื่อง: " .. tostring(res))
			return
		end
	end
end

local chunk, err = loadstring(src, "vx_loader")
if not chunk then
	warn("[radar] compile error: " .. tostring(err))
	return
end

chunk()
