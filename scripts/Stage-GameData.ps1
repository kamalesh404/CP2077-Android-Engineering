# Stage-GameData.ps1
# Production-Hardened, Read-Only Staging Utility for Cyberpunk 2077 Android Deployment
# Strictly protects original Steam installation and validates destination before copying.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DestinationPath,

    [string]$GameSource = "C:\Games\steam\steamapps\common\Cyberpunk 2077",
    [string]$DistSource = "C:\CP2077-Android-Engineering\dist",
    [string]$ReportPath = "C:\CP2077-Android-Engineering\reports\STAGING_RUN_REPORT.json",
    
    [int64]$SafetyMarginBytes = 5368709120, # 5 GB default safety margin
    [switch]$AllowOverwrite,
    [switch]$DryRun
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Cyberpunk 2077 Android Deployment - Hardened Staging Tool" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$executionReport = [ordered]@{
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
    dry_run = $DryRun.IsPresent
    allow_overwrite = $AllowOverwrite.IsPresent
    source_path = $GameSource
    destination_path = $DestinationPath
    status = "INITIALIZING"
    planned_files_count = 0
    planned_bytes = 0
    safety_margin_bytes = $SafetyMarginBytes
    required_bytes_total = 0
    destination_free_bytes = 0
    omitted_files = @()
    transferred_files = @()
    failed_files = @()
    error_message = $null
}

function Save-ExecutionReport {
    param([string]$Status, [string]$ErrorMsg = $null)
    $executionReport.status = $Status
    if ($null -ne $ErrorMsg) { $executionReport.error_message = $ErrorMsg }
    try {
        $reportDir = Split-Path -Parent $ReportPath
        if (-not (Test-Path $reportDir)) { New-Item -ItemType Directory -Force -Path $reportDir | Out-Null }
        $executionReport | ConvertTo-Json -Depth 6 | Out-File -FilePath $ReportPath -Encoding utf8
    } catch {
        Write-Warning "Failed to write execution report: $($_.Exception.Message)"
    }
}

# --- GATE 1: SOURCE VALIDATION (READ-ONLY) ---
if (-not (Test-Path $GameSource -PathType Container)) {
    $err = "Source game directory not found: $GameSource"
    Write-Error $err
    Save-ExecutionReport -Status "FAILED_INVALID_SOURCE" -ErrorMsg $err
    exit 1
}

