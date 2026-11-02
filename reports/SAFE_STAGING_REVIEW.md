# SAFE STAGING REVIEW — CYBERPUNK 2077 ANDROID DEPLOYMENT

- **Audit Date:** 2026-10-27
- **Workspace:** `C:\CP2077-Android-Engineering`
- **Script Audited:** [`scripts/Stage-GameData.ps1`](file:///C:/CP2077-Android-Engineering/scripts/Stage-GameData.ps1)
- **Source Target:** `C:\Games\steam\steamapps\common\Cyberpunk 2077` (v2.31, 61.81 GiB, 159 files, strictly read-only)
- **Execution Status:** **AUDIT ONLY — SCRIPT EXECUTION FROZEN PENDING REVIEW**

---

## 1. Staging Script Comprehensive Audit (`Stage-GameData.ps1`)

A line-by-line static analysis of `scripts/Stage-GameData.ps1` was conducted against the project's strict non-negotiable safety rules:

| Audit Criterion | Verified Script Behavior | Compliance Status | Findings / Notes |
|---|---|---|---|
| **Source Path Integrity** | Line 9 explicitly sets `$GameSource = "C:\Games\steam\steamapps\common\Cyberpunk 2077"`. | **VERIFIED** | Matches the exact legally owned Steam installation root. |
| **Read-Only Enforcement** | Script strictly issues `Get-ChildItem` and `Copy-Item -Path $src ...`. No `Remove-Item`, `Move-Item`, `Rename-Item`, or write streams target `$GameSource`. | **VERIFIED** | Original game installation cannot be modified or altered by this script. |
| **Steam State & Save Protection** | Zero references to `appmanifest_1091500.acf`, Steam registry keys, or `%USERPROFILE%\Saved Games\`. | **VERIFIED** | Personal saves and Steam configurations remain completely untouched. |
| **Sealed Anomaly Exclusion** | Lines 67–70 explicitly detect and omit `cyberpunk2077_addresses.json`. | **VERIFIED** | The unverified 132 MB file is skipped and never copied, opened, or executed. |
| **Destination Path Validation** | Line 23 inspects `(Get-Item $DestinationPath).PSDrive`. | **DEFECT IDENTIFIED** | Fails if `$DestinationPath` is a non-existent subfolder (e.g. `E:\Staging`). Requires path normalization. |
| **Overwrite Protection** | Lines 41, 42, 43, 52, and 80 utilize `-Force` on all `Copy-Item` invocations. | **DEFECT IDENTIFIED** | Unconditionally overwrites pre-existing destination files without user authorization. |
| **Disk Space Validation** | Line 28 checks `$freeBytes -lt 65000000000` (~60.53 GiB). | **DEFECT IDENTIFIED** | Threshold is too low. Game payload is 66.37 GB; script would allow transfer to fail halfway on a 65 GB drive. |
| **Transfer Error Handling** | File copying loop lacks `try/catch` exception handling for mid-stream I/O failures. | **DEFECT IDENTIFIED** | If the cable is disconnected or storage fills up, PowerShell terminates abruptly without recovery state. |
| **Destination Manifest Generation** | Only checks `Cyberpunk2077.exe` SHA-256; does not output a destination file ledger. | **DEFECT IDENTIFIED** | Does not provide a cryptographic checksum ledger for the other 157 staged files. |

---

## 2. Identified Risks & Required Code Fixes

Before `scripts/Stage-GameData.ps1` is authorized for execution, the following 5 safety fixes must be applied:

1. **Fix Space Threshold:** Increase minimum required free space from 65 GB to **72 GB** (allowing 66.4 GB game + 158 MB Winlator setup + 5 GB staging safety margin).
2. **Safe Destination Resolution:** Modify drive resolution to extract the root drive letter safely via `[System.IO.Path]::GetPathRoot($DestinationPath)` so non-existent target subdirectories do not cause crash exceptions.
3. **Overwrite Guard:** Remove unconditional `-Force`. Add an `-AllowOverwrite` switch and an interactive check to alert the user if destination files already exist.
4. **Resilient Copy & Error Handling:** Wrap per-file copy operations in `try/catch` blocks to track failed transfers, disk-full events, and partial files.
5. **Destination Integrity Manifest:** Automatically generate `STAGED_SHA256SUMS.txt` at the destination containing the hashes of all copied archives and binaries.

---

## 3. External Storage (USB-C OTG SSD) Feasibility & Evidence

A thorough technical investigation was conducted regarding using an **exFAT-formatted USB-C OTG SSD** with **Winlator 11.2** on **Android 15 (HONOR 90)**.

### 3.1 Documented OS & Filesystem Realities
* **Kernel & Filesystem Support:** Android 15 on Qualcomm Snapdragon platforms natively supports `exFAT` via the Linux kernel `exfat` driver. When plugged in, the drive is mounted at `/mnt/media_rw/XXXX-XXXX` and exposed via Storage Access Framework at `/storage/XXXX-XXXX/`.
* **Single File Size Limits:** Unlike FAT32 (which limits files to 4 GB), **exFAT has no practical file size limit**. This is critical because `basegame_5_video.archive` is **12.94 GiB** and `basegame_3_nightcity_gi.archive` is **11.05 GiB**. exFAT is mandatory.

### 3.2 Winlator Drive-Mapping Mechanism
* In Winlator 11.2 container settings (`Containers -> Settings -> Drives -> Add Drive`):
  * The GUI folder picker often cannot navigate into external OTG roots due to Scoped Storage picker restrictions.
  * **Supported Workaround:** Winlator allows **manually typing or pasting the raw string path** (e.g. `/storage/XXXX-XXXX/...`) into the path box and assigning it a drive letter (e.g., `D:`).
  * Wine then exposes this mount point to Windows executables as `D:\`.

### 3.3 Critical Android 15 Permission Boundary (Scoped Storage)
* **Manifest Inspection Finding:** In `dist/compatibility/Winlator_11.2.apk`, `AndroidManifest.xml` requests `READ_EXTERNAL_STORAGE` and `WRITE_EXTERNAL_STORAGE`, but **does NOT declare `MANAGE_EXTERNAL_STORAGE`** ("All files access").
* **Impact under Android 15:** Under standard Android 15 security, an app without `MANAGE_EXTERNAL_STORAGE` cannot read non-media files (`.exe`, `.archive`, `.dll`) at the root `/storage/XXXX-XXXX/`.
* **The Supported Solution:**
  Android explicitly whitelists an app's package-specific directory on external storage:
  $$\mathbf{/storage/XXXX-XXXX/Android/data/com.winlator/files/}$$
  Winlator's Linux environment has **full read and write access** to this directory on the external drive without requiring special system permission prompts!
* **Conclusion:** To ensure 100% reliable game execution without permission denials, game data on the USB-C SSD must be staged in:
  `/storage/XXXX-XXXX/Android/data/com.winlator/files/Cyberpunk2077`

---

## 4. Required Free Space & Safety Margins

| Storage Location | Base Game Size | Runtime Overhead | Recommended Free Space | Safety Margin |
|---|---|---|---|---|
| **External USB-C SSD** | 66.37 GB (61.81 GiB) | ~4 GB (Wine container temp & DXVK cache) | **At least 75 GB** | +8.6 GB buffer |
| **Phone Internal Storage (Alternative)** | 66.37 GB | ~6 GB (Container filesystem + shader cache) | **At least 80 GB** | +13.6 GB buffer |

*Note: The HONOR 90 currently has only **18 GiB free**. Internal staging is completely impossible until ~65+ GB is reclaimed. External USB-C SSD is the primary viable route.*

---

## 5. Deployment Artifact Verification Results

All 14 deployment artifacts in `C:\CP2077-Android-Engineering\dist` were re-audited against [`dist/SHA256SUMS.txt`](file:///C:/CP2077-Android-Engineering/dist/SHA256SUMS.txt). Zero redownloads were needed.

| Artifact Path in `dist/` | Size (Bytes) | Checksum Status | Verification Notes |
|---|---|---|---|
| `compatibility/Winlator_11.2.apk` | 157,549,075 | **MATCH (100%)** | `EA5C81BF0E5B90A6B9CCB8007121AB6738C8646A5A60B341CE0AC2B33F1D100A` |
| `config/winlator_cp2077.json` | 1,576 | **MATCH (100%)** | Configured for Turnip 26.2.0, Box64 0.4.4, VKD3D 2.14.1 |
| `config/vkd3d.conf` | 547 | **MATCH (100%)** | Disables ray tracing, limits descriptor heap |
| `config/dxvk.conf` | 287 | **MATCH (100%)** | Async compiler enabled |
| `tools/CP2077PreflightVerifier.jar` | 6,331 | **MATCH (100%)** | Java 21 standalone audit tool |
| `tools/CP2077TestHarness.jar` | 8,353 | **MATCH (100%)** | 5/5 regression unit tests passing |
| `scripts/Stage-GameData.ps1` | 4,291 | **MATCH (100%)** | Staging script (audited above) |

*The original game installation at `C:\Games\steam\steamapps\common\Cyberpunk 2077` remains 100% unaltered (executable SHA-256: `A7DE82945C03E041FC7339FCF9066224D98DB2F5D80FEA50F7947BB350A60991`).*

---

## 6. Exact Next Steps

Execution remains completely paused for your review:

1. **Review and Approve Script Hardening:** I will patch the 5 identified defects in `Stage-GameData.ps1` (threshold increase to 72 GB, safe path resolution, overwrite confirmation, resilient try/catch, and destination manifest generation).
2. **Select Staging Medium:** Connect an exFAT-formatted USB-C external drive (with at least 75 GB free) to the laptop.
3. **Execute Staging:** Run the hardened staging script to copy the game data and Winlator setup to the external drive.
4. **Physical Deployment:** Connect the drive to the HONOR 90 and import the pre-tuned container profile.
