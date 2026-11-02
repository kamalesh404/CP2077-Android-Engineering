# Cyberpunk 2077 — Android Engineering Mission

Engineering workspace and research repository for exploring local execution of a legally owned Steam copy of **Cyberpunk 2077** (Windows x86-64) on an **HONOR 90** Android phone (Qualcomm Snapdragon 7 Gen 1 Accelerated Edition / Adreno 644) without streaming.

---

## ⚠️ Mission Safety & Legal Guardrails

- **Legally Owned Copy Only:** Targets the unmodified base Steam install at `C:\Games\steam\steamapps\common\Cyberpunk 2077` (v2.31, Build 5294808, 61.81 GiB).
- **Strictly Non-Destructive & Read-Only:** The original Steam game directory is treated as read-only. No files, saves, or Steam state are ever modified, moved, or deleted.
- **No DRM Circumvention:** Denuvo Anti-Tamper and Steam DRM are not bypassed or cracked.
- **Zero Proprietary Redistribution:** This repository contains **zero** proprietary game binaries (`.exe`), archives (`.archive`), audio/video files, textures, models, saves, or credentials. It contains only project-owned code, configs, test suites, and documentation.
- **No False Port Claims:** Distinguishes compatibility layer execution (Winlator / Box64 / Wine / VKD3D) from a native game port. Route A (native port) is documented as technically blocked due to proprietary REDengine source code unavailability.

---

## 📁 Repository Structure

```text
CP2077-Android-Engineering/
├── config/                               # Container & graphics translation profiles
│   ├── winlator_cp2077.json              # Winlator 11.2 container profile (SM7450 / Adreno 644)
│   ├── vkd3d.conf                        # VKD3D-Proton low-memory and Adreno overrides
│   └── dxvk.conf                         # DXVK Direct3D 11 fallback configuration
├── reports/                              # Detailed technical audits and feasibility reports
│   ├── FINAL_PROJECT_STATUS.md           # Executive project summary and blocker ledger
│   ├── GAME_EXECUTION_READINESS.md       # Winlator 11.2 readiness & execution path analysis
│   ├── STAGING_SCRIPT_HARDENING.md       # Audit and remediation report for Stage-GameData.ps1
│   ├── OTG_STORAGE_COMPATIBILITY_REVIEW.md# Android 15 & Winlator USB-OTG exFAT storage review
│   ├── SAFE_STAGING_REVIEW.md            # Static safety audit of staging workflows
│   ├── FINAL_ARCHITECTURE_DECISION.md    # Route A (Blocked) vs Route B (Conditional GO)
│   ├── COMPATIBILITY_MATRIX.md           # Subsystem-by-subsystem hardware & translation matrix
│   ├── DEVICE_AND_STORAGE_READINESS.md   # Storage deficit mathematics and phone profile
│   ├── ASSET_REDUCTION_FEASIBILITY.md    # Analysis of archive trimming (proves 47+ GB gap)
│   ├── OFFLINE_BUILD_STATUS.md           # Offline build and toolchain verification
│   └── PHONE_INSTALLATION_CHECKLIST.md   # Step-by-step phone deployment and rollback checklist
├── scripts/                              # Project-owned deployment and verification scripts
│   ├── Stage-GameData.ps1                # Hardened, read-only staging tool with safety gates
│   ├── Verify-GameIntegrity.ps1          # Non-destructive file integrity and hash auditor
│   ├── Analyze-AssetReduction.ps1        # Archive breakdown and storage deficit evaluator
│   ├── Build-DeploymentBundle.ps1       # Distribution packager with SHA256SUMS generator
│   └── lib/AndroidDevice.ps1             # Safe ADB communication wrapper
├── src/                                  # Project-owned source code
│   ├── android-companion/                # Native Android hardware/storage auditor app
│   └── tools/                            # Standalone Java tools
│       ├── CP2077PreflightVerifier.java  # Preflight verification and storage deficit checker
│       └── TestHarness.java              # Automated regression test suite
├── tests/                                # Automated test scripts
│   └── Test-HardenedStaging.ps1          # 10-point regression suite for Stage-GameData.ps1
└── tools/
    └── inspect_dex.py                    # Static Dalvik bytecode inspector for Winlator analysis
```

---

## 🔬 Key Engineering Findings

1. **Storage Deficit & Solution:**
   - Base game payload: **61.19 GiB** (**65,704,372,884 bytes**, 158 files).
   - Target phone free space: **~18 GiB** (~47 GB shortfall).
   - Asset reduction analysis proved that non-destructive trimming saves < 150 MB.
   - **Solution:** External **USB-C OTG SSD formatted exFAT** (bypassing Android 15 FAT32 4 GB file limits and internal storage constraints).
2. **Android 15 Scoped Storage Permission Boundary:**
   - Winlator 11.2 lacks `MANAGE_EXTERNAL_STORAGE`.
   - Native POSIX access is permitted under Android 15 by staging game data inside:
     `/storage/XXXX-XXXX/Android/data/com.winlator/files/Cyberpunk2077`
3. **Execution Runtime Profile:**
   - **Container:** Winlator 11.2 (Box64 v0.4.4 + Wine 9.2 vanilla + VKD3D-Proton 2.14.1 + Mesa Turnip 26.2.0).
   - **Performance Ceiling:** Snapdragon 7 Gen 1 / Adreno 644 (877 GFLOPS FP32) provides entry-to-midrange emulation capabilities (estimated 5–15 FPS).
   - **Primary Execution Blocker:** Denuvo Anti-Tamper runtime behavior under ARM64 usermode translation.

---

## 🛠️ Usage & Verification

### Running the Preflight Verifier (Java)
```bash
javac -d build/classes src/tools/CP2077PreflightVerifier.java
java -cp build/classes com.cp2077.tools.CP2077PreflightVerifier --test
```

### Running the Hardened Staging Regression Suite
```powershell
powershell.exe -ExecutionPolicy Bypass -File tests/Test-HardenedStaging.ps1
```

### Running a Safe Staging Dry-Run
```powershell
powershell.exe -ExecutionPolicy Bypass -File scripts/Stage-GameData.ps1 -DestinationPath "E:\" -DryRun
```

---

## ⚖️ License

Project-owned scripts, configurations, and documentation are licensed under the MIT License.
Cyberpunk 2077 is a registered trademark of CD PROJEKT S.A. All rights reserved.
