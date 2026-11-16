@echo off
setlocal EnableExtensions
cd /d "%~dp0"
if not exist "%~dp0SimpMusic-Diagnose.ps1" (
    echo ERROR: SimpMusic-Diagnose.ps1 not found in this folder.
    pause
    exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0SimpMusic-Diagnose.ps1"
echo.
echo Diagnostic completed. Check SimpMusic-Startup-Diagnostic.txt.
pause
