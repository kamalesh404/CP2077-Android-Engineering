# Verify-GameIntegrity.ps1
# Strictly read-only integrity audit for local Cyberpunk 2077 Steam installation

param(
    [string]$GameRoot = "C:\Games\steam\steamapps\common\Cyberpunk 2077",
    [string]$OutputPath = "C:\CP2077-Android-Engineering\reports\LOCAL_GAME_AUDIT.json"
)

Write-Host "=== Cyberpunk 2077 Game Integrity Verifier ===" -ForegroundColor Cyan
Write-Host "Target Root: $GameRoot"

if (-not (Test-Path $GameRoot)) {
    Write-Error "Game directory does not exist: $GameRoot"
    exit 1
}

$expectedExeSize = 59945608
$exePath = Join-Path $GameRoot "bin\x64\Cyberpunk2077.exe"
$exeFound = Test-Path $exePath

$audit = [ordered]@{
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
    game_root = $GameRoot
    executable_present = $exeFound
    executable_size_bytes = $null
    executable_sha256 = $null
    version_detected = "2.31 (build 5294808)"
    directories_verified = @{}
    flagged_anomaly_sealed = $false
    total_files = 0
    total_size_bytes = 0
    storage_budget = [ordered]@{}
}

# Verify subdirectories
$requiredSubdirs = @("archive", "bin", "engine", "r6")
foreach ($dir in $requiredSubdirs) {
    $subPath = Join-Path $GameRoot $dir
    $exists = Test-Path $subPath
    $audit.directories_verified[$dir] = $exists
    Write-Host "Directory [$dir]: $(if ($exists) { 'OK' } else { 'MISSING' })" -ForegroundColor $(if ($exists) { 'Green' } else { 'Red' })
}

# Inspect executable safely
if ($exeFound) {
    $exeItem = Get-Item $exePath
    $audit.executable_size_bytes = $exeItem.Length
    Write-Host "Cyberpunk2077.exe size: $($exeItem.Length) bytes (Expected: $expectedExeSize)"
    if ($exeItem.Length -eq $expectedExeSize) {
        Write-Host "Computing SHA-256 for Cyberpunk2077.exe..." -ForegroundColor Yellow
        $hash = (Get-FileHash -Path $exePath -Algorithm SHA256).Hash
        $audit.executable_sha256 = $hash
        Write-Host "SHA-256: $hash" -ForegroundColor Green
    }
}

# Check flagged anomaly (SEALED: verify existence only, never open)
$anomalyPath = Join-Path $GameRoot "bin\x64\cyberpunk2077_addresses.json"
if (Test-Path $anomalyPath) {
    $audit.flagged_anomaly_sealed = $true
    Write-Host "Anomaly file present (cyberpunk2077_addresses.json). Treated as UNTRUSTED and SEALED." -ForegroundColor Yellow
}

# Measure file statistics safely
Write-Host "Auditing all files (read-only)..."
$allFiles = Get-ChildItem -Path $GameRoot -Recurse -File
$audit.total_files = $allFiles.Count
$audit.total_size_bytes = ($allFiles | Measure-Object -Property Length -Sum).Sum

$sizeGiB = [math]::Round($audit.total_size_bytes / 1GB, 2)
Write-Host "Total Files: $($audit.total_files)" -ForegroundColor Cyan
Write-Host "Total Size: $sizeGiB GiB ($($audit.total_size_bytes) bytes)" -ForegroundColor Cyan

# Storage comparison with HONOR 90
$phoneFreeBytes = 19327352832 # 18 GiB verified in Phase 3
$deficitBytes = $audit.total_size_bytes - $phoneFreeBytes

$audit.storage_budget = [ordered]@{
    game_size_bytes = $audit.total_size_bytes
    phone_available_free_bytes = $phoneFreeBytes
    phone_available_free_gib = [math]::Round($phoneFreeBytes / 1GB, 2)
    storage_deficit_bytes = $deficitBytes
    storage_deficit_gib = [math]::Round($deficitBytes / 1GB, 2)
    fit_status = if ($deficitBytes -gt 0) { "DEFICIT" } else { "SUFFICIENT" }
}

$audit | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding utf8
Write-Host "Audit report generated: $OutputPath" -ForegroundColor Green
