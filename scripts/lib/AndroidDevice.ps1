function Get-AdbDefaultPath {
    $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    return (Join-Path $root 'tools\platform-tools\adb.exe')
}

function Format-AdbShellArgument {
    param([Parameter(Mandatory = $true)][string]$Value)
    return $Value.Trim()
}

function Invoke-AdbProcess {
    param(
        [Parameter(Mandatory = $true)][string]$AdbPath,
        [Parameter(Mandatory = $true)][string]$Arguments,
        [int]$TimeoutMs = 15000
    )

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $AdbPath
    $psi.Arguments = $Arguments
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8

    $result = [ordered]@{
        adb_path    = $AdbPath
        arguments   = $Arguments
        status      = 'unknown'
        exit_code   = $null
        stdout      = ''
        stderr      = ''
        duration_ms = $null
        error       = $null
    }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $proc = $null
    try {
        $proc = [System.Diagnostics.Process]::Start($psi)
        $stdoutTask = $proc.StandardOutput.ReadToEndAsync()
        $stderrTask = $proc.StandardError.ReadToEndAsync()
        $exited = $proc.WaitForExit($TimeoutMs)

        if ($exited) {
            try { $result.exit_code = $proc.ExitCode } catch { $result.exit_code = $null }
            $result.status = 'ok'
        } else {
            try { $proc.Kill() } catch { }
            try { $proc.WaitForExit(2000) } catch { }
            $result.status = 'timeout'
            $result.error = 'adb process did not exit before the configured timeout and was killed'
        }

        if ($null -ne $stdoutTask) { $result.stdout = [string]$stdoutTask.Result }
        if ($null -ne $stderrTask) { $result.stderr = [string]$stderrTask.Result }
    } catch {
        $result.status = 'error'
        $result.error = $_.Exception.Message
    } finally {
        $sw.Stop()
        $result.duration_ms = $sw.ElapsedMilliseconds
        if ($null -ne $proc) {
            try { $proc.Dispose() } catch { }
        }
    }

    return $result
}

function Invoke-AdbShell {
    param(
        [Parameter(Mandatory = $true)][string]$AdbPath,
        [Parameter(Mandatory = $true)][string]$Command,
        [string]$Serial = '',
        [int]$TimeoutMs = 15000
    )

    $command = Format-AdbShellArgument -Value $Command
    if ([string]::IsNullOrEmpty($command)) {
        return [ordered]@{
            adb_path = $AdbPath
            arguments = $Command
            status = 'error'
            exit_code = $null
            stdout = ''
            stderr = ''
            duration_ms = 0
            error = 'command is empty after formatting'
        }
    }

    $argsText = ''
    if ([string]::IsNullOrEmpty($Serial)) {
        $argsText = "shell $command"
    } else {
        $argsText = "-s $Serial shell $command"
    }

    $result = Invoke-AdbProcess -AdbPath $AdbPath -Arguments $argsText -TimeoutMs $TimeoutMs
    $result.command = $command
    $result.serial = $Serial
    return $result
}

function Get-AdbDeviceState {
    param(
        [Parameter(Mandatory = $true)][string]$AdbPath,
        [int]$TimeoutMs = 15000
    )

    $raw = Invoke-AdbProcess -AdbPath $AdbPath -Arguments 'devices -l' -TimeoutMs $TimeoutMs
    $devices = @()

    if ($raw.status -eq 'ok') {
        $lines = $raw.stdout -split "`r?`n"
        foreach ($line in $lines) {
            $trimmed = $line.Trim()
            if ([string]::IsNullOrEmpty($trimmed)) { continue }
            if ($trimmed -eq 'List of devices attached') { continue }
            if ($trimmed -like '*daemon started successfully*') { continue }

            if ($trimmed -match '^(\S+)\s+(\S+)\s*(.*)$') {
                $serial = $Matches[1]
                $state = $Matches[2]
                $tail = $Matches[3]

                $model = $null
                if ($tail -match 'model:([^\s]+)') { $model = $Matches[1] }

                $transportId = $null
                if ($tail -match 'transport_id:([^\s]+)') { $transportId = $Matches[1] }

                $devices += [ordered]@{
                    serial       = $serial
                    state        = $state
                    model        = $model
                    transport_id = $transportId
                    raw          = $trimmed
                }
            } else {
                $devices += [ordered]@{
                    serial       = $null
                    state        = 'unparsed'
                    model        = $null
                    transport_id = $null
                    raw          = $trimmed
                }
            }
        }
    }

    return [ordered]@{
        adb_path    = $AdbPath
        status      = $raw.status
        exit_code   = $raw.exit_code
        stdout      = $raw.stdout
        stderr      = $raw.stderr
        duration_ms = $raw.duration_ms
        error       = $raw.error
        devices     = $devices
    }
}

