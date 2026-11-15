function Get-HikvisionBaseUri {
    param([string]$ConfigPath = (Join-Path $PSScriptRoot 'hikvision_device.json'))
    $config = [IO.File]::ReadAllText($ConfigPath) | ConvertFrom-Json
    $address = [string]$config.device_ipv4
    $parsed = $null
    if (-not [Net.IPAddress]::TryParse($address, [ref]$parsed) -or
        $parsed.AddressFamily -ne [Net.Sockets.AddressFamily]::InterNetwork -or
        $parsed.ToString() -cne $address) { throw 'Invalid Hikvision IPv4 configuration.' }
    $octets = $parsed.GetAddressBytes()
    $private = ($octets[0] -eq 10) -or
        ($octets[0] -eq 192 -and $octets[1] -eq 168) -or
        ($octets[0] -eq 172 -and $octets[1] -ge 16 -and $octets[1] -le 31)
    if (-not $private) { throw 'Hikvision device must use a private LAN IPv4 address.' }
    return [Uri]('http://' + $address + '/')
}
