@echo off
title Dimah ERP - Automatic attendance setup
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_hikvision_autostart.ps1"
echo.
pause
