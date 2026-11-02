# Build-DeploymentBundle.ps1
# Creates a self-contained, verified deployment directory in C:\CP2077-Android-Engineering\dist

param(
    [string]$DistDir = "C:\CP2077-Android-Engineering\dist",
    [string]$RootDir = "C:\CP2077-Android-Engineering"
)

Write-Host "=== Assembling Cyberpunk 2077 Android Deployment Bundle ===" -ForegroundColor Cyan

# Ensure clean subdirectories in dist
$subdirs = @("tools", "config", "docs", "scripts")
foreach ($sub in $subdirs) {
    $p = Join-Path $DistDir $sub
    if (-not (Test-Path $p)) {
        New-Item -ItemType Directory -Path $p -Force | Out-Null
    }
}

# Copy config templates
Copy-Item (Join-Path $RootDir "config\*") (Join-Path $DistDir "config") -Force
Write-Host "[OK] Copied configuration templates to dist/config" -ForegroundColor Green

# Copy scripts
Copy-Item (Join-Path $RootDir "scripts\Verify-GameIntegrity.ps1") (Join-Path $DistDir "scripts") -Force
Copy-Item (Join-Path $RootDir "scripts\Analyze-AssetReduction.ps1") (Join-Path $DistDir "scripts") -Force
Copy-Item (Join-Path $RootDir "scripts\Stage-GameData.ps1") (Join-Path $DistDir "scripts") -Force
Write-Host "[OK] Copied helper scripts to dist/scripts" -ForegroundColor Green

# Copy documentation templates
$docFiles = @(
    "reports\STAGING_SCRIPT_HARDENING.md",
    "reports\OTG_STORAGE_COMPATIBILITY_REVIEW.md",
    "reports\SAFE_STAGING_REVIEW.md",
    "reports\GAME_EXECUTION_READINESS.md",
    "reports\PHONE_INSTALLATION_CHECKLIST.md",
    "reports\OFFLINE_BUILD_STATUS.md",
    "reports\ANDROID_ARTIFACT_MANIFEST.md",
    "reports\FINAL_ARCHITECTURE_DECISION.md"
)
foreach ($doc in $docFiles) {
    $src = Join-Path $RootDir $doc
    if (Test-Path $src) {
        Copy-Item $src (Join-Path $DistDir "docs") -Force
    }
}
Write-Host "[OK] Copied documentation to dist/docs" -ForegroundColor Green

# Compute SHA-256 for all artifacts in dist
Write-Host "Calculating SHA-256 checksums for dist bundle..." -ForegroundColor Yellow
$distFiles = Get-ChildItem -Path $DistDir -Recurse -File | Where-Object { $_.Name -ne "SHA256SUMS.txt" }
$checksumLines = @()
foreach ($f in $distFiles) {
    $hash = (Get-FileHash -Path $f.FullName -Algorithm SHA256).Hash
    $relPath = $f.FullName.Substring($DistDir.Length).TrimStart("\", "/")
    $checksumLines += "$hash  $relPath"
}
$checksumPath = Join-Path $DistDir "SHA256SUMS.txt"
$checksumLines | Out-File -FilePath $checksumPath -Encoding utf8
Write-Host "[OK] Generated $checksumPath ($($checksumLines.Count) files)" -ForegroundColor Green
Write-Host "Deployment bundle assembly completed successfully." -ForegroundColor Cyan
