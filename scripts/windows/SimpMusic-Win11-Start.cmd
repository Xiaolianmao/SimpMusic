@echo off
setlocal EnableExtensions
cd /d "%~dp0"
if not exist "%~dp0SimpMusic.exe" (
    echo ERROR: SimpMusic.exe not found. Copy these files beside SimpMusic.exe.
    pause
    exit /b 1
)
echo Closing previously running SimpMusic.exe processes...
taskkill /F /IM SimpMusic.exe >nul 2>&1
timeout /T 2 /NOBREAK >nul
set "SKIKO_RENDER_API=SOFTWARE"
echo Starting SimpMusic with software rendering...
start "" /D "%~dp0" "%~dp0SimpMusic.exe"
timeout /T 8 /NOBREAK >nul
echo If no window appears, run SimpMusic-Diagnose.cmd.
pause
