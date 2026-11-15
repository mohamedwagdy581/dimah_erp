@echo off
title Dimah ERP - Hikvision event sample
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0check_hikvision_events.ps1"
echo.
pause
