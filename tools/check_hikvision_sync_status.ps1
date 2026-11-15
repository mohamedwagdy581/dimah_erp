$ErrorActionPreference = 'Stop'
$task = Get-ScheduledTask -TaskName 'Dimah ERP Hikvision Attendance' -ErrorAction SilentlyContinue
if ($null -eq $task) { Write-Host 'Automatic startup is not installed. Run setup_hikvision_autostart.cmd.'; exit 0 }
Write-Host ('Scheduled task: ' + $task.State)
$statusPath = Join-Path $env:LOCALAPPDATA 'DimahERP\HikvisionSync\status.json'
if (Test-Path -LiteralPath $statusPath) {
    try {
        $status = [IO.File]::ReadAllText($statusPath) | ConvertFrom-Json
        Write-Host ('Last status: ' + $status.status)
        Write-Host ('Updated (UTC): ' + $status.time_utc)
        if ($null -ne $status.details) { Write-Host ($status.details | ConvertTo-Json -Compress) }
        if ([DateTimeOffset]::UtcNow - [DateTimeOffset]::Parse($status.time_utc) -gt [TimeSpan]::FromMinutes(5)) {
            Write-Host 'Status is older than 5 minutes. Check that the task is running and the network is connected.' -ForegroundColor Yellow
        }
        if ($status.status -in @('sync_failed', 'startup_failed')) {
            Write-Host 'Check network/device and ERP credentials. If passwords changed, run setup again.' -ForegroundColor Yellow
        }
    } catch { Write-Host 'Status is being updated. Run this check again.' }
} else { Write-Host 'Waiting for the first sync. Run this check again in one minute.' }
