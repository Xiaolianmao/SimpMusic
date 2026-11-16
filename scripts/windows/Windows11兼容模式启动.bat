@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"
if not exist "SimpMusic.exe" (
  echo [ERROR] Please place this file next to SimpMusic.exe.
  pause
  exit /b 1
)
echo SimpMusic Windows 11 compatible startup
echo Closing existing SimpMusic processes...
taskkill /IM SimpMusic.exe /F >nul 2>&1
timeout /t 2 /nobreak >nul
set "SKIKO_RENDER_API=SOFTWARE"
echo Using software-based graphics renderer.
start "" "%~dp0SimpMusic.exe"
timeout /t 6 /nobreak >nul
echo If no window appears, run the diagnostic starter.
pause
