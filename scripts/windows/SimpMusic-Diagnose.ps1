$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$exe = Join-Path $root 'SimpMusic.exe'
$cfg = Join-Path $root 'app\SimpMusic.cfg'
$runtime = Join-Path $root 'runtime\bin\server\jvm.dll'
$report = Join-Path $root 'SimpMusic-Startup-Diagnostic.txt'
$env:SKIKO_RENDER_API = 'SOFTWARE'

function Write-Report([string]$message) {
    $message | Tee-Object -FilePath $report -Append
}

'====== SimpMusic Startup Diagnostic ======' | Out-File -FilePath $report -Encoding utf8
Write-Report ('Time: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz'))
Write-Report ('OS: ' + [Environment]::OSVersion.VersionString)
Write-Report ('PowerShell: ' + $PSVersionTable.PSVersion.ToString())
Write-Report ('SimpMusic.exe: ' + (Test-Path -LiteralPath $exe))
Write-Report ('App config: ' + (Test-Path -LiteralPath $cfg))
Write-Report ('Bundled JVM: ' + (Test-Path -LiteralPath $runtime))
Write-Report ('Graphics: SOFTWARE')

if (-not (Test-Path -LiteralPath $exe)) {
    Write-Report 'ERROR: SimpMusic.exe is missing. Extract the full application first.'
    return
}
if (-not (Test-Path -LiteralPath $cfg) -or -not (Test-Path -LiteralPath $runtime)) {
    Write-Report 'ERROR: Required application files are missing. Extract the entire portable ZIP.'
    return
}
try {
    $old = @(Get-Process -Name 'SimpMusic' -ErrorAction SilentlyContinue)
    Write-Report ('Old SimpMusic processes: ' + $old.Count)
    $old | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Write-Host 'Launching SimpMusic and checking the main window...'
    $p = Start-Process -FilePath $exe -WorkingDirectory $root -PassThru -ErrorAction Stop
    Write-Report ('Launched PID: ' + $p.Id)
    Start-Sleep -Seconds 12
    $running = @(Get-Process -Name 'SimpMusic' -ErrorAction SilentlyContinue)
    Write-Report ('Processes after 12 sec: ' + $running.Count)
    foreach ($item in $running) {
        Write-Report ('PID=' + $item.Id + '; MainWindowHandle=' + $item.MainWindowHandle + '; MainWindowTitle=' + $item.MainWindowTitle)
        if ($item.MainWindowHandle -eq 0) {
            Write-Report 'INFO: This process has no main window handle (may still be starting or running in the tray).'
        }
    }
    if ($running.Count -eq 0) {
        Write-Report 'ERROR: SimpMusic terminated or could not stay running.'
    }
} catch {
    Write-Report ('STARTUP ERROR: ' + $_.Exception.GetType().FullName)
    Write-Report ('MESSAGE: ' + $_.Exception.Message)
}
$logs = Join-Path $HOME '.simpmusic\logs'
Write-Report ('Existing application logs folder: ' + (Test-Path -LiteralPath $logs))
if (Test-Path -LiteralPath $logs) {
    $recent = @(Get-ChildItem -LiteralPath $logs -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 8)
    foreach ($f in $recent) {
        Write-Report ('Log file: ' + $f.Name + '; modified: ' + $f.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss') + '; bytes: ' + $f.Length)
    }
}
Write-Report 'END. Do not publish private application logs without reviewing them for credentials.'
Write-Host 'Done. The report contains startup status, not browser cookies.'
Write-Host ('Report file: ' + $report)