function Get-AdbDeviceBySerial {
    param(
        [Parameter(Mandatory = $true)][string]$AdbPath,
        [Parameter(Mandatory = $true)][string]$Serial,
        [int]$TimeoutMs = 15000
    )

    $state = Get-AdbDeviceState -AdbPath $AdbPath -TimeoutMs $TimeoutMs
    foreach ($device in $state.devices) {
        if ($device.serial -eq $Serial) {
            $device.raw_status = $state.status
            $device.raw_error = $state.error
            return $device
        }
    }
    return $null
}

function Get-AdbProp {
    param(
        [Parameter(Mandatory = $true)][string]$AdbPath,
        [Parameter(Mandatory = $true)][string]$Serial,
        [Parameter(Mandatory = $true)][string]$Key,
        [int]$TimeoutMs = 15000
    )

    $res = Invoke-AdbShell -AdbPath $AdbPath -Serial $Serial -Command "getprop $Key" -TimeoutMs $TimeoutMs
    $value = ''
    if ($null -ne $res.stdout) { $value = $res.stdout.TrimEnd("`r", "`n") }

    return [ordered]@{
        key        = $Key
        value      = $value
        status     = $res.status
        exit_code  = $res.exit_code
        stderr     = $res.stderr
        error      = $res.error
        duration_ms = $res.duration_ms
    }
}

function Get-AdbDf {
    param(
        [Parameter(Mandatory = $true)][string]$AdbPath,
        [Parameter(Mandatory = $true)][string]$Serial,
        [string]$Mount = '',
        [int]$TimeoutMs = 15000
    )

    if ([string]::IsNullOrEmpty($Mount)) {
        $command = 'df -k'
    } else {
        $command = "df -k $Mount"
    }

    $res = Invoke-AdbShell -AdbPath $AdbPath -Serial $Serial -Command $command -TimeoutMs $TimeoutMs
    return [ordered]@{
        mount       = $Mount
        command     = $command
        stdout      = $res.stdout
        stderr      = $res.stderr
        status      = $res.status
        exit_code   = $res.exit_code
        error       = $res.error
        duration_ms = $res.duration_ms
    }
}

function Get-AdbId {
    param(
        [Parameter(Mandatory = $true)][string]$AdbPath,
        [Parameter(Mandatory = $true)][string]$Serial,
        [int]$TimeoutMs = 15000
    )

    $res = Invoke-AdbShell -AdbPath $AdbPath -Serial $Serial -Command 'id' -TimeoutMs $TimeoutMs
    return [ordered]@{
        stdout      = $res.stdout
        stderr      = $res.stderr
        status      = $res.status
        exit_code   = $res.exit_code
        error       = $res.error
        duration_ms = $res.duration_ms
    }
}

function Convert-AdbDfOutput {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text)

    $rows = @()
    foreach ($line in ($Text -split "`r?`n")) {
        $trimmed = $line.Trim()
        if ([string]::IsNullOrEmpty($trimmed)) { continue }
        if ($trimmed -match '^Filesystem\s') { continue }

        if ($trimmed -match '^(\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+%)\s+(.+)$') {
            $rows += [ordered]@{
                fs        = $Matches[1]
                size_kb   = [int64]$Matches[2]
                used_kb   = [int64]$Matches[3]
                avail_kb  = [int64]$Matches[4]
                use_pct   = $Matches[5]
                mount     = $Matches[6].Trim()
            }
        }
    }

    return $rows
}
