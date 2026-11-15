@echo off
title Dimah ERP - Automatic attendance status
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0check_hikvision_sync_status.ps1"
echo.
pause