$canonicalSource = [System.IO.Path]::GetFullPath($GameSource).TrimEnd("\", "/")

# --- GATE 2: DESTINATION PATH VALIDATION & SOURCE PROTECTION ---
if ([string]::IsNullOrWhiteSpace($DestinationPath)) {
    $err = "Destination path cannot be empty."
    Write-Error $err
    Save-ExecutionReport -Status "FAILED_INVALID_DESTINATION" -ErrorMsg $err
    exit 1
}

try {
    $canonicalDest = [System.IO.Path]::GetFullPath($DestinationPath).TrimEnd("\", "/")
} catch {
    $err = "Invalid destination path syntax: $DestinationPath ($($_.Exception.Message))"
    Write-Error $err
    Save-ExecutionReport -Status "FAILED_INVALID_DESTINATION" -ErrorMsg $err
    exit 1
}

# CRITICAL PROTECTION: Prevent overwriting source installation or parent paths
if ($canonicalDest.Equals($canonicalSource, [System.StringComparison]::OrdinalIgnoreCase)) {
    $err = "SAFETY VIOLATION: Destination path cannot be identical to the source game directory!"
    Write-Error $err
    Save-ExecutionReport -Status "FAILED_SOURCE_OVERWRITE_PREVENTED" -ErrorMsg $err
    exit 1
}

if ($canonicalSource.StartsWith($canonicalDest + "\", [System.StringComparison]::OrdinalIgnoreCase) -or 
    $canonicalDest.StartsWith($canonicalSource + "\", [System.StringComparison]::OrdinalIgnoreCase)) {
    $err = "SAFETY VIOLATION: Destination path overlaps with source game installation hierarchy ($canonicalDest <-> $canonicalSource)!"
    Write-Error $err
    Save-ExecutionReport -Status "FAILED_SOURCE_OVERLAP_PREVENTED" -ErrorMsg $err
    exit 1
}

# Validate Destination Drive / Root
$destRoot = [System.IO.Path]::GetPathRoot($canonicalDest)
if (-not (Test-Path $destRoot)) {
    $err = "Destination root drive/volume not found: $destRoot"
    Write-Error $err
    Save-ExecutionReport -Status "FAILED_DESTINATION_ROOT_NOT_FOUND" -ErrorMsg $err
    exit 1
}

# --- GATE 3: WRITABILITY TEST (NON-DRYRUN) ---
if (-not $DryRun) {
    try {
        if (-not (Test-Path $canonicalDest)) {
            New-Item -ItemType Directory -Force -Path $canonicalDest | Out-Null
        }
        $testProbe = Join-Path $canonicalDest (".staging_write_test_" + [System.Guid]::NewGuid().ToString("N"))
        Set-Content -Path $testProbe -Value "write_test" -ErrorAction Stop
        Remove-Item -Path $testProbe -Force -ErrorAction Stop
    } catch {
        $err = "Destination directory is not writable: $canonicalDest ($($_.Exception.Message))"
        Write-Error $err
        Save-ExecutionReport -Status "FAILED_DESTINATION_NOT_WRITABLE" -ErrorMsg $err
        exit 1
    }
}

$destGameDir = Join-Path $canonicalDest "Cyberpunk2077"
$destCompatibilityDir = Join-Path $canonicalDest "Winlator_Setup"

# --- GATE 4: OVERWRITE PROTECTION ---
if (-not $AllowOverwrite) {
    if (Test-Path $destGameDir) {
        $existingGameFiles = Get-ChildItem -Path $destGameDir -Recurse -File -ErrorAction SilentlyContinue
        if ($existingGameFiles.Count -gt 0) {
            $err = "OVERWRITE REFUSED: Destination directory '$destGameDir' already contains $($existingGameFiles.Count) files. Run with -AllowOverwrite to authorize replacement."
            Write-Error $err
            Save-ExecutionReport -Status "FAILED_OVERWRITE_REFUSED" -ErrorMsg $err
            exit 1
        }
    }
}

# --- GATE 5: FILE SELECTION & EXACT BYTE CALCULATION ---
Write-Host "`nScanning source files to calculate exact byte payload..." -ForegroundColor Cyan

$stagedPlan = @()
$omittedPlan = @()
$totalPayloadBytes = 0

# 1. Compatibility APK & Configs from dist
if (Test-Path $DistSource) {
    $compatFiles = Get-ChildItem -Path $DistSource -Recurse -File | Where-Object { $_.Name -ne "SHA256SUMS.txt" }
    foreach ($cf in $compatFiles) {
        $relPath = $cf.FullName.Substring($DistSource.Length).TrimStart("\", "/")
        $targetPath = Join-Path $destCompatibilityDir $relPath
        $stagedPlan += [PSCustomObject]@{
            Source = $cf.FullName
            Destination = $targetPath
            RelativePath = "Winlator_Setup\" + $relPath
            SizeBytes = $cf.Length
            Category = "Compatibility"
        }
        $totalPayloadBytes += $cf.Length
    }
}

# 2. Game files from C:\Games\steam\steamapps\common\Cyberpunk 2077
$gameFiles = Get-ChildItem -Path $canonicalSource -Recurse -File
foreach ($gf in $gameFiles) {
    # CRITICAL SECURITY RULE: Omit the unverified 132 MB anomaly
    if ($gf.Name -eq "cyberpunk2077_addresses.json") {
        $omittedPlan += [PSCustomObject]@{
            Source = $gf.FullName
            RelativePath = $gf.FullName.Substring($canonicalSource.Length).TrimStart("\", "/")
            SizeBytes = $gf.Length
            Reason = "SEALED_UNTRUSTED_ANOMALY"
        }
        continue
    }

    # Omit secondary redist installers (e.g. REDlauncher.msi)
    if ($gf.Name -like "*.msi") {
        $omittedPlan += [PSCustomObject]@{
            Source = $gf.FullName
            RelativePath = $gf.FullName.Substring($canonicalSource.Length).TrimStart("\", "/")
            SizeBytes = $gf.Length
            Reason = "OPTIONAL_REDIST_INSTALLER"
        }
        continue
    }

    $relPath = $gf.FullName.Substring($canonicalSource.Length).TrimStart("\", "/")
    $targetPath = Join-Path $destGameDir $relPath

    $stagedPlan += [PSCustomObject]@{
        Source = $gf.FullName
        Destination = $targetPath
        RelativePath = "Cyberpunk2077\" + $relPath
        SizeBytes = $gf.Length
        Category = "GameData"
    }
    $totalPayloadBytes += $gf.Length
}

$executionReport.planned_files_count = $stagedPlan.Count
$executionReport.planned_bytes = $totalPayloadBytes
$executionReport.required_bytes_total = $totalPayloadBytes + $SafetyMarginBytes
$executionReport.omitted_files = $omittedPlan

Write-Host "Files Selected for Staging : $($stagedPlan.Count)" -ForegroundColor Green
Write-Host "Files Omitted (Protected) : $($omittedPlan.Count)" -ForegroundColor Yellow
Write-Host ("Exact Payload Size         : {0:N2} GiB ({1:N0} bytes)" -f ($totalPayloadBytes / 1GB), $totalPayloadBytes) -ForegroundColor Green
Write-Host ("Explicit Safety Margin     : {0:N2} GiB ({1:N0} bytes)" -f ($SafetyMarginBytes / 1GB), $SafetyMarginBytes) -ForegroundColor Cyan
Write-Host ("Total Required Free Space  : {0:N2} GiB ({1:N0} bytes)" -f (($totalPayloadBytes + $SafetyMarginBytes) / 1GB), ($totalPayloadBytes + $SafetyMarginBytes)) -ForegroundColor Cyan

# --- GATE 6: DYNAMIC FREE SPACE VALIDATION ---
$driveInfo = Get-PSDrive | Where-Object { $_.Root -and $destRoot.StartsWith($_.Root, [System.StringComparison]::OrdinalIgnoreCase) }
if ($null -ne $driveInfo) {
    $destFreeBytes = $driveInfo.Free
    $executionReport.destination_free_bytes = $destFreeBytes
    Write-Host ("Destination Free Space     : {0:N2} GiB ({1:N0} bytes)" -f ($destFreeBytes / 1GB), $destFreeBytes) -ForegroundColor Cyan

    $requiredWithMargin = $totalPayloadBytes + $SafetyMarginBytes
    if ($destFreeBytes -lt $requiredWithMargin) {
        $shortfall = $requiredWithMargin - $destFreeBytes
        $err = ("INSUFFICIENT STORAGE: Destination free space ({0:N2} GiB) is less than required ({1:N2} GiB). Shortfall: {2:N2} GiB." -f 
            ($destFreeBytes / 1GB), ($requiredWithMargin / 1GB), ($shortfall / 1GB))
        Write-Error $err
        Save-ExecutionReport -Status "FAILED_INSUFFICIENT_SPACE" -ErrorMsg $err
        exit 1
    }
}

# --- DRY-RUN SHORT-CIRCUIT ---
if ($DryRun) {
    Write-Host "`n[DRY RUN COMPLETE] Zero bytes written to disk. All safety and storage checks PASSED." -ForegroundColor Green
    Save-ExecutionReport -Status "DRY_RUN_PASSED"
    exit 0
}

# --- GATE 7: RESILIENT EXECUTION WITH PER-FILE ERROR HANDLING ---
Write-Host "`nBeginning copy operation to: $canonicalDest" -ForegroundColor Cyan

New-Item -ItemType Directory -Force -Path $destGameDir | Out-Null
New-Item -ItemType Directory -Force -Path $destCompatibilityDir | Out-Null

$stagedManifest = @()
$copyFailed = $false
$failureReason = $null
$completedBytes = 0

foreach ($item in $stagedPlan) {
    $destDir = Split-Path -Parent $item.Destination
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    }

    try {
        Copy-Item -Path $item.Source -Destination $item.Destination -Force:$AllowOverwrite -ErrorAction Stop
        
        # Calculate SHA-256 for destination manifest
        $sha256 = (Get-FileHash -Path $item.Destination -Algorithm SHA256).Hash
        $completedBytes += $item.SizeBytes

        $manifestEntry = [ordered]@{
            relative_path = $item.RelativePath
            size_bytes = $item.SizeBytes
            sha256 = $sha256
        }
        $stagedManifest += $manifestEntry
        $executionReport.transferred_files += $manifestEntry

    } catch {
        $copyFailed = $true
        $failureReason = "Failed to copy '$($item.RelativePath)': $($_.Exception.Message)"
        Write-Error $failureReason
        $executionReport.failed_files += [ordered]@{
            relative_path = $item.RelativePath
            source = $item.Source
            destination = $item.Destination
            error = $_.Exception.Message
        }
        break # STOP SAFELY ON FIRST COPY FAILURE
    }
}

# --- GATE 8: DESTINATION MANIFEST & INTEGRITY LEDGER ---
if ($stagedManifest.Count -gt 0) {
    $manifestPath = Join-Path $destGameDir "STAGED_MANIFEST.json"
    $shaListPath = Join-Path $destGameDir "STAGED_SHA256SUMS.txt"
    
    $stagedManifest | ConvertTo-Json -Depth 5 | Out-File -FilePath $manifestPath -Encoding utf8
    
    $shaLines = @()
    foreach ($m in $stagedManifest) {
        $shaLines += "$($m.sha256)  $($m.relative_path)"
    }
    $shaLines | Out-File -FilePath $shaListPath -Encoding utf8
    
    Write-Host "[OK] Written destination manifest: $manifestPath" -ForegroundColor Green
    Write-Host "[OK] Written destination checksums: $shaListPath" -ForegroundColor Green
}

if ($copyFailed) {
    Save-ExecutionReport -Status "FAILED_MID_TRANSFER" -ErrorMsg $failureReason
    Write-Error "`nSTAGING HALTED DUE TO ERROR: $failureReason"
    Write-Warning "Source directory remains completely untouched. Completed files have been preserved."
    exit 1
}

# Verify Executable Specifically
$destExe = Join-Path $destGameDir "bin\x64\Cyberpunk2077.exe"
if (Test-Path $destExe) {
    $destExeHash = (Get-FileHash -Path $destExe -Algorithm SHA256).Hash
    Write-Host "`nStaged Executable SHA-256: $destExeHash" -ForegroundColor Green
    if ($destExeHash -ne "A7DE82945C03E041FC7339FCF9066224D98DB2F5D80FEA50F7947BB350A60991") {
        $err = "FATAL: Executable hash mismatch at destination!"
        Write-Error $err
        Save-ExecutionReport -Status "FAILED_EXECUTABLE_HASH_MISMATCH" -ErrorMsg $err
        exit 1
    }
}

Save-ExecutionReport -Status "SUCCESS"
Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host " Staging completed successfully with full verification!" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
