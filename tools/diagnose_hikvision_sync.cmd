@echo off
title Dimah ERP - Attendance diagnosis
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0diagnose_hikvision_sync.ps1" -Unattended
echo.
pause
