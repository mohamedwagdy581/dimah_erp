$ErrorActionPreference = 'Stop'
$deviceCredential = $null; $erpCredential = $null
$taskName = 'Dimah ERP Hikvision Attendance'
try {
    Write-Host 'Dimah ERP - one-time automatic attendance setup'
    Write-Host 'Close the old LIVE sync window with Ctrl+C before continuing.' -ForegroundColor Yellow
    $userName = Read-Host 'DEVICE username (empty cancels)'
    if ([string]::IsNullOrWhiteSpace($userName)) { exit 0 }
    $deviceCredential = [Management.Automation.PSCredential]::new($userName.Trim(), (Read-Host 'DEVICE password' -AsSecureString))
    $erpEmail = Read-Host 'ERP HR/admin email'
    if ([string]::IsNullOrWhiteSpace($erpEmail)) { exit 0 }
    $erpCredential = [Management.Automation.PSCredential]::new($erpEmail.Trim(), (Read-Host 'ERP password' -AsSecureString))
    $syncDirectory = Join-Path $env:LOCALAPPDATA 'DimahERP\HikvisionSync'
    [IO.Directory]::CreateDirectory($syncDirectory) | Out-Null
    # Passwords use Windows DPAPI for this user and machine, not plaintext.
    # Restrict directory access to the current Windows user and SYSTEM.
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $acl = [Security.AccessControl.DirectorySecurity]::new()
    $acl.SetAccessRuleProtection($true, $false)
    foreach ($sid in @($identity.User, [Security.Principal.SecurityIdentifier]::new('S-1-5-18'))) {
        $acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new($sid, 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow'))
    }
    Set-Acl -LiteralPath $syncDirectory -AclObject $acl
    # Stop only our own registered task when updating stored credentials.
    $existing = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($null -ne $existing) { Stop-ScheduledTask -TaskName $taskName }
    $credentialPath = Join-Path $syncDirectory 'credentials.xml'
    [pscustomobject]@{ Device = $deviceCredential; ERP = $erpCredential } | Export-Clixml -LiteralPath ($credentialPath + '.pending')
    Move-Item -LiteralPath ($credentialPath + '.pending') -Destination $credentialPath -Force
    $oldCheckpoint = Join-Path $PSScriptRoot '..\build\hikvision-sync\checkpoint.txt'
    $newCheckpoint = Join-Path $syncDirectory 'checkpoint.txt'
    if (-not (Test-Path -LiteralPath $newCheckpoint) -and (Test-Path -LiteralPath $oldCheckpoint)) {
        Copy-Item -LiteralPath $oldCheckpoint -Destination $newCheckpoint
    }
    $runner = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'start_hikvision_sync.ps1'))
    $powerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $arguments = '-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "' + $runner + '" -Commit -Unattended'
    $action = New-ScheduledTaskAction -Execute $powerShell -Argument $arguments -WorkingDirectory $PSScriptRoot
    $principal = New-ScheduledTaskPrincipal -UserId $identity.User.Value -LogonType Interactive -RunLevel Limited
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $identity.Name
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit ([TimeSpan]::Zero) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description 'Dimah ERP Hikvision sync every minute, encrypted credentials for this Windows user.' -Force | Out-Null
    Start-ScheduledTask -TaskName $taskName
    Write-Host 'SUCCESS: automatic startup enabled for this Windows account.' -ForegroundColor Green
    Write-Host 'The sync runs in the background now and after Windows sign-in. No daily password prompts.'
    Write-Host 'Run check_hikvision_sync_status.cmd to check the first result.'
} catch {
    Write-Host 'Setup failed. Close the old sync window and check Task Scheduler access for this Windows account. No passwords are printed.' -ForegroundColor Red
    exit 1
} finally {
    if ($null -ne $deviceCredential) { $deviceCredential.Password.Dispose() }
    if ($null -ne $erpCredential) { $erpCredential.Password.Dispose() }
}
