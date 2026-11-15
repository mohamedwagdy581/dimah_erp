param([switch]$Unattended)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'hikvision_sync_helpers.ps1')
. (Join-Path $PSScriptRoot 'hikvision_failure_helpers.ps1')
. (Join-Path $PSScriptRoot 'hikvision_device_config.ps1')
$stage = 'startup'; $device = $null; $erp = $null; $session = $null; $headers = $null
try {
    Write-Host 'READ-ONLY DIAGNOSIS: no attendance writes, no checkpoint changes, no scheduled-task changes.'
    if ($Unattended) {
        $saved = Import-Clixml -LiteralPath (Join-Path $env:LOCALAPPDATA 'DimahERP\HikvisionSync\credentials.xml')
        $device = $saved.Device; $erp = $saved.ERP; $saved = $null
    } else {
        $device = [Management.Automation.PSCredential]::new((Read-Host 'DEVICE username'), (Read-Host 'DEVICE password' -AsSecureString))
        $erp = [Management.Automation.PSCredential]::new((Read-Host 'ERP HR/admin email'), (Read-Host 'ERP password' -AsSecureString))
    }
    if ($device -isnot [Management.Automation.PSCredential] -or $erp -isnot [Management.Automation.PSCredential]) { throw 'Invalid saved credentials.' }
    $base = Get-HikvisionBaseUri
    Write-Host ('Device: ' + $base.Host)
    $cache = [Net.CredentialCache]::new(); $cache.Add($base, 'Digest', $device.GetNetworkCredential())
    $stage = 'device_read'
    $end = [DateTimeOffset]::UtcNow
    $events = @(Read-HikvisionSyncEvents -BaseUri $base -Credentials $cache -Start $end.AddMinutes(-5) -End $end)
    Write-Host ('DEVICE EVENT READ OK: ' + $events.Count + ' events in the last 5 minutes. No names or events printed.')
    $stage = 'startup'; $values = @{}
    foreach ($line in [IO.File]::ReadAllLines((Join-Path $PSScriptRoot '..\.env'))) {
        if ($line -match '^\s*(SUPABASE_URL|SUPABASE_ANON_KEY)\s*=\s*(.*?)\s*$') { $values[$matches[1]] = $matches[2].Trim().Trim('"').Trim("'") }
    }
    $api = [Uri]$values['SUPABASE_URL']
    if ($api.Scheme -ne 'https' -or [string]::IsNullOrWhiteSpace($values['SUPABASE_ANON_KEY'])) { throw 'Missing HTTPS configuration.' }
    $headers = @{ apikey = $values['SUPABASE_ANON_KEY'] }
    $stage = 'erp_sign_in'
    $body = @{email = $erp.UserName; password = $erp.GetNetworkCredential().Password} | ConvertTo-Json -Compress
    $session = Invoke-RestMethod -Uri ($api.AbsoluteUri.TrimEnd('/') + '/auth/v1/token?grant_type=password') -Method Post -Headers $headers -ContentType 'application/json' -Body $body -TimeoutSec 30
    $body = $null
    $headers.Authorization = 'Bearer ' + $session.access_token
    Write-Host 'ERP SIGN-IN OK'
    $stage = 'erp_role'
    $uid = [Uri]::EscapeDataString([string]$session.user.id)
    $actor = @(Invoke-RestMethod -Uri ($api.AbsoluteUri.TrimEnd('/') + '/rest/v1/users?select=role,is_active&id=eq.' + $uid) -Headers $headers -TimeoutSec 30)
    if ($actor.Count -ne 1 -or $actor[0].is_active -ne $true -or $actor[0].role -notin @('hr','admin')) { throw 'Active HR/admin required.' }
    Write-Host 'ERP ROLE OK: active HR/admin'
    # PostgREST OpenAPI is metadata only. Never call the importing RPC during diagnosis.
    try {
        $schema = Invoke-RestMethod -Uri ($api.AbsoluteUri.TrimEnd('/') + '/rest/v1/') -Headers $headers -TimeoutSec 30
        if ($null -ne $schema.paths -and $schema.paths.PSObject.Properties.Name -contains '/rpc/sync_hikvision_attendance') {
            Write-Host 'ATTENDANCE RPC VISIBLE: device/login/role checks passed. Restart sync to obtain any importing-stage error.' -ForegroundColor Green
        } else {
            Write-Host 'ATTENDANCE RPC NOT VISIBLE: verify install_hikvision_sync.sql in this Supabase project.' -ForegroundColor Yellow
        }
    } catch { Write-Host 'SCHEMA CHECK UNAVAILABLE: device/login/role passed; check SQL installation separately.' -ForegroundColor Yellow }
    exit 0
} catch {
    $failure = Get-HikvisionSyncFailure -Failure $_ -Stage $stage
    Write-Host ('DIAGNOSIS FAILED: ' + ($failure | ConvertTo-Json -Compress)) -ForegroundColor Red
    exit 1
} finally {
    $session = $null; $headers = $null; $body = $null; $cache = $null; $values = $null
    if ($null -ne $device) { $device.Password.Dispose() }
    if ($null -ne $erp) { $erp.Password.Dispose() }
}
