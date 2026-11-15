function New-HikvisionEventQuery {
    param(
        [DateTimeOffset]$EndTime = [DateTimeOffset]::UtcNow,
        [ValidateSet(0, 1, 38, 75)][int]$Minor = 0
    )
    return [ordered]@{ AcsEventCond = [ordered]@{
        searchID = [Guid]::NewGuid().ToString()
        searchResultPosition = 0
        maxResults = 5
        major = 5
        minor = $Minor
        startTime = $EndTime.AddDays(-7).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:sszzz')
        endTime = $EndTime.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:sszzz')
        picEnable = $false
    } }
}

function ConvertTo-HikvisionEventSample {
    param([Parameter(Mandatory)]$Response)
    $hikResult = $Response.PSObject.Properties['AcsEvent']
    if ($null -eq $hikResult -or $null -eq $hikResult.Value) {
        throw 'Unexpected event response.'
    }
    $hikEvents = @()
    $hikList = $hikResult.Value.PSObject.Properties['InfoList']
    if ($null -ne $hikList -and $null -ne $hikList.Value) {
        foreach ($hikEvent in @($hikList.Value) | Select-Object -First 5) {
            $hikSafeEvent = [ordered]@{}
            foreach ($hikField in @('serialNo', 'time', 'employeeNoString', 'employeeNo', 'major', 'minor', 'attendanceStatus', 'currentVerifyMode')) {
                $hikProperty = $hikEvent.PSObject.Properties[$hikField]
                if ($null -ne $hikProperty -and $null -ne $hikProperty.Value) {
                    $hikValue = $hikProperty.Value
                    if ($hikValue -is [string] -or $hikValue -is [ValueType]) {
                        $hikSafeEvent[$hikField] = $hikValue
                    }
                }
            }
            $hikEvents += $hikSafeEvent
        }
    }
    return [ordered]@{ sample_count = $hikEvents.Count; events = $hikEvents }
}
