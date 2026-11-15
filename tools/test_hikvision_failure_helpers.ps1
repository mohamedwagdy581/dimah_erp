$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'hikvision_failure_helpers.ps1')
function New-FakeFailure {
    param([int]$Status,[string]$Code)
    return [pscustomobject]@{
        Exception = [pscustomobject]@{ Message = 'PRIVATE-PASSWORD-TOKEN'; Response = [pscustomobject]@{StatusCode = $Status} }
        ErrorDetails = [pscustomobject]@{Message = (@{code=$Code; message='PRIVATE-PASSWORD-TOKEN'; details='PRIVATE-PASSWORD-TOKEN'} | ConvertTo-Json)}
    }
}
$cases = @(
    @{stage='device_read'; status=401; code=''; reason='device_login_rejected'},
    @{stage='erp_sign_in'; status=400; code='invalid_credentials'; reason='erp_login_rejected'},
    @{stage='attendance_rpc'; status=404; code='PGRST202'; reason='attendance_sql_missing'},
    @{stage='attendance_rpc'; status=403; code='42501'; reason='erp_role_not_allowed'},
    @{stage='attendance_rpc'; status=400; code='22023'; reason='device_events_rejected'},
    @{stage='checkpoint'; status=0; code='PRIVATE-PASSWORD-TOKEN'; reason='checkpoint_save_failed'}
)
foreach ($case in $cases) {
    $result = Get-HikvisionSyncFailure -Stage $case.stage -Failure (New-FakeFailure $case.status $case.code)
    if ($result.reason -ne $case.reason) { throw ('Incorrect reason for ' + $case.stage) }
    if (($result | ConvertTo-Json -Compress).Contains('PRIVATE-PASSWORD-TOKEN')) { throw 'Private details leaked.' }
}
$timeout = [Net.WebException]::new('PRIVATE-PASSWORD-TOKEN', [Net.WebExceptionStatus]::Timeout)
$wrapped = [Exception]::new('PRIVATE-PASSWORD-TOKEN', $timeout)
$timeoutFailure = [pscustomobject]@{Exception=$wrapped; ErrorDetails=$null}
$timeoutResult = Get-HikvisionSyncFailure -Failure $timeoutFailure -Stage 'device_read'
if ($timeoutResult.reason -ne 'device_unreachable' -or $timeoutResult.transport_status -ne 'Timeout') { throw 'Wrapped transport failure was misclassified.' }
if (($timeoutResult | ConvertTo-Json).Contains('PRIVATE-PASSWORD-TOKEN')) { throw 'Transport error disclosed raw details.' }
foreach ($file in @('start_hikvision_sync.ps1','diagnose_hikvision_sync.ps1','hikvision_failure_helpers.ps1')) {
    $tokens = $null; $errors = $null
    [Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot $file),[ref]$tokens,[ref]$errors) | Out-Null
    if ($errors.Count) { throw ('Syntax error in ' + $file) }
}
Write-Host 'PASS: stage-specific failures, HTTP/provider-code classification, no password/token/raw-error disclosure, script syntax.'
