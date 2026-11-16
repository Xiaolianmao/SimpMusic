@echo off
setlocal EnableExtensions
cd /d "%~dp0"
if not exist "%~dp0SimpMusic.exe" (
  echo ERROR: SimpMusic.exe was not found.
  pause
  exit /b 1
)
set "PROXY_PORT=%~1"
if "%PROXY_PORT%"=="" set "PROXY_PORT=7897"
set "http_proxy=http://127.0.0.1:%PROXY_PORT%"
set "https_proxy=http://127.0.0.1:%PROXY_PORT%"
set "HTTP_PROXY=http://127.0.0.1:%PROXY_PORT%"
set "HTTPS_PROXY=http://127.0.0.1:%PROXY_PORT%"
set "no_proxy=127.0.0.1,localhost,::1"
set "NO_PROXY=127.0.0.1,localhost,::1"
set "SKIKO_RENDER_API=SOFTWARE"
echo SimpMusic Windows 11 proxy-aware native media startup.
echo Proxy: 127.0.0.1:%PROXY_PORT%
echo Closing old SimpMusic processes...
taskkill /F /IM SimpMusic.exe >nul 2>&1
timeout /T 2 /NOBREAK >nul
start "" /D "%~dp0" "%~dp0SimpMusic.exe"
timeout /T 5 /NOBREAK >nul
echo If no sound or cover appears, inspect Clash connections and SimpMusic logs.
pause
