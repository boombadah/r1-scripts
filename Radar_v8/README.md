# VOXEL RADAR v8.1

ระบบ Enemy Radar / Chams เวอร์ชันเขียนใหม่ทั้งตัว ใช้ **Linoria** เป็น UI (จาก `UI_Libraries/Linoria - Library.lua`) ฝังเข้าไปในไฟล์เดียว ไม่ต้องโหลดอะไรเพิ่ม ไม่มี HTTP request

**ไฟล์ที่ต้องรัน:** [`VoxelRadar_v8.lua`](VoxelRadar_v8.lua) (~129 KB)

---

## ของใหม่ใน v8.1

| ระบบ | รายละเอียด |
|---|---|
| **Skeleton ESP** | โครงกระดูกจากชื่อ part R15/R6 → `AnimationConstraint` → `Motor6D` (รองรับ rig ใหม่ของ Voxel Wars ที่ไม่มี Motor6D) วาดด้วย `Drawing.Line` ล้วน — **ไม่มี Instance ใน DataModel** |
| **Panic kill-switch** | ปุ่ม `Delete` (เปลี่ยนได้) — ซ่อน Highlight + Drawing + GUI ทั้งหมดในเฟรมเดียว |
| **Humanizer** | สุ่ม "กะพริบ" ปิด Chams 0.15–0.6 วิ ทุก 35–90 วิ (ปรับได้) — pattern ไม่นิ่งให้ telemetry เก็บ |
| **Profile Legit / Rage** | สลับชุดค่าเดียวจบ + sync UI อัตโนมัติ |
| **Auto-config ตาม PlaceId** | เข้า Voxel Wars ครั้งแรกได้โหมด Legit อัตโนมัติ |
| **Adaptive budget** | FPS ต่ำกว่า 45 → ลดจำนวน Chams/Skeleton อัตโนมัติ, กลับมาเมื่อ FPS > 55 |
| **Dot-product cull** | ข้ามการ projrect เป้าที่อยู่หลังกล้อง (ประหยัด math ต่อเฟรม) |
| **Config แยกตามเกม** | `VXR8/place_<PlaceId>.json` มาก่อน, fallback `VXR8/settings.json` |
| **Debug state** | `getgenv().__vx_dbg` = enemies / chams / bars / lines / fps / scale / blink |

## API สำหรับเรียกจากสคริปต์อื่น

```lua
local api  = getgenv().__vx_api     -- panic(on), profile("Legit"/"Rage"), refresh(), destroy()
local menu = getgenv().__vx_menu    -- Save(), Load(silent), Unload(), sync()
local dbg  = getgenv().__vx_dbg     -- สถานะสด
```


---

## วิธีใช้

```lua
-- paste ทั้งไฟล์ลง executor แล้ว Execute
-- หรือถ้าใช้ MCP / file runner:
execute-file Radar_v8/VoxelRadar_v8.lua
```

| ปุ่ม | การทำงาน |
|---|---|
| `RightShift` | เปิด-ปิดเมนู |
| `Z` | เปิด-ปิด Enemy Chams (เปลี่ยนได้ในเมนู) |
| `Delete` | Panic — ซ่อนทุกอย่างทันที (เปลี่ยนได้ในเมนู) |
| ปุ่ม `Unload ทั้งหมด` (แท็บ Info) | ถอดทุกอย่างออกจาก memory |

ปิดเมนูแล้วสคริปต์ยังทำงานปกติ — เมนูแค่ซ่อน

---

## สิ่งที่แก้จาก v7.0

### บั๊กที่ถูกแก้

| ปัญหาใน v7 | การแก้ใน v8 |
|---|---|
| `Camera` เก็บค่าไว้ตั้งแต่ต้นไฟล์ — กล้องเปลี่ยนแล้วESP เพี้ยน | อ่าน `Workspace.CurrentCamera` ทุกเฟรม |
| สแกน `Players` + `Workspace.Characters` + `BotRigs` **ทุกเฟรม** | Registry สแกน 4Hz แล้ว render ใช้ cache — CPU ลดลงมาก |
| `activeHighlights` ค้าง instance ที่ถูก Destroy ไปแล้ว | ใช้ Highlight pool ขนาดคงที่ + `Adornee` reassign ไม่มี leak |
| ปิด Chams แล้วแถบเลือดดับไปด้วย | แยก toggle กันสนิท |
| `slot.Text.Text` ถูกเขียนใหม่ทุกเฟรม (string alloc ถี่) | จำกัดอัปเดตข้อความ 10Hz + เช็คค่าซ้ำก่อนเขียน |
| `Recoil` ใช้ `Camera.CFrame *` ทับ camera script → ภาพสั่น | ใช้ `mousemoverel` ก่อน (hardware-level) ถ้าไม่มีค่อย fallback camera |
| `FPS Boost` ปิด ParticleEmitter ทั้งแมพแล้วคืนค่าไม่ได้ | เก็บ snapshot ไว้ คืนค่าได้ทั้งหมดตอนปิด/Unload |
| รันซ้ำแล้ว Highlight / GUI เก่าค้าง | purge ผ่าน `genv.__vx` + `genv.__vx_gui` + guard `not Outer.Parent` ใน Linoria |
| `Enum.TeamColor.White` เทียบค่า enum ตรง ๆ (เสี่ยง error) | เทียบผ่าน `.Name` |
| Health bar พังเมื่อ rig ไม่มี Humanoid/Health | fallback attribute → default 100 |

