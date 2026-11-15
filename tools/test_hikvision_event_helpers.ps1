$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'hikvision_event_helpers.ps1')
$hikQuery = New-HikvisionEventQuery -EndTime ([DateTimeOffset]'2026-10-05T12:00:00+03:00')
if ($hikQuery.AcsEventCond.startTime -ne '2026-09-28T09:00:00+00:00' -or $hikQuery.AcsEventCond.endTime -ne '2026-10-05T09:00:00+00:00') { throw 'UTC query interval failed.' }
if ($hikQuery.AcsEventCond.maxResults -ne 5 -or $hikQuery.AcsEventCond.picEnable -ne $false) { throw 'Query bounds failed.' }
foreach ($hikMinor in @(38, 75, 1)) {
    $hikFiltered = New-HikvisionEventQuery -Minor $hikMinor
    if ($hikFiltered.AcsEventCond.major -ne 5 -or $hikFiltered.AcsEventCond.minor -ne $hikMinor) { throw 'Verification type filter failed.' }
}
$hikFilterRejected = $false
try { New-HikvisionEventQuery -Minor 23 | Out-Null } catch { $hikFilterRejected = $true }
if (-not $hikFilterRejected) { throw 'Unsupported diagnostic filter accepted.' }
$hikFixture = '{"AcsEvent":{"InfoList":[{"serialNo":42,"employeeNoString":"0007","time":"2026-10-05T09:00:00+03:00","attendanceStatus":"checkIn","name":"PRIVATE_NAME","cardNo":"PRIVATE_CARD","pictureURL":"PRIVATE_PHOTO","password":"PRIVATE_PASSWORD","major":5,"minor":75}]}}' | ConvertFrom-Json
$hikSample = ConvertTo-HikvisionEventSample $hikFixture
$hikJson = $hikSample | ConvertTo-Json -Depth 6
if ($hikJson -match 'PRIVATE_' -or $hikJson -match 'pictureURL|cardNo|password') { throw 'Private data leaked.' }
if ($hikSample.sample_count -ne 1 -or $hikSample.events[0].employeeNoString -cne '0007' -or $hikSample.events[0].attendanceStatus -ne 'checkIn') { throw 'Event identity or status lost.' }
$hikFixture.AcsEvent.InfoList = @($hikFixture.AcsEvent.InfoList[0]) * 10
if ((ConvertTo-HikvisionEventSample $hikFixture).sample_count -ne 5) { throw 'Sample cap failed.' }
$hikEmpty = ConvertTo-HikvisionEventSample ('{"AcsEvent":{"numOfMatches":0}}' | ConvertFrom-Json)
if ($hikEmpty.sample_count -ne 0 -or @($hikEmpty.events).Count -ne 0) { throw 'Empty event response failed.' }
$hikRejected = $false
try { ConvertTo-HikvisionEventSample ('{"statusCode":4}' | ConvertFrom-Json) | Out-Null } catch { $hikRejected = $true }
if (-not $hikRejected) { throw 'Unexpected response accepted.' }
Write-Host 'PASS: query bounds/UTC, private-field exclusion, employee identity/status, event cap, empty response, invalid response.' -ForegroundColor Green
