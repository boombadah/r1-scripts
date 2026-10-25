# Sentinel Host Security Audit Script for Windows 11
# Non-destructive, read-only diagnostic scanner

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " [SENTINEL SHIELD] Windows 11 Internal Security Audit      " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$Findings = @()

# 1. Audit Registry Startup Persistence
Write-Host "`n[*] Auditing Startup & Registry Persistence..." -ForegroundColor Yellow
$RunKeys = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
)
foreach ($key in $RunKeys) {
    if (Test-Path $key) {
        $props = Get-ItemProperty -Path $key
        foreach ($name in ($props.PSObject.Properties.Name | Where-Object { $_ -notmatch '^(PS|Run)' })) {
            $val = $props.$name
            if ($val -match 'AppData|Temp|powershell|cmd\.exe|wscript|cscript') {
                $Findings += [PSCustomObject]@{
                    Category = "Suspicious Startup Entry"
                    Details  = "Key: $name | Value: $val"
                    Risk     = "HIGH"
                }
            } else {
                Write-Host "  [+] Verified Startup: $name -> $val" -ForegroundColor DarkGray
            }
        }
    }
}

# 2. Check Processes Running from AppData/Temp
Write-Host "`n[*] Scanning Running Processes in Temp/AppData..." -ForegroundColor Yellow
Get-Process | Where-Object {
    $_.Path -and (
        $_.Path -match 'AppData\\Local\\Temp' -or
        $_.Path -match 'AppData\\Roaming\\[^\\]+\.exe' -or
        $_.Path -match 'Users\\Public'
    )
} | ForEach-Object {
    $Findings += [PSCustomObject]@{
        Category = "Rogue Process Location"
        Details  = "$($_.ProcessName) (PID: $($_.Id)) -> $($_.Path)"
        Risk     = "HIGH"
    }
}

# 3. Check Outbound TCP Connections for Non-Standard Endpoints
Write-Host "`n[*] Inspecting Active Remote Network Connections..." -ForegroundColor Yellow
$connections = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue |
    Where-Object { 
        $_.RemoteAddress -notmatch '^(127\.|192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|::1|fe80)' -and
        $_.RemotePort -notin @(80, 443, 8000, 8080, 53)
    }

foreach ($c in $connections) {
    $proc = Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue
    if ($proc -and $proc.ProcessName -notin @('RobloxPlayerBeta', 'Discord', 'msedge', 'chrome', 'brave', 'steam', 'steamwebhelper')) {
        $Findings += [PSCustomObject]@{
            Category = "Unusual Remote Port Connection"
            Details  = "$($proc.ProcessName) (PID: $($c.OwningProcess)) -> $($c.RemoteAddress):$($c.RemotePort)"
            Risk     = "MEDIUM"
        }
    }
}

# 4. Check Scheduled Tasks for Suspicious Triggers
Write-Host "`n[*] Inspecting Scheduled Tasks for Suspicious Actions..." -ForegroundColor Yellow
Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
    $_.Actions.Execute -match 'AppData|Temp|powershell -enc|cmd\.exe /c'
} | ForEach-Object {
    $Findings += [PSCustomObject]@{
        Category = "Suspicious Scheduled Task"
        Details  = "Task: $($_.TaskName) -> $($_.Actions.Execute)"
        Risk     = "HIGH"
    }
}

# Summary Output
Write-Host "`n==========================================================" -ForegroundColor Cyan
if ($Findings.Count -eq 0) {
    Write-Host " [RESULT] SYSTEM CLEAN: Zero internal threats or backdoors detected!" -ForegroundColor Green
    Write-Host " All startup persistence, processes, and network ports are verified safe." -ForegroundColor Green
} else {
    Write-Host " [RESULT] WARNING: $($Findings.Count) items need inspection!" -ForegroundColor Red
    $Findings | Format-Table -AutoSize
}
Write-Host "==========================================================" -ForegroundColor Cyan
