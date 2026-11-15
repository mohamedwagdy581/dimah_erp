$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'hikvision_device_config.ps1')
if ((Get-HikvisionBaseUri).Host -ne '192.168.8.130') { throw 'Wrong configured address.' }
$path = Join-Path $PSScriptRoot '..\build\hikvision-device-config-test.json'
try {
    foreach ($address in @('192.168.8.97','192.168.8.130','10.0.0.12','172.16.0.20')) {
        [IO.File]::WriteAllText($path, (@{device_ipv4=$address} | ConvertTo-Json))
        if ((Get-HikvisionBaseUri -ConfigPath $path).Host -ne $address) { throw 'Configuration reload failed.' }
    }
    foreach ($address in @('8.8.8.8','https://example.com','192.168.8.130/path','127.0.0.1','::1','192.168.8.999')) {
        [IO.File]::WriteAllText($path, (@{device_ipv4=$address} | ConvertTo-Json))
        $rejected = $false
        try { Get-HikvisionBaseUri -ConfigPath $path | Out-Null } catch { $rejected = $true }
        if (-not $rejected) { throw 'Invalid/non-LAN address accepted.' }
    }
    foreach ($name in @('check_hikvision_connection.ps1','check_hikvision_events.ps1','hikvision_device_config.ps1')) {
        $tokens=$null; $errors=$null
        [Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot $name),[ref]$tokens,[ref]$errors) | Out-Null
        if ($errors.Count) { throw ('Script syntax error: ' + $name) }
    }
    Write-Host 'PASS: current address, reloading LAN addresses, rejecting malformed/public addresses, script syntax.'
} finally {
    if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path }
}
