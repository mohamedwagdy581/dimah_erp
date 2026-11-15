@echo off
title Dimah ERP - Hikvision automatic attendance
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0start_hikvision_sync.ps1" -Commit
echo.
pause
