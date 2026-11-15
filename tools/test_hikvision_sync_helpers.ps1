$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'hikvision_sync_helpers.ps1')
$fixture = '{"AcsEvent":{"totalMatches":2,"InfoList":[{"serialNo":42,"major":5,"minor":75,"employeeNoString":"0002","time":"2026-10-06T10:00:00+03:00","attendanceStatus":"checkIn","name":"PRIVATE","pictureURL":"PRIVATE"}]}}' | ConvertFrom-Json
$page = ConvertTo-HikvisionSyncPage $fixture
if ($page.done -or $page.next -ne 1 -or $page.events.Count -ne 1) { throw 'Pagination failed.' }
if ($page.events[0].person -cne '0002' -or $page.events[0].status -cne 'checkIn') { throw 'Identity/status changed.' }
if (($page | ConvertTo-Json -Depth 5) -match 'PRIVATE|pictureURL') { throw 'Private fields leaked.' }
if (-not (ConvertTo-HikvisionSyncPage $fixture -Position 1).done) { throw 'Last page not detected.' }
$fixture.AcsEvent.InfoList[0].attendanceStatus = 'overtimeIn'
if ((ConvertTo-HikvisionSyncPage $fixture).events[0].status -cne 'overtimeIn') { throw 'Unsupported status was inferred.' }
$fixture.AcsEvent.InfoList[0].minor = 23
if ((ConvertTo-HikvisionSyncPage $fixture).events.Count -ne 0) { throw 'Door event accepted.' }
$fixture.AcsEvent.InfoList[0].minor = 75
$fixture.AcsEvent.InfoList[0].time = '2026-10-06T10:00:00'
$rejected = $false
try { ConvertTo-HikvisionSyncPage $fixture | Out-Null } catch { $rejected = $true }
if (-not $rejected) { throw 'Timezone-less event accepted.' }
$rejected = $false
try { ConvertTo-HikvisionSyncPage ('{"AcsEvent":{"totalMatches":2,"InfoList":[]}}' | ConvertFrom-Json) | Out-Null } catch { $rejected = $true }
if (-not $rejected) { throw 'No-progress pagination accepted.' }
Write-Host 'PASS: pagination, leading zeros, timestamps, explicit status, private-field exclusion, ignored door events, no-progress rejection.'
