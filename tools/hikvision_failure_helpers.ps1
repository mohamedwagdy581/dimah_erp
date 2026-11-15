# Only allowlisted diagnostics may leave the bridge. Never return raw exception text.
function Get-HikvisionSyncFailure {
    param([Parameter(Mandatory)]$Failure, [Parameter(Mandatory)][string]$Stage)
    $http = $null; $code = $null; $transport = $null
    $exception = $Failure.Exception
    $networkException = $exception
    for ($depth = 0; $depth -lt 5 -and $null -ne $networkException; $depth++) {
        if ($networkException -is [Net.WebException]) {
            $transport = [string]$networkException.Status
            if ($null -ne $networkException.Response) {
                try { $http = [int]$networkException.Response.StatusCode } catch { }
            }
            break
        }
        $networkException = $networkException.InnerException
    }
    if ($null -ne $exception.Response) {
        try { $http = [int]$exception.Response.StatusCode } catch { }
    }
    $parsed = $null
    if ($null -ne $Failure.ErrorDetails) {
        try { $parsed = $Failure.ErrorDetails.Message | ConvertFrom-Json } catch { }
    }
    foreach ($candidate in @($parsed.code, $parsed.error_code, $parsed.error)) {
        if ([string]$candidate -cin @('invalid_credentials','invalid_grant','refresh_token_not_found',
            'user_banned','over_request_rate_limit','PGRST202','PGRST301','42501','22023','23505','42P01','42883')) {
            $code = [string]$candidate; break
        }
    }
    $reason = 'request_failed'; $action = 'Check this stage and retry.'
    if ($Stage -eq 'device_read') {
        $reason = 'device_unreachable'; $action = 'Check device power, the address in tools/hikvision_device.json, and the local network.'
        if ($http -eq 401 -or $http -eq 403) {
            $reason = 'device_login_rejected'; $action = 'Update DEVICE credentials using setup_hikvision_autostart.cmd.'
        } elseif ($http -ge 400) {
            $reason = 'device_http_error'; $action = 'Check device event-search support and run preview_hikvision_sync.cmd.'
        } elseif ($exception.Message -cin @('Unexpected event response.','Invalid event identity.',
            'Event time must include a timezone.','Missing search completion metadata; checkpoint not advanced.',
            'Device pagination made no progress.','Event search limit reached; checkpoint not advanced.','Device response too large.')) {
            $reason = 'device_event_format'; $action = 'Run preview_hikvision_sync.cmd; device event response needs review.'
        } elseif ($null -eq $transport -or $transport -eq 'ProtocolError') {
            $reason = 'device_read_failed'; $action = 'Run preview_hikvision_sync.cmd to check device response and event format.'
        }
    } elseif ($Stage -in @('erp_sign_in','erp_refresh')) {
        $reason = 'erp_connection_failed'; $action = 'Check internet access and Supabase configuration.'
        if ($http -in @(400,401,403) -or $code -in @('invalid_credentials','invalid_grant','refresh_token_not_found','user_banned')) {
            $reason = 'erp_login_rejected'; $action = 'Run setup_hikvision_autostart.cmd with the current ERP HR/admin password.'
        } elseif ($http -eq 429) {
            $reason = 'erp_rate_limited'; $action = 'Wait before retrying; avoid multiple login attempts.'
        }
    } elseif ($Stage -eq 'attendance_rpc') {
        $reason = 'attendance_rpc_failed'; $action = 'Check the installed attendance SQL and database availability.'
        if ($code -in @('PGRST202','42P01','42883') -or $http -eq 404) {
            $reason = 'attendance_sql_missing'; $action = 'Install install_attendance_identity.sql and install_hikvision_sync.sql in the correct project.'
        } elseif ($code -eq '42501' -or $http -eq 403) {
            $reason = 'erp_role_not_allowed'; $action = 'The bridge requires an active ERP HR/admin account; finance and employee accounts cannot sync.'
        } elseif ($code -eq '22023') {
            $reason = 'device_events_rejected'; $action = 'Check the device time/timezone and event format.'
        } elseif ($http -eq 401) {
            $reason = 'erp_session_rejected'; $action = 'The next cycle signs in again; update saved ERP credentials if this repeats.'
        }
    } elseif ($Stage -eq 'checkpoint') {
        $reason = 'checkpoint_save_failed'; $action = 'Check free disk space and checkpoint folder permissions; do not delete the checkpoint.'
    } elseif ($Stage -eq 'erp_role') {
        $reason = 'erp_role_not_allowed'; $action = 'Use an active ERP HR/admin account when setting up the bridge.'
    } elseif ($Stage -eq 'startup') {
        $reason = 'startup_failed'; $action = 'Check configuration, saved credentials and whether another sync process is running.'
        if ($exception.Message -ceq 'A synchronization process is already running.') {
            $reason = 'sync_already_running'; $action = 'Close the previous synchronization window before restarting automatic sync.'
        }
    }
    return [ordered]@{ stage = $Stage; reason = $reason; http_status = $http; provider_code = $code; transport_status = $transport; action = $action }
}
