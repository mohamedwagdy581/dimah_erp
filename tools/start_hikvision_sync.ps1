param([switch]$Commit, [switch]$Once, [switch]$Unattended)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'hikvision_sync_helpers.ps1')
. (Join-Path $PSScriptRoot 'hikvision_failure_helpers.ps1')
. (Join-Path $PSScriptRoot 'hikvision_device_config.ps1')
$stage = 'startup'
$deviceCredential = $null; $erpCredential = $null
$syncMutex = $null; $ownsMutex = $false
$automaticDirectory = Join-Path $env:LOCALAPPDATA 'DimahERP\HikvisionSync'
function Write-SyncStatus {
    param([string]$Status, $Details = $null)
    if ($Unattended) {
        $statusData = @{ time_utc = [DateTimeOffset]::UtcNow.ToString('o'); status = $Status; details = $Details }
        [IO.File]::WriteAllText((Join-Path $automaticDirectory 'status.json'), ($statusData | ConvertTo-Json -Depth 4), [Text.UTF8Encoding]::new($false))
    }
}
try {
    if ($Unattended -and -not $Commit) { throw 'Unattended mode requires Commit.' }
    if ($Commit) {
        $syncMutex = [Threading.Mutex]::new($false, 'Local\DimahERP_HikvisionSync_Main')
        try { $ownsMutex = $syncMutex.WaitOne(0) } catch [Threading.AbandonedMutexException] { $ownsMutex = $true }
        if (-not $ownsMutex) { throw 'A synchronization process is already running.' }
    }
    Write-Host 'Dimah ERP - Hikvision attendance bridge'
    if ($Commit) { Write-Host 'LIVE: new attendance is sent every 60 seconds. Ctrl+C stops synchronization.' -ForegroundColor Yellow }
    else { Write-Host 'PREVIEW ONLY: no database writes. Credentials stay in this process.' -ForegroundColor Cyan }
    if ($Unattended) {
        $savedCredentials = Import-Clixml -LiteralPath (Join-Path $automaticDirectory 'credentials.xml')
        $deviceCredential = $savedCredentials.Device
        $erpCredential = $savedCredentials.ERP
        if ($deviceCredential -isnot [Management.Automation.PSCredential] -or $erpCredential -isnot [Management.Automation.PSCredential]) { throw 'Invalid saved credentials.' }
    } else {
        $deviceUser = Read-Host 'DEVICE username (empty cancels)'
        if ([string]::IsNullOrWhiteSpace($deviceUser)) { exit 0 }
        $deviceCredential = [Management.Automation.PSCredential]::new($deviceUser, (Read-Host 'DEVICE password' -AsSecureString))
    }
    $directory = Join-Path $PSScriptRoot '..\build\hikvision-sync'
    if ($Unattended) { $directory = $automaticDirectory }
    [IO.Directory]::CreateDirectory($directory) | Out-Null
    $checkpoint = Join-Path $directory 'checkpoint.txt'
    $since = [DateTimeOffset]::UtcNow.AddHours(-24)
    if ($Commit -and (Test-Path -LiteralPath $checkpoint)) {
        $since = [DateTimeOffset]::Parse([IO.File]::ReadAllText($checkpoint), [Globalization.CultureInfo]::InvariantCulture).AddMinutes(-10)
    }
    $headers = $null; $session = $null; $api = $null
    if ($Commit) {
        $values = @{}
        foreach ($line in [IO.File]::ReadAllLines((Join-Path $PSScriptRoot '..\.env'))) {
            if ($line -match '^\s*(SUPABASE_URL|SUPABASE_ANON_KEY)\s*=\s*(.*?)\s*$') {
                $values[$matches[1]] = $matches[2].Trim().Trim('"').Trim("'")
            }
        }
        $api = [Uri]$values['SUPABASE_URL']
        if ($api.Scheme -ne 'https' -or [string]::IsNullOrWhiteSpace($values['SUPABASE_ANON_KEY'])) { throw 'Missing HTTPS Supabase configuration in project .env.' }
        if (-not $Unattended) {
            $erpUser = Read-Host 'ERP HR/admin email (not DEVICE username)'
            $erpCredential = [Management.Automation.PSCredential]::new($erpUser, (Read-Host 'ERP password' -AsSecureString))
        }
        $headers = @{ apikey = $values['SUPABASE_ANON_KEY'] }
    }
    do {
        try {
            Write-SyncStatus 'syncing'
            # Reload only the address. Credentials and checkpoint remain unchanged.
            $stage = 'startup'
            $base = Get-HikvisionBaseUri
            $cache = [Net.CredentialCache]::new()
            $cache.Add($base, 'Digest', $deviceCredential.GetNetworkCredential())
            $end = [DateTimeOffset]::UtcNow
            # Bounded catch-up windows; after an outage do not skip historical windows.
            if ($end -gt $since.AddHours(24)) { $end = $since.AddHours(24) }
            $stage = 'device_read'
            Write-Host ('Reading device: ' + $base.Host)
            $events = @(Read-HikvisionSyncEvents -BaseUri $base -Credentials $cache -Start $since -End $end)
            if (-not $Commit) {
                $preview = @{ checked_at = $end.ToString('o'); event_count = $events.Count; events = $events }
                [IO.File]::WriteAllText((Join-Path $directory 'preview.json'), ($preview | ConvertTo-Json -Depth 5), [Text.UTF8Encoding]::new($false))
                Write-Host ("PREVIEW: {0} events. No writes. Report: build\hikvision-sync\preview.json" -f $events.Count) -ForegroundColor Green
                break
            }
            if ($null -eq $session -or [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() -gt ($session.expires_at - 120)) {
                if ($null -eq $session) {
                    $stage = 'erp_sign_in'
                    $grant = 'password'
                    $body = @{ email = $erpCredential.UserName; password = $erpCredential.GetNetworkCredential().Password }
                } else {
                    $stage = 'erp_refresh'
                    $grant = 'refresh_token'; $body = @{ refresh_token = $session.refresh_token }
                }
                $session = Invoke-RestMethod -Uri ($api.AbsoluteUri.TrimEnd('/') + '/auth/v1/token?grant_type=' + $grant) -Method Post -Headers $headers -ContentType 'application/json' -Body ($body | ConvertTo-Json -Compress) -TimeoutSec 30
                $body = $null
                if ($null -eq $session.expires_at) { $session | Add-Member -NotePropertyName expires_at -NotePropertyValue ([DateTimeOffset]::UtcNow.ToUnixTimeSeconds() + [int]$session.expires_in) }
                $headers.Authorization = 'Bearer ' + $session.access_token
            }
            # Empty batches also allow recently mapped raw events to be replayed.
            $batches = [Math]::Max(1, [Math]::Ceiling($events.Count / 500.0))
            for ($batch = 0; $batch -lt $batches; $batch++) {
                $slice = @($events | Select-Object -Skip ($batch * 500) -First 500)
                $payload = @{ p_events = $slice } | ConvertTo-Json -Depth 5 -Compress
                $stage = 'attendance_rpc'
                $result = Invoke-RestMethod -Uri ($api.AbsoluteUri.TrimEnd('/') + '/rest/v1/rpc/sync_hikvision_attendance') -Method Post -Headers $headers -ContentType 'application/json' -Body $payload -TimeoutSec 60
                Write-Host ('SYNC: ' + ($result | ConvertTo-Json -Compress)) -ForegroundColor Green
                Write-SyncStatus 'sync_success' $result
            }
            # Save only after every page and batch succeeded. Replays are idempotent.
            $stage = 'checkpoint'
            $temporary = Join-Path $directory 'checkpoint.pending'
            [IO.File]::WriteAllText($temporary, $end.ToString('o'))
            Move-Item -LiteralPath $temporary -Destination $checkpoint -Force
            $since = $end.AddMinutes(-10)
        } catch {
            $failure = Get-HikvisionSyncFailure -Failure $_ -Stage $stage
            Write-SyncStatus 'sync_failed' $failure
            # Recover if a refresh token was revoked; next cycle signs in again.
            $session = $null
            if ($null -ne $headers) { $headers.Remove('Authorization') }
            # Never print exception bodies: providers may include credential details.
            Write-Host 'SYNC FAILED: checkpoint preserved. Check device/network, HR login, and installed SQL. Retrying in 60 seconds.' -ForegroundColor Red
            Write-Host ($failure | ConvertTo-Json -Compress) -ForegroundColor Yellow
            if ($Once) { exit 1 }
        }
        if (-not $Once) { Start-Sleep -Seconds 60 }
    } while (-not $Once)
} catch {
    if (Test-Path -LiteralPath $automaticDirectory) { Write-SyncStatus 'startup_failed' (Get-HikvisionSyncFailure -Failure $_ -Stage 'startup') }
    Write-Host 'Cannot start sync. Check project .env and make sure another sync window is not already running.' -ForegroundColor Red
    exit 1
} finally {
    $session = $null; $headers = $null
    if ($null -ne $deviceCredential) { $deviceCredential.Password.Dispose() }
    if ($null -ne $erpCredential) { $erpCredential.Password.Dispose() }
    if ($ownsMutex) { $syncMutex.ReleaseMutex() }
    if ($null -ne $syncMutex) { $syncMutex.Dispose() }
}
