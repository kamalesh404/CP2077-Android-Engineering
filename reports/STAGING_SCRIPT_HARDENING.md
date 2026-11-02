# STAGING SCRIPT HARDENING REPORT — CYBERPUNK 2077 ANDROID DEPLOYMENT

- **Audit Date:** 2026-10-27
- **Workspace:** `C:\CP2077-Android-Engineering`
- **Script Hardened:** [`scripts/Stage-GameData.ps1`](file:///C:/CP2077-Android-Engineering/scripts/Stage-GameData.ps1)
- **Automated Test Suite:** [`tests/Test-HardenedStaging.ps1`](file:///C:/CP2077-Android-Engineering/tests/Test-HardenedStaging.ps1)
- **Status:** **ALL 9 SAFETY DEFECTS REMEDIATED | 10/10 AUTOMATED REGRESSION TESTS PASSED**

---

## 1. Safety Defects Identified & Implemented Fixes

| # | Defect Identified in Audit | Risk Severity | Implemented Fix in `Stage-GameData.ps1` | Code Verification |
|---|---|---|---|---|
| **1** | **Hardcoded 65 GB Space Threshold** | **CRITICAL** | Replaced with dynamic exact byte calculation: scans all 171 target files (game files + compatibility setup) and adds an explicit `$SafetyMarginBytes` (default: 5.0 GB). Required free space = **71,073,082,004 bytes** (~66.19 GiB). Aborts safely before writing if free space is insufficient. | Gate 5 & Gate 6 |
| **2** | **Fragile Destination Path Resolution** | **HIGH** | Uses `[System.IO.Path]::GetFullPath()` and `[System.IO.Path]::GetPathRoot()` to extract root drive/volume. Tests destination writability by creating and deleting a GUID-named temporary probe file prior to staging. | Gate 2 & Gate 3 |
| **3** | **Unconditional Overwriting (`-Force`)** | **HIGH** | Removed unconditional overwrite. Implemented strict overwrite guard: scans destination `$destGameDir`; if files already exist, the script immediately aborts with `FAILED_OVERWRITE_REFUSED` unless the user explicitly passes `-AllowOverwrite`. | Gate 4 |
| **4** | **Unprotected Source Directory** | **CRITICAL** | Canonicalizes both `$GameSource` and `$DestinationPath`. Rejects identical destination paths, destination paths that are subdirectories of the game, and destination paths that are parents of the game (preventing accidental source corruption). | Gate 2 |
| **5** | **Lack of Per-File Copy Error Handling** | **HIGH** | Encapsulated all per-file copy operations inside `try/catch [System.Exception]`. If an I/O error or disconnected cable occurs, the loop breaks cleanly, records the failure, preserves all completed files, and never touches source files. | Gate 7 |
| **6** | **Missing Destination Checksums & Manifest** | **MEDIUM** | Upon staging completion, writes `$destGameDir\STAGED_MANIFEST.json` and `$destGameDir\STAGED_SHA256SUMS.txt` at the destination containing relative paths, byte counts, and SHA-256 hashes for all copied files. | Gate 8 |
| **7** | **Absence of Dry-Run Capability** | **MEDIUM** | Added `-DryRun` switch. Scans source and dist directories, outputs exact file counts, payload byte sizes, safety margin, and destination free space, and exits with status `DRY_RUN_PASSED` writing **zero bytes** to disk. | Dry-Run Short-Circuit |
| **8** | **Flagged Anomaly Exposure** | **HIGH** | Explicitly filters out `bin\x64\cyberpunk2077_addresses.json` (132 MB untrusted file). The file is classified as `SEALED_UNTRUSTED_ANOMALY` in the execution report and is never opened, read, or staged. | Gate 5 |
| **9** | **Audit Trail Logging Outside Steam Root** | **MEDIUM** | Generates a structured JSON report (`reports/STAGING_RUN_REPORT.json`) outside the Steam game installation, recording exact timestamps, file lists, omitted files, and pass/fail statuses. | `Save-ExecutionReport` |

---

## 2. Automated Regression Test Results

A dedicated automated test harness ([`tests/Test-HardenedStaging.ps1`](file:///C:/CP2077-Android-Engineering/tests/Test-HardenedStaging.ps1)) was constructed using isolated synthetic test files and temporary directories. **The actual Steam game directory was not used for testing.**

```text
==========================================================
 Running Automated Tests for Hardened Staging Script
==========================================================
 [PASS] Source Protection: Rejects Destination Identical to Source
 [PASS] Source Protection: Rejects Destination Overlapping Source Hierarchy
 [PASS] Destination Validation: Rejects Non-Existent Drive Root
 [PASS] Dry-Run Mode: Calculates Plan Without Writing to Destination
 [PASS] Security Gate: Flagged Anomaly Excluded and Classified as SEALED
 [PASS] Storage Math: Fails Safely When Destination Space < Required Payload + Margin
 [PASS] Overwrite Protection: Refuses to Overwrite Existing Content by Default
 [PASS] Overwrite Authorization: Proceeds Past Overwrite Gate with -AllowOverwrite
 [PASS] Destination Manifest: Writes STAGED_MANIFEST.json and STAGED_SHA256SUMS.txt
 [PASS] Source Immutability: Source Files Never Mutated, Moved, or Deleted
==========================================================
 Test Results: 10 / 10 Passed (100.0%)
==========================================================
```

---

## 3. Dry-Run Verification Against Actual Steam Installation

The hardened script was executed with `-DryRun` against the real Steam game directory:
`powershell.exe -ExecutionPolicy Bypass -File scripts/Stage-GameData.ps1 -DestinationPath "C:\CP2077-Android-Engineering\build\dry_run_test" -DryRun`

**Verified Execution Metrics:**
* **Files Selected for Staging:** 171 files (158 base game files + 13 Winlator/VKD3D setup files)
* **Files Omitted & Protected:** 2 files
  * `bin\x64\cyberpunk2077_addresses.json` (132,079,509 B — `SEALED_UNTRUSTED_ANOMALY`)
  * `REDlauncher-4.2.0.4.msi` (687,386,624 B — `OPTIONAL_REDIST_INSTALLER`)
* **Exact Staging Payload:** **61.19 GiB** (**65,704,372,884 bytes**)
* **Safety Margin Added:** **5.00 GiB** (**5,368,709,120 bytes**)
* **Total Destination Free Space Required:** **66.19 GiB** (**71,073,082,004 bytes**)
* **Destination Disk Free Space:** **78.81 GiB**
* **Result:** `DRY_RUN_PASSED` (Zero bytes written to destination; Steam source remains 100% unaltered).

---

## 4. Known Limitations & Operational Constraints

1. **Transfer Speed Limitation:** USB 2.0 / USB 3.0 file transfer speeds over phone MTP protocol typically average 30–45 MB/s. Copying the ~61.19 GiB payload will take approximately 25 to 35 minutes.
2. **Drive Unplug Risk:** If an external USB-OTG drive is unplugged during staging, the per-file `try/catch` will halt execution immediately and record `FAILED_MID_TRANSFER`. Staged files will be preserved, but the transfer must be resumed with `-AllowOverwrite` once reconnected.
3. **No Dynamic Decompression:** The script preserves CD Projekt Red's original Oodle-compressed `.archive` structure. Do not attempt zip extraction on archives.

---

## 5. Exact Staging Command for Future Execution

When an external drive (e.g. `E:\`, formatted exFAT with at least 72 GB free) is connected and approved:

```powershell
powershell.exe -ExecutionPolicy Bypass -File "C:\CP2077-Android-Engineering\scripts\Stage-GameData.ps1" -DestinationPath "E:\" -SafetyMarginBytes 5368709120
```

*(If re-running or updating an existing staging folder on the drive, add `-AllowOverwrite`.)*
