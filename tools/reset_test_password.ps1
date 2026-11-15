# Run locally as a Supabase project administrator. Never put this key in Flutter.
# Password is entered interactively, sent only to Supabase Auth, and not saved.
# Example: .\tools\reset_test_password.ps1 -ProjectUrl https://PROJECT.supabase.co -UserId AUTH-UUID
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][uri]$ProjectUrl,
    [Parameter(Mandatory = $true)][Guid]$UserId
)
$ErrorActionPreference = 'Stop'
if ($ProjectUrl.Scheme -ne 'https' -or $ProjectUrl.AbsolutePath -ne '/' -or $ProjectUrl.Query -or $ProjectUrl.Fragment) {
    throw 'ProjectUrl must be the HTTPS project origin, with no path, query or fragment.'
}
$adminKey = $env:SUPABASE_SERVICE_ROLE_KEY
if ([string]::IsNullOrWhiteSpace($adminKey)) {
    throw 'Set SUPABASE_SERVICE_ROLE_KEY in this local administrator session. Do not paste it into chat or source code.'
}
$securePassword = Read-Host 'New test password (keep it in your password manager)' -AsSecureString
if ($securePassword.Length -lt 8) { throw 'Choose a password of at least 8 characters, meeting your project policy.' }
$passwordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
try {
    $newPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordPointer)
    $body = @{ password = $newPassword } | ConvertTo-Json -Compress
    $headers = @{ apikey = $adminKey; Authorization = "Bearer $adminKey" }
    $target = $ProjectUrl.GetLeftPart([System.UriPartial]::Authority) + '/auth/v1/admin/users/' + $UserId.ToString()
    try {
        $result = Invoke-RestMethod -Method Put -Uri $target -Headers $headers -ContentType 'application/json' -Body $body
        Write-Output ('Password updated for Auth user ' + $result.id + '. No password was saved to public.users.')
    } catch {
        throw 'Supabase Auth rejected the update. Check the project URL, Auth user ID, admin key and password policy. No password was written to public.users.'
    }
} finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPointer)
    $newPassword = $null
    $body = $null
    $headers = $null
    $adminKey = $null
    $securePassword.Dispose()
}
