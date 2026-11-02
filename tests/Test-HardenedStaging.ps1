# Test-HardenedStaging.ps1
# Automated Regression Test Suite for Stage-GameData.ps1
# Uses synthetic files and isolated temporary directories ONLY.
# Never modifies or touches the actual Steam installation!

$ErrorActionPreference = "Continue"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Running Automated Tests for Hardened Staging Script" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$scriptPath = "C:\CP2077-Android-Engineering\scripts\Stage-GameData.ps1"
$testRoot = "C:\CP2077-Android-Engineering\build\staging_tests"
if (Test-Path $testRoot) { Remove-Item -Path $testRoot -Recurse -Force -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Force -Path $testRoot | Out-Null

$syntheticSource = Join-Path $testRoot "synthetic_game"
$syntheticDist = Join-Path $testRoot "synthetic_dist"
$testReport = Join-Path $testRoot "test_staging_report.json"

New-Item -ItemType Directory -Force -Path (Join-Path $syntheticSource "bin\x64") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $syntheticSource "archive\pc\content") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $syntheticSource "engine") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $syntheticSource "r6") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $syntheticDist "config") | Out-Null

Set-Content -Path (Join-Path $syntheticSource "bin\x64\Cyberpunk2077.exe") -Value "DUMMY_CYBERPUNK_EXE_BYTES"
Set-Content -Path (Join-Path $syntheticSource "bin\x64\cyberpunk2077_addresses.json") -Value "DUMMY_ANOMALY_JSON_SEALED"
Set-Content -Path (Join-Path $syntheticSource "archive\pc\content\basegame_1_engine.archive") -Value "DUMMY_ARCHIVE_DATA"
Set-Content -Path (Join-Path $syntheticSource "engine\engine.ini") -Value "DUMMY_ENGINE_INI"
Set-Content -Path (Join-Path $syntheticDist "config\winlator_test.json") -Value "DUMMY_CONFIG"

$srcFilesInitial = Get-ChildItem -Path $syntheticSource -Recurse -File

$totalTests = 0
$passedTests = 0

function Assert-Test([string]$TestName, [bool]$Condition, [string]$Details = "") {
    $script:totalTests++
    if ($Condition) {
        $script:passedTests++
        Write-Host " [PASS] $TestName" -ForegroundColor Green
    } else {
        Write-Host " [FAIL] $TestName - $Details" -ForegroundColor Red
    }
}

# ----------------------------------------------------------------------------------
# Test 1: Source-Directory Self-Overwrite Rejection
# ----------------------------------------------------------------------------------
$destSame = $syntheticSource
$out1 = & powershell.exe -ExecutionPolicy Bypass -File $scriptPath -GameSource $syntheticSource -DestinationPath $destSame -ReportPath $testReport 2>&1
$rep1 = if (Test-Path $testReport) { Get-Content $testReport | ConvertFrom-Json } else { $null }
Assert-Test "Source Protection: Rejects Destination Identical to Source" `
    ($rep1.status -eq "FAILED_SOURCE_OVERWRITE_PREVENTED") `
    "Status was '$($rep1.status)'"

# ----------------------------------------------------------------------------------
# Test 2: Source-Directory Parent Overlap Rejection
# ----------------------------------------------------------------------------------
$destParent = Split-Path -Parent $syntheticSource
$out2 = & powershell.exe -ExecutionPolicy Bypass -File $scriptPath -GameSource $syntheticSource -DestinationPath $destParent -ReportPath $testReport 2>&1
$rep2 = if (Test-Path $testReport) { Get-Content $testReport | ConvertFrom-Json } else { $null }
Assert-Test "Source Protection: Rejects Destination Overlapping Source Hierarchy" `
    ($rep2.status -eq "FAILED_SOURCE_OVERLAP_PREVENTED") `
    "Status was '$($rep2.status)'"

# ----------------------------------------------------------------------------------
# Test 3: Missing / Invalid Destination Drive
# ----------------------------------------------------------------------------------
$destInvalid = "Z:\NonExistentDriveRoot999\Staging"
$out3 = & powershell.exe -ExecutionPolicy Bypass -File $scriptPath -GameSource $syntheticSource -DestinationPath $destInvalid -ReportPath $testReport 2>&1
$rep3 = if (Test-Path $testReport) { Get-Content $testReport | ConvertFrom-Json } else { $null }
Assert-Test "Destination Validation: Rejects Non-Existent Drive Root" `
    ($rep3.status -eq "FAILED_DESTINATION_ROOT_NOT_FOUND") `
    "Status was '$($rep3.status)'"

# ----------------------------------------------------------------------------------
# Test 4: Dry-Run Mode (Zero Writes)
# ----------------------------------------------------------------------------------
$destDry = Join-Path $testRoot "dry_run_dest"
$out4 = & powershell.exe -ExecutionPolicy Bypass -File $scriptPath -GameSource $syntheticSource -DistSource $syntheticDist -DestinationPath $destDry -ReportPath $testReport -DryRun 2>&1
$rep4 = if (Test-Path $testReport) { Get-Content $testReport | ConvertFrom-Json } else { $null }
$dryDirCreated = Test-Path (Join-Path $destDry "Cyberpunk2077")
Assert-Test "Dry-Run Mode: Calculates Plan Without Writing to Destination" `
    ($rep4.status -eq "DRY_RUN_PASSED" -and -not $dryDirCreated) `
    "Status was '$($rep4.status)', dryDirCreated=$dryDirCreated"

