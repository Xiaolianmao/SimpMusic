$ErrorActionPreference = 'Stop'
$base = Split-Path -Parent $MyInvocation.MyCommand.Path
$appDir = Join-Path $base 'app'
$cfg = Join-Path $appDir 'SimpMusic.cfg'
$java = Join-Path $base 'runtime\bin\java.exe'
$log = Join-Path $base 'SimpMusic-启动诊断记录.txt'
$env:SKIKO_RENDER_API = 'SOFTWARE'
$ErrorActionPreference = 'Continue'
try {
    if (-not (Test-Path $java)) { throw 'Missing bundled Java runtime' }
    if (-not (Test-Path $cfg)) { throw 'Missing application configuration' }
    Get-Process -Name 'SimpMusic' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    $classpath = @()
    foreach ($line in [System.IO.File]::ReadAllLines($cfg)) {
        if ($line.StartsWith('app.classpath=')) {
            $classpath += $line.Substring(14).Replace('$APPDIR', $appDir)
        }
    }
    if ($classpath.Count -eq 0) { throw 'Empty Java classpath' }
    $cp = $classpath -join ';'
    Push-Location $base
    Write-Host 'Starting SimpMusic diagnostic mode. Keep this window open.'
    Write-Host ('Diagnostic file: ' + $log)
    & $java '--add-opens=java.base/java.nio=ALL-UNNAMED' '-Dcompose.application.configure.swing.globals=true' "-Dcompose.application.resources.dir=$appDir\resources" "-Dskiko.library.path=$appDir" '-Dskiko.renderApi=SOFTWARE' '-Djpackage.app-version=2.6.0' '-cp' $cp 'com.maxrave.simpmusic.MainKt' 2>&1 | Tee-Object -FilePath $log
    Write-Host ('Process finished. Exit code: ' + $LASTEXITCODE)
    Pop-Location
} catch {
    $errorText = 'Failed to run diagnostics: ' + $_.Exception.Message
    Write-Host $errorText
    $errorText | Out-File -LiteralPath $log -Encoding UTF8 -Append
}
Write-Host 'Review the diagnostic text file if the main window did not appear.'
