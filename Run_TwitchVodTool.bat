@echo off
setlocal
title Twitch VOD ^& Chat Tool

set "SCRIPT_PATH=%~dp0app\TwitchVodTool.ps1"
if not exist "%SCRIPT_PATH%" (
    echo [ERROR] Script not found at "%SCRIPT_PATH%".
    pause
    exit /b 1
)

where pwsh >nul 2>nul
if %errorlevel% equ 0 (
    pwsh.exe -STA -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"
) else (
    powershell.exe -STA -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"
)

if %errorlevel% neq 0 (
    echo.
    pause
)