### เรื่อง anti-detect (จงใจทำแบบนี้)

- **ไม่มี `print` เลย** — console สะอาด ไม่มีร่องรอย log
- **ชื่อ instance สุ่มทุก session** — ไม่มีคำว่า `Chams` / `Sentinel` / `Radar` อยู่ใน DataModel (เหลือเฉพาะใน purge list ของ v7)
- **Highlight อยู่ใน `Lighting` ไม่ใช่ `Workspace`** — สคริปต์ตรวจโกงที่ยิง `Workspace:GetDescendants()` มองไม่เห็น และไม่มีการฝัง Highlight ใต้ตัวละคร (ซึ่งเป็นจุดที่เช็คง่ายที่สุด)
- **GUI อยู่ใน `gethui()` / `CoreGui` + `protect_gui`** — LocalScript ของเกมอ่าน `CoreGui` ไม่ได้
- **Drawing ใช้ทำแถบเลือดเท่านั้น** — ไม่มี Instance ใหม่ใน Workspace ต่อเป้าหมาย
- **จำนวน Instance คงที่** — Highlight pool สร้างครั้งเดียวตาม slider (default 32) ไม่ผันผวนตามจำนวนศัตรู
- **ไม่มี `_G` pollution** — เหลือแค่ key เดียว (`__vx`) ไว้ purge รอบถัดไป
- **target scan 4Hz** — ไม่มี loop หนัก ๆ ที่ทำให้ frame time ผิดปกติ

สิ่งที่ยังตรวจจับได้: **พฤติกรรม** — กดยิงข้ามกำแพง, เลี้ยวเข้าหาคนที่มองไม่เห็น, recoil ที่นิ่งเกินมนุษย์ การออกแบบสคริปต์ไม่สามารถซ่อนสิ่งนี้ได้

---

## แท็บในเมนู

**Combat** — เปิด/ปิด Chams, Health Bars, keybind, จำนวน Chams สูงสุด (1–64), ระยะ Chams, ระยะแถบเลือด

**Visual** — สี Chams, ความโปร่งแสง Fill/Outline, โหมด `XRay` (ทะลุกำแพง) / `Glow` (เห็นเฉพาะในสายตา), เปิด/ปิดชื่อ-เลขเลือด-ระยะ

**Team** — กฎแยกศัตรู 3 แบบ:
- `Auto` — อ่าน `Player.Team` → attribute `Team` → `CharacterName` faction (BloxStrike CT/T) → TeamColor ถ้าไม่มีข้อมูลเลยจะนับทุกคนเป็นศัตรู (เกม FFA ใช้ตัวนี้)
- `FFA` — ทุกคนคือศัตรู
- `Strict` — ไม่มั่นใจ = ไม่ไฮไลต์ (กันเพื่อนโดนติด)

พร้อม toggle บอท/Rig และ toggle สแกน Model ทั้ง Workspace (ปิดได้ถ้าเกมมี prop แปลก ๆ)

**Misc** — Recoil Dampener (ความแรง/ความนุ่ม), Potato FPS Mode, Save/Load config (`VXR8/settings.json`)

**Info** — hotkeys + Unload

---

## โครงสร้างโปรเจกต์

```
Radar_v8/
├── VoxelRadar_v8.lua      <- ไฟล์ที่รัน (build แล้ว)
├── build.ps1              <- ประกอบไฟล์ + patch Linoria
├── selene.toml / executor.yml
└── src/
    ├── head.lua           <- banner + stealth contract
    ├── engine.lua         <- registry, chams pool, bars, recoil, fps, purge
    └── menu.lua           <- Linoria UI ทั้งหมด
```

แก้ engine/menu แล้ว build ใหม่:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Radar_v8\build.ps1
```

`build.ps1` จะ patch Linoria 4 จุดระหว่างประกอบ:

1. `ScreenGui` → ชื่อสุ่ม + `gethui()`/`CoreGui` + `IgnoreGuiInset`
2. เก็บ connection ของปุ่มเปิดเมนูไว้ disconnect ตอน Unload + guard `Outer.Parent`
3. loop cursor ของ Linoria หยุดเมื่อ Unload/GUI ถูกทำลาย
4. loop rainbow ของ Linoria หยุดเมื่อ GUI ถูกทำลาย (กันสคริปต์เก่าวิ่งค้างหลังรันซ้ำ)

---

## หมายเหตุ

- ตัวไฟล์ผ่าน `selene` (0 errors, 0 parse errors) และ `stylua` parse ผ่านทั้งไฟล์ แต่ยังไม่ได้รันในเกมจริงเพราะยังไม่มี client เชื่อมต่อ — รันแล้วมี error อะไร ส่ง console มาได้เลย
- ถ้า executor ไม่มี `Drawing` ระบบแถบเลือดจะปิดตัวเองเงียบ ๆ ส่วน Chams ยังทำงาน
- `Save/Load` ต้องมี `writefile` (executor ส่วนใหญ่มี; ถ้าไม่มีจะขึ้น notify บอก)
