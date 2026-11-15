@echo off
title Dimah ERP - Stop automatic attendance
powershell.exe -NoProfile -Command "$ErrorActionPreference='Stop'; Disable-ScheduledTask -TaskName 'Dimah ERP Hikvision Attendance' | Out-Null; Stop-ScheduledTask -TaskName 'Dimah ERP Hikvision Attendance'; Write-Host 'Automatic attendance stopped and disabled. Run setup again to re-enable.'"
echo.
pause
