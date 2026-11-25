$ErrorActionPreference = "Stop"

# Tell Windows the QEMU/KVM hardware RTC is in UTC (matches Linux host, prevents S3 RequestTimeTooSkewed)
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" -Name "RealTimeIsUniversal" -Value 1 -Type DWord -ErrorAction SilentlyContinue
Start-Service w32time -ErrorAction SilentlyContinue
w32tm /resync /force 2>$null | Out-Null

$SourceDir = "\\host.lan\Data\print-svc"
$InstallDir = "C:\PrintSvc"
$ServiceName = "PrintSvc"
$ExePath = Join-Path $InstallDir "PrintSvc.exe"

Write-Host "Waiting for $SourceDir..."
$ready = $false
for ($i = 0; $i -lt 30; $i++) {
    if (Test-Path (Join-Path $SourceDir "PrintSvc.exe")) {
        $ready = $true
        break
    }
    Start-Sleep -Seconds 2
}

if (-not $ready) {
    Write-Warning "Source $SourceDir not reachable yet."
    if (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) {
        Start-Service -Name $ServiceName -ErrorAction SilentlyContinue
    }
    exit 0
}

if (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) {
    Write-Host "Stopping $ServiceName..."
    Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

Write-Host "Syncing PrintSvc from $SourceDir to $InstallDir..."
robocopy $SourceDir $InstallDir /E /XF sync-printsvc.ps1 /XD tmp /R:3 /W:2 | Out-Null
if ($LASTEXITCODE -ge 8) {
    throw "robocopy failed with exit code $LASTEXITCODE"
}

if (-not (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue)) {
    Write-Host "Creating Windows service $ServiceName..."
    sc.exe create $ServiceName binPath= "`"$ExePath`"" start= auto | Out-Null
    sc.exe failure $ServiceName reset= 86400 actions= restart/5000/restart/10000/restart/30000 | Out-Null
} else {
    sc.exe config $ServiceName binPath= "`"$ExePath`"" start= auto | Out-Null
}

Write-Host "Starting $ServiceName..."
Start-Service -Name $ServiceName
Write-Host "PrintSvc is running."
