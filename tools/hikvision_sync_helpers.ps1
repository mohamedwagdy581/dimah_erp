function ConvertTo-HikvisionSyncPage {
    param([Parameter(Mandatory)]$Response, [int]$Position = 0)
    $result = $Response.AcsEvent
    if ($null -eq $result) { throw 'Unexpected event response.' }
    $rows = @()
    if ($null -ne $result.InfoList) { $rows = @($result.InfoList) }
    $events = @()
    foreach ($row in $rows) {
        if ([int]$row.major -ne 5 -or [int]$row.minor -notin @(1, 38, 75)) { continue }
        $person = [string]$row.employeeNoString
        if ([string]::IsNullOrWhiteSpace($person)) { $person = [string]$row.employeeNo }
        if ([string]::IsNullOrWhiteSpace($person)) { continue }
        if ($person -cnotmatch '^[A-Za-z0-9_-]{1,32}$' -or [string]$row.serialNo -notmatch '^\d{1,32}$') { throw 'Invalid event identity.' }
        if ([string]$row.time -notmatch '(Z|[+-]\d{2}:\d{2})$') { throw 'Event time must include a timezone.' }
        $stamp = [DateTimeOffset]::Parse([string]$row.time, [Globalization.CultureInfo]::InvariantCulture)
        $status = [string]$row.attendanceStatus
        if ([string]::IsNullOrWhiteSpace($status)) { $status = 'unknown' }
        # Never infer attendance direction from event subtype, name, or time of day.
        $events += [ordered]@{ serial = [string]$row.serialNo; person = $person
            time = $stamp.ToString('o'); status = $status }
    }
    $next = $Position + $rows.Count
    if ($null -ne $result.totalMatches) {
        $done = $next -ge [int]$result.totalMatches
    } elseif ([string]$result.responseStatusStrg -in @('OK', 'NO MATCH', 'NO MATCHES')) {
        $done = $true
    } elseif ([string]$result.responseStatusStrg -eq 'MORE') {
        $done = $false
    } else { throw 'Missing search completion metadata; checkpoint not advanced.' }
    if (-not $done -and $rows.Count -eq 0) { throw 'Device pagination made no progress.' }
    return @{ events = $events; next = $next; done = $done }
}

function Read-HikvisionSyncEvents {
    param([Uri]$BaseUri, [Net.ICredentials]$Credentials,
        [DateTimeOffset]$Start, [DateTimeOffset]$End)
    $events = @()
    foreach ($minor in @(1, 38, 75)) {
        $position = 0
        $search = [Guid]::NewGuid().ToString()
        for ($page = 0; $page -lt 1000; $page++) {
            $query = @{ AcsEventCond = @{ searchID = $search; searchResultPosition = $position
                maxResults = 100; major = 5; minor = $minor; picEnable = $false
                startTime = $Start.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:sszzz')
                endTime = $End.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:sszzz') } }
            $request = [Net.HttpWebRequest]::Create([Uri]::new($BaseUri, 'ISAPI/AccessControl/AcsEvent?format=json'))
            $request.Method = 'POST'; $request.ContentType = 'application/json; charset=utf-8'
            $request.Timeout = 20000; $request.ReadWriteTimeout = 20000
            $request.AllowAutoRedirect = $false; $request.Proxy = $null; $request.Credentials = $Credentials
            $bytes = [Text.Encoding]::UTF8.GetBytes(($query | ConvertTo-Json -Depth 5 -Compress))
            $request.ContentLength = $bytes.Length
            $stream = $request.GetRequestStream()
            try { $stream.Write($bytes, 0, $bytes.Length) } finally { $stream.Dispose() }
            $response = $null
            try {
                $response = $request.GetResponse()
                $reader = $response.GetResponseStream()
                $memory = [IO.MemoryStream]::new()
                try {
                    $buffer = New-Object byte[] 8192
                    while (($count = $reader.Read($buffer, 0, $buffer.Length)) -gt 0) {
                        if ($memory.Length + $count -gt 4194304) { throw 'Device response too large.' }
                        $memory.Write($buffer, 0, $count)
                    }
                    $parsed = [Text.Encoding]::UTF8.GetString($memory.ToArray()) | ConvertFrom-Json
                } finally { $reader.Dispose(); $memory.Dispose() }
            } finally { if ($null -ne $response) { $response.Close() } }
            $converted = ConvertTo-HikvisionSyncPage -Response $parsed -Position $position
            $events += @($converted.events)
            $position = $converted.next
            if ($converted.done) { break }
            if ($page -eq 999) { throw 'Event search limit reached; checkpoint not advanced.' }
        }
    }
    return $events
}