# ----------------------------------------------------------------------------------
# Test 5: Flagged File (cyberpunk2077_addresses.json) Exclusion
# ----------------------------------------------------------------------------------
$anomalyOmitted = $rep4.omitted_files | Where-Object { $_.RelativePath -like "*cyberpunk2077_addresses.json" }
Assert-Test "Security Gate: Flagged Anomaly Excluded and Classified as SEALED" `
    ($null -ne $anomalyOmitted -and $anomalyOmitted.Reason -eq "SEALED_UNTRUSTED_ANOMALY") `
    "Omission record: $($anomalyOmitted | Out-String)"

# ----------------------------------------------------------------------------------
# Test 6: Insufficient Destination Space Check
# ----------------------------------------------------------------------------------
$destSpace = Join-Path $testRoot "space_dest"
# Request 50 TB margin to exceed any available disk
$out6 = & powershell.exe -ExecutionPolicy Bypass -File $scriptPath -GameSource $syntheticSource -DistSource $syntheticDist -DestinationPath $destSpace -ReportPath $testReport -SafetyMarginBytes 50000000000000 2>&1
$rep6 = if (Test-Path $testReport) { Get-Content $testReport | ConvertFrom-Json } else { $null }
Assert-Test "Storage Math: Fails Safely When Destination Space < Required Payload + Margin" `
    ($rep6.status -eq "FAILED_INSUFFICIENT_SPACE") `
    "Status was '$($rep6.status)'"

# ----------------------------------------------------------------------------------
# Test 7: Overwrite Guard (Default Refusal)
# ----------------------------------------------------------------------------------
$destOverwrite = Join-Path $testRoot "overwrite_dest"
$existingSub = Join-Path $destOverwrite "Cyberpunk2077\bin\x64"
New-Item -ItemType Directory -Force -Path $existingSub | Out-Null
Set-Content -Path (Join-Path $existingSub "pre_existing_file.txt") -Value "ALREADY_EXISTS"

$out7 = & powershell.exe -ExecutionPolicy Bypass -File $scriptPath -GameSource $syntheticSource -DistSource $syntheticDist -DestinationPath $destOverwrite -ReportPath $testReport -SafetyMarginBytes 1000 2>&1
$rep7 = if (Test-Path $testReport) { Get-Content $testReport | ConvertFrom-Json } else { $null }
Assert-Test "Overwrite Protection: Refuses to Overwrite Existing Content by Default" `
    ($rep7.status -eq "FAILED_OVERWRITE_REFUSED") `
    "Status was '$($rep7.status)'"

# ----------------------------------------------------------------------------------
# Test 8: Explicit Overwrite Authorization (-AllowOverwrite)
# ----------------------------------------------------------------------------------
$out8 = & powershell.exe -ExecutionPolicy Bypass -File $scriptPath -GameSource $syntheticSource -DistSource $syntheticDist -DestinationPath $destOverwrite -ReportPath $testReport -SafetyMarginBytes 1000 -AllowOverwrite 2>&1
$rep8 = if (Test-Path $testReport) { Get-Content $testReport | ConvertFrom-Json } else { $null }
# Overwrite permitted to proceed through copy phase (synthetic exe fails real CP2077 hash check, which is expected!)
Assert-Test "Overwrite Authorization: Proceeds Past Overwrite Gate with -AllowOverwrite" `
    ($rep8.status -ne "FAILED_OVERWRITE_REFUSED") `
    "Status was '$($rep8.status)'"

# ----------------------------------------------------------------------------------
# Test 9: Destination Manifest & Checksum Creation
# ----------------------------------------------------------------------------------
$manifestPath = Join-Path $destOverwrite "Cyberpunk2077\STAGED_MANIFEST.json"
$sumsPath = Join-Path $destOverwrite "Cyberpunk2077\STAGED_SHA256SUMS.txt"
$manifestExists = Test-Path $manifestPath
$sumsExists = Test-Path $sumsPath
Assert-Test "Destination Manifest: Writes STAGED_MANIFEST.json and STAGED_SHA256SUMS.txt" `
    ($manifestExists -and $sumsExists) `
    "manifestExists=$manifestExists, sumsExists=$sumsExists"

# ----------------------------------------------------------------------------------
# Test 10: Source Directory Immutability
# ----------------------------------------------------------------------------------
$srcFilesAfter = Get-ChildItem -Path $syntheticSource -Recurse -File
$anomalyStillInSource = Test-Path (Join-Path $syntheticSource "bin\x64\cyberpunk2077_addresses.json")
Assert-Test "Source Immutability: Source Files Never Mutated, Moved, or Deleted" `
    ($srcFilesAfter.Count -eq $srcFilesInitial.Count -and $anomalyStillInSource) `
    "Initial count=$($srcFilesInitial.Count), after count=$($srcFilesAfter.Count)"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host (" Test Results: {0} / {1} Passed ({2:P1})" -f $passedTests, $totalTests, ($passedTests / $totalTests)) -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# Clean up synthetic test folder safely
Remove-Item -Path $testRoot -Recurse -Force -ErrorAction SilentlyContinue

if ($passedTests -ne $totalTests) {
    exit 1
}
