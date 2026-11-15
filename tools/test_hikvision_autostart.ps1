$ErrorActionPreference = 'Stop'
$testPaths = @('start_hikvision_sync.ps1', 'setup_hikvision_autostart.ps1', 'check_hikvision_sync_status.ps1')
foreach ($name in $testPaths) {
    $tokens = $null; $errors = $null
    [Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot $name), [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors.Count) { throw ('PowerShell syntax failed: ' + $name) }
}
$testFile = Join-Path $PSScriptRoot ('..\build\hikvision-credential-test-' + [Guid]::NewGuid().ToString() + '.xml')
$fakePassword = 'Synthetic-test-' + [Guid]::NewGuid().ToString()
$device = [Management.Automation.PSCredential]::new('test-device', (ConvertTo-SecureString $fakePassword -AsPlainText -Force))
$erp = [Management.Automation.PSCredential]::new('test-erp', (ConvertTo-SecureString $fakePassword -AsPlainText -Force))
try {
    [pscustomobject]@{ Device = $device; ERP = $erp } | Export-Clixml -LiteralPath $testFile
    if ([IO.File]::ReadAllText($testFile).Contains($fakePassword)) { throw 'Password saved in plaintext.' }
    $restored = Import-Clixml -LiteralPath $testFile
    foreach ($credential in @($restored.Device, $restored.ERP)) {
        if ($credential -isnot [Management.Automation.PSCredential]) { throw 'Nested credential type not restored.' }
        if ($credential.GetNetworkCredential().Password -cne $fakePassword) { throw 'DPAPI round trip failed.' }
        $credential.Password.Dispose()
    }
    $setup = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'setup_hikvision_autostart.ps1'))
    foreach ($required in @('-WindowStyle Hidden', '-NonInteractive', '-AtLogOn', '-LogonType Interactive', '-RunLevel Limited', '-Unattended', '-MultipleInstances IgnoreNew')) {
        if (-not $setup.Contains($required)) { throw ('Missing task configuration: ' + $required) }
    }
    Write-Host 'PASS: script syntax, nested encrypted credential round trip, no plaintext password, background logon configuration. No task registered.'
} finally {
    $device.Password.Dispose(); $erp.Password.Dispose()
    if (Test-Path -LiteralPath $testFile) { Remove-Item -LiteralPath $testFile }
}
