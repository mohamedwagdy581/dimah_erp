param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'hikvision_event_helpers.ps1')
. (Join-Path $PSScriptRoot 'hikvision_device_config.ps1')
$hikBaseUri = Get-HikvisionBaseUri
$hikCredentials = $null
$hikResponse = $null
try {
    Write-Host 'Dimah ERP - Hikvision read-only event sample'
    Write-Host 'Reads up to 5 events per type: fingerprint, face, card (last 7 days).'
    Write-Host 'No settings or database changes. Successful verification does not prove check-in/out.'
    Write-Host 'Event types are not converted to attendance yet. No photos are requested.'
    $hikUserName = Read-Host 'Device username (leave empty to cancel)'
    if ([string]::IsNullOrWhiteSpace($hikUserName)) { Write-Host 'Cancelled.'; exit 0 }
    $hikSecurePassword = Read-Host 'Device password (hidden while typing)' -AsSecureString
    $hikCredentials = [Management.Automation.PSCredential]::new($hikUserName.Trim(), $hikSecurePassword)
    $hikCredentialCache = [Net.CredentialCache]::new()
    $hikCredentialCache.Add($hikBaseUri, 'Digest', $hikCredentials.GetNetworkCredential())
    $hikEndTime = [DateTimeOffset]::UtcNow
    $hikSamples = @()
    # Official SDK event table: 0x26 fingerprint pass, 0x4b face pass, 0x01 card pass.
    # ISAPI search uses decimal values. These are diagnostic filters, not attendance rules.
    foreach ($hikMinor in @(38, 75, 1)) {
        $hikQuery = New-HikvisionEventQuery -EndTime $hikEndTime -Minor $hikMinor
        # POST submits search conditions only; it does not create or modify events.
        $hikRequest = [Net.HttpWebRequest]::Create([Uri]::new($hikBaseUri, 'ISAPI/AccessControl/AcsEvent?format=json'))
        $hikRequest.Method = 'POST'
        $hikRequest.ContentType = 'application/json; charset=utf-8'
        $hikRequest.Accept = 'application/json'
        $hikRequest.Timeout = 15000
        $hikRequest.ReadWriteTimeout = 15000
        $hikRequest.AllowAutoRedirect = $false
        $hikRequest.Proxy = $null
        $hikRequest.Credentials = $hikCredentialCache
        $hikRequest.PreAuthenticate = $false
        $hikBytes = [Text.Encoding]::UTF8.GetBytes(($hikQuery | ConvertTo-Json -Depth 4 -Compress))
        $hikRequest.ContentLength = $hikBytes.Length
        $hikRequestStream = $hikRequest.GetRequestStream()
        try { $hikRequestStream.Write($hikBytes, 0, $hikBytes.Length) } finally { $hikRequestStream.Dispose() }
        $hikResponse = $hikRequest.GetResponse()
        if ([int]$hikResponse.StatusCode -ne 200) { throw 'Unexpected HTTP status.' }
        $hikStream = $hikResponse.GetResponseStream()
        $hikBuffer = New-Object byte[] 8192
        $hikMemory = [IO.MemoryStream]::new()
        try {
            while (($hikRead = $hikStream.Read($hikBuffer, 0, $hikBuffer.Length)) -gt 0) {
                if (($hikMemory.Length + $hikRead) -gt 1048576) { throw 'Response exceeds sample limit.' }
                $hikMemory.Write($hikBuffer, 0, $hikRead)
            }
            $hikParsed = [Text.Encoding]::UTF8.GetString($hikMemory.ToArray()) | ConvertFrom-Json
        } finally { $hikMemory.Dispose(); $hikStream.Dispose() }
        $hikSample = ConvertTo-HikvisionEventSample -Response $hikParsed
        $hikSamples += [ordered]@{
            filter_major = 5
            filter_minor = $hikMinor
            sample_count = $hikSample.sample_count
            events = $hikSample.events
        }
        $hikResponse.Close()
        $hikResponse = $null
    }
    $hikEventCount = 0
    $hikIdentifiedCount = 0
    foreach ($hikSampleGroup in $hikSamples) {
        $hikEventCount += $hikSampleGroup.sample_count
        foreach ($hikSampleEvent in $hikSampleGroup.events) {
            if (-not [string]::IsNullOrWhiteSpace([string]$hikSampleEvent.employeeNoString) -or
                -not [string]::IsNullOrWhiteSpace([string]$hikSampleEvent.employeeNo)) { $hikIdentifiedCount++ }
        }
    }
    $hikReport = [ordered]@{
        host = $hikBaseUri.Host
        status = 'event_sample_read_successfully'
        checked_at_utc = [DateTime]::UtcNow.ToString('o')
        start_time = $hikQuery.AcsEventCond.startTime
        end_time = $hikQuery.AcsEventCond.endTime
        sample_count = $hikEventCount
        events_with_employee_id = $hikIdentifiedCount
        samples_by_type = $hikSamples
    }
    $hikDirectory = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\build'))
    [IO.Directory]::CreateDirectory($hikDirectory) | Out-Null
    $hikReportPath = Join-Path $hikDirectory 'hikvision_event_sample.json'
    $hikReportJson = $hikReport | ConvertTo-Json -Depth 8
    [IO.File]::WriteAllText($hikReportPath, $hikReportJson, [Text.UTF8Encoding]::new($false))
    Write-Host 'SUCCESS: event search completed. Automatic synchronization is not enabled yet.' -ForegroundColor Green
    Write-Host $hikReportJson
    if ($hikIdentifiedCount -eq 0) {
        Write-Host 'No employee IDs returned. Check recent employee verification and the device clock.' -ForegroundColor Yellow
    }
    Write-Host ('Report saved to: ' + $hikReportPath)
    exit 0
} catch [Net.WebException] {
    if ($null -ne $_.Exception.Response) {
        $hikStatus = [int]$_.Exception.Response.StatusCode
        $_.Exception.Response.Close()
        Write-Host ('Event check failed. Device HTTP status: ' + $hikStatus) -ForegroundColor Red
        if ($hikStatus -eq 401) { Write-Host 'Check the DEVICE username and password.' }
        if ($hikStatus -eq 400 -or $hikStatus -eq 404 -or $hikStatus -eq 405) {
            Write-Host 'This event search needs review for your firmware. Send a screenshot of this result.'
        }
    } else { Write-Host 'Unable to reach the device. Check the network connection.' -ForegroundColor Red }
    exit 1
} catch {
    Write-Host 'Unable to read a valid event sample. No settings or database changes were made.' -ForegroundColor Red
    exit 1
} finally {
    if ($null -ne $hikResponse) { $hikResponse.Close() }
    if ($null -ne $hikCredentials) { $hikCredentials.Password.Dispose() }
}
