@echo off
setlocal

mkdir C:\PrintSvc 2>nul
copy /Y C:\OEM\sync-printsvc.ps1 C:\PrintSvc\sync-printsvc.ps1 >nul

echo @echo off> C:\Users\Public\Desktop\Sync-PrintSvc.bat
echo powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\PrintSvc\sync-printsvc.ps1>> C:\Users\Public\Desktop\Sync-PrintSvc.bat
echo pause>> C:\Users\Public\Desktop\Sync-PrintSvc.bat

schtasks /Create /TN "SyncPrintSvc" /SC ONSTART /RU SYSTEM /RL HIGHEST /TR "powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\PrintSvc\sync-printsvc.ps1" /F >nul

powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\PrintSvc\sync-printsvc.ps1
exit /b 0
