# =====================================================================
#  VOXEL RADAR v8  --  build single-file script
#  ประกอบ: head + engine + Linoria (patched) + menu  ->  VoxelRadar_v8.lua
# =====================================================================
$ErrorActionPreference = 'Stop'

$here    = Split-Path -Parent $MyInvocation.MyCommand.Path
$root    = Split-Path -Parent $here
$libPath = Join-Path $root 'UI_Libraries\Linoria - Library.lua'

function Read-Lf([string]$path) {
    $txt = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
    return ($txt -replace "`r`n", "`n")
}

function Patch([string]$src, [string]$old, [string]$new, [string]$label) {
    if (-not $src.Contains($old)) { throw "patch failed -> $label" }
    return $src.Replace($old, $new)
}

$lib = Read-Lf $libPath

# ---------------------------------------------------------------------
# PATCH 1 : ScreenGui -> random name + gethui()/CoreGui + protect_gui
# ---------------------------------------------------------------------
$p1old = @'
local ScreenGui = Instance.new('ScreenGui');
ProtectGui(ScreenGui);

ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
ScreenGui.Parent = CoreGui;
'@

$p1new = @'
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
'@
$lib = Patch $lib $p1old $p1new 'ScreenGui parent'

# ---------------------------------------------------------------------
# PATCH 2 : menu toggle connection handle + unloaded guard
# ---------------------------------------------------------------------
$p2old = @'
    InputService.InputBegan:Connect(function(Input, Processed)
        if Input.KeyCode == Enum.KeyCode.RightControl or (Input.KeyCode == Enum.KeyCode.RightShift and (not Processed)) then
            Outer.Visible = not Outer.Visible;
'@

$p2new = @'
    Library.MenuToggleConnection = InputService.InputBegan:Connect(function(Input, Processed)
        if Library.Unloaded or (not Outer.Parent) then return end;
        if Input.KeyCode == Enum.KeyCode.RightShift and (not Processed) then
            Outer.Visible = not Outer.Visible;
'@
$lib = Patch $lib $p2old $p2new 'menu keybind'

# ---------------------------------------------------------------------
# PATCH 3 : stop the software cursor loop on unload
# ---------------------------------------------------------------------
$p3old = '            while Outer.Visible do'
$p3new = '            while Outer.Visible and Outer.Parent and (not Library.Unloaded) do'
$lib = Patch $lib $p3old $p3new 'cursor loop'

# ---------------------------------------------------------------------
# PATCH 3b : Thai-capable font face for every text object the library makes
# ---------------------------------------------------------------------
$p5old = @'
    for Property, Value in next, Properties do
        _Instance[Property] = Value;
    end;

    return _Instance;
end;
'@

$p5new = @'
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
'@
$lib = Patch $lib $p5old $p5new 'thai font face'

# ---------------------------------------------------------------------
# PATCH 4 : stop the rainbow RenderStepped loop on unload
# ---------------------------------------------------------------------
$p4old = @'
    while RenderStepped:Wait() do
        if tick() - Tick >= (1 / 60) then
'@

$p4new = @'
    while RenderStepped:Wait() do
        if Library.Unloaded or (not ScreenGui.Parent) then break end;
        if tick() - Tick >= (1 / 60) then
'@
$lib = Patch $lib $p4old $p4new 'rainbow loop'

# ---------------------------------------------------------------------
# COMPOSE
# ---------------------------------------------------------------------
$head   = Read-Lf (Join-Path $here 'src\head.lua')
$engine = Read-Lf (Join-Path $here 'src\engine.lua')
$menu   = Read-Lf (Join-Path $here 'src\menu.lua')

$menuBlock = $menu

$out = $head + "`n" +
       "local _ok, _err = pcall(function()`n" +
       $engine + "`n" +
       "-- =====================================================================" + "`n" +
       "-- UI LIBRARY : Linoria (embedded, patched for CoreGui protect + unload)" + "`n" +
       "-- =====================================================================" + "`n" +
       "local Library = (function()`n" +
       $lib + "`n" +
       "end)()`n" + "`n" +
       "-- =====================================================================" + "`n" +
       "-- MENU" + "`n" +
       "-- =====================================================================" + "`n" +
       $menuBlock + "`n" +
       "end)`n" +
       "if not _ok then" + "`n" +
       "	local _e = tostring(_err)" + "`n" +
       "	local _g = (getgenv and getgenv()) or _G" + "`n" +
       "	_g.__vx_err = _e" + "`n" +
       "end`n"

$target = Join-Path $here 'VoxelRadar_v8.lua'
[System.IO.File]::WriteAllText($target, $out, (New-Object System.Text.UTF8Encoding($false)))

$size = (Get-Item $target).Length
Write-Host "built  -> $target"
Write-Host "size   -> $([math]::Round($size / 1KB, 1)) KB"
Write-Host "lines  -> $((Get-Content $target).Count)"
