@echo off
title Dimah ERP - Hikvision sync preview
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0start_hikvision_sync.ps1" -Once
echo.
pause
