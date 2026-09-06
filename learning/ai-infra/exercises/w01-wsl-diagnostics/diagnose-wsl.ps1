#Requires -RunAsAdministrator
# Local diagnostics only. Run as the Windows user who owns the Ubuntu distro.
# wsl.wprp source: https://github.com/microsoft/WSL/blob/master/diagnostics/wsl.wprp
$ErrorActionPreference = 'Stop'
$env:WSL_UTF8 = '1'
$logDir = Join-Path $PSScriptRoot ('logs-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
New-Item -ItemType Directory -Path $logDir | Out-Null
Start-Transcript -Path (Join-Path $logDir 'summary.txt') | Out-Null
$tracing = $false

function Invoke-WslCheck {
    param([string]$Label, [string[]]$WslArguments)
    $stdout = Join-Path $logDir ($Label + '.txt')
    $stderr = Join-Path $logDir ($Label + '-stderr.txt')
    $process = Start-Process -FilePath "$env:WINDIR\System32\wsl.exe" -ArgumentList $WslArguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    if (-not $process.WaitForExit(30000)) {
        Stop-Process -Id $process.Id -ErrorAction SilentlyContinue
        Write-Warning "$Label timed out after 30 seconds; only its wsl.exe client was stopped."
    } else {
        $process.WaitForExit()
        Write-Host "$Label exit code: $($process.ExitCode)"
    }
    Get-Content -LiteralPath $stdout,$stderr -Encoding UTF8
}

try {
    Get-Date -Format o
    Get-CimInstance Win32_OperatingSystem | Select-Object Caption,Version,LastBootUpTime | Format-List
    Get-Service WslService,vmcompute,hns | Format-Table Name,Status
    Invoke-WslCheck 'version' @('--version')
    Invoke-WslCheck 'distributions' @('--list','--verbose')
    & netsh.exe winsock show catalog | Out-File (Join-Path $logDir 'winsock.txt') -Encoding UTF8
    & wpr.exe -start ((Join-Path $PSScriptRoot 'wsl.wprp') + '!WSL') -filemode
    $tracing = ($LASTEXITCODE -eq 0)
    if (-not $tracing) { Write-Warning 'Trace did not start. Existing trace sessions will not be cancelled.' }
    Invoke-WslCheck 'shutdown' @('--shutdown')
    Restart-Service -Name WslService -ErrorAction Stop
    Invoke-WslCheck 'ubuntu-start' @('-d','Ubuntu','--exec','/bin/true')
    $eventLogs = @(
        'Microsoft-Windows-Hyper-V-Compute-Admin',
        'Microsoft-Windows-Hyper-V-Compute-Operational',
        'Microsoft-Windows-Host-Network-Service-Admin',
        'Microsoft-Windows-Host-Network-Service-Operational'
    )
    foreach ($eventLog in $eventLogs) {
        try {
            Get-WinEvent -FilterHashtable @{LogName=$eventLog; StartTime=(Get-Date).AddMinutes(-30)} -MaxEvents 50 -ErrorAction Stop |
                Select-Object TimeCreated,Id,LevelDisplayName,Message |
                Format-List | Out-File (Join-Path $logDir ($eventLog + '.txt')) -Encoding UTF8 -Width 240
        } catch { Write-Warning "$eventLog : $_" }
    }
} finally {
    if ($tracing) {
        & wpr.exe -stop (Join-Path $logDir 'logs.etl')
        if ($LASTEXITCODE -ne 0) { Write-Warning 'Trace save failed; see the wpr output above.' }
    }
    Write-Host "Logs saved in: $logDir"
    Stop-Transcript | Out-Null
}
