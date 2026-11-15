@echo off
title Dimah ERP - Hikvision connection check
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0check_hikvision_connection.ps1"
echo.
pause
