param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'hikvision_device_config.ps1')
$hikBaseUri = Get-HikvisionBaseUri
$hikCredentials = $null
$hikResponse = $null
try {
    Write-Host 'Dimah ERP - Hikvision read-only connection check'
    Write-Host ('Device: ' + $hikBaseUri.Host + '. This check does not change device settings.')
    Write-Host 'Enter the DEVICE login below in this window. Press Ctrl+C to cancel.'
    $hikUserName = Read-Host 'Device username (leave empty to cancel)'
    if ([string]::IsNullOrWhiteSpace($hikUserName)) {
        Write-Host 'Cancelled.'
        exit 0
    }
    $hikSecurePassword = Read-Host 'Device password (hidden while typing)' -AsSecureString
    $hikCredentials = [Management.Automation.PSCredential]::new($hikUserName.Trim(), $hikSecurePassword)
    $hikCredentialCache = [Net.CredentialCache]::new()
    $hikCredentialCache.Add($hikBaseUri, 'Digest', $hikCredentials.GetNetworkCredential())
    $hikRequest = [Net.HttpWebRequest]::Create([Uri]::new($hikBaseUri, 'ISAPI/System/deviceInfo'))
    $hikRequest.Method = 'GET'
    $hikRequest.Timeout = 10000
    $hikRequest.ReadWriteTimeout = 10000
    $hikRequest.AllowAutoRedirect = $false
    $hikRequest.Proxy = $null
    $hikRequest.Credentials = $hikCredentialCache
    $hikRequest.PreAuthenticate = $false
    $hikResponse = $hikRequest.GetResponse()
    if ([int]$hikResponse.StatusCode -ne 200) {
        throw 'Device did not return a successful information response.'
    }
    $hikXmlSettings = [Xml.XmlReaderSettings]::new()
    $hikXmlSettings.DtdProcessing = [Xml.DtdProcessing]::Prohibit
    $hikXmlSettings.XmlResolver = $null
    $hikXmlSettings.MaxCharactersInDocument = 1048576
    $hikXmlReader = [Xml.XmlReader]::Create($hikResponse.GetResponseStream(), $hikXmlSettings)
    try {
        $hikXmlDocument = [Xml.XmlDocument]::new()
        $hikXmlDocument.XmlResolver = $null
        $hikXmlDocument.Load($hikXmlReader)
    } finally {
        $hikXmlReader.Dispose()
    }
    if ($hikXmlDocument.DocumentElement.LocalName -ne 'DeviceInfo') {
        throw 'Unexpected device response. No configuration was changed.'
    }
    $hikReport = [ordered]@{
        host = $hikBaseUri.Host
        authentication = 'Digest'
        status = 'device_information_read_successfully'
        checked_at_utc = [DateTime]::UtcNow.ToString('o')
    }
    foreach ($hikField in @('model', 'firmwareVersion', 'firmwareReleasedDate')) {
        $hikNode = $hikXmlDocument.SelectSingleNode("//*[local-name()='$hikField']")
        if ($null -ne $hikNode) { $hikReport[$hikField] = $hikNode.InnerText }
    }
    $hikReportDirectory = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\build'))
    [IO.Directory]::CreateDirectory($hikReportDirectory) | Out-Null
    $hikReportPath = Join-Path $hikReportDirectory 'hikvision_connection_report.json'
    $hikReportJson = $hikReport | ConvertTo-Json
    [IO.File]::WriteAllText($hikReportPath, $hikReportJson, [Text.UTF8Encoding]::new($false))
    Write-Host ''
    Write-Host 'SUCCESS: device information read. Attendance synchronization is not enabled yet.' -ForegroundColor Green
    Write-Host $hikReportJson
    Write-Host ('Report saved to: ' + $hikReportPath)
    exit 0
} catch [Net.WebException] {
    if ($null -ne $_.Exception.Response) {
        $hikStatus = [int]$_.Exception.Response.StatusCode
        $_.Exception.Response.Close()
        Write-Host ('Check failed. Device HTTP status: ' + $hikStatus) -ForegroundColor Red
        if ($hikStatus -eq 401) { Write-Host 'Check the DEVICE username and password. No settings were changed.' }
    } else {
        Write-Host 'Unable to reach the device. Check the network connection.' -ForegroundColor Red
    }
    exit 1
} catch {
    Write-Host 'Unable to read device information. No settings were changed.' -ForegroundColor Red
    exit 1
} finally {
    if ($null -ne $hikResponse) { $hikResponse.Close() }
    if ($null -ne $hikCredentials) { $hikCredentials.Password.Dispose() }
}
