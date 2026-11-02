# ANDROID ARTIFACT MANIFEST — Cyberpunk 2077 Android Engineering

- **Date:** 2026-10-27
- **Target Location:** `C:\CP2077-Android-Engineering\dist`
- **Integrity Baseline:** Cryptographic SHA-256 for all deployable project-owned deliverables.

---

## 1. Project-Owned Build Artifacts

| Relative Path in `dist/` | File Type | Version | Architecture | Size (Bytes) | SHA-256 Checksum | Build Status |
|---|---|---|---|---|---|---|
| `tools/CP2077PreflightVerifier.jar` | Executable JAR | 1.0.0 | Any (JVM 21+) | 6,331 | `37DBC096ECFCE2719B27830DF4E9789178E44EB8E2D560A812C451E91C68E6A7` | **BUILD VERIFIED** |
| `tools/CP2077TestHarness.jar` | Executable JAR | 1.0.0 | Any (JVM 21+) | 3,845 | `341A59BAA6F333C4FF630A657BC98759714856D34B806AE57D7A25EB58A593A1` | **BUILD VERIFIED** |
| `src/android-companion/` | Android App Source | 1.0.0 | Android ARM64/x86_64 | ~35 KB source | N/A (Directory) | **SOURCE IMPLEMENTED** (APK compilation blocked by missing SDK licenses) |

---

## 2. Configuration & Runtime Templates

| Relative Path in `dist/` | Type | Purpose | Size (Bytes) | Target Environment |
|---|---|---|---|---|
| `config/winlator_cp2077.json` | JSON | Winlator container profile for SM7450 / Adreno 644 (Turnip/Zink, VKD3D 2.12, Box64 stability preset) | ~1,100 | Winlator 8.0+ |
| `config/vkd3d.conf` | INI | VKD3D-Proton low-memory and Adreno driver stability overrides (disables DXR/Raytracing) | ~490 | VKD3D-Proton / Mesa Turnip |
| `config/dxvk.conf` | INI | Direct3D 11 fallback configuration with async shader compiler flags | ~260 | DXVK 2.3+ |

---

## 3. Deployment & Audit Scripts

| Relative Path in `dist/` | Script Language | Purpose | Size (Bytes) | Safety Status |
|---|---|---|---|---|
| `scripts/Verify-GameIntegrity.ps1` | PowerShell | Non-destructive audit of Steam install; verifies executable SHA-256 and seals anomaly | ~2,800 | **STRICTLY READ-ONLY** |
| `scripts/Analyze-AssetReduction.ps1` | PowerShell | Breakdown of `archive/pc/content` archives and storage feasibility calculation | ~3,300 | **STRICTLY READ-ONLY** |
| `scripts/Build-DeploymentBundle.ps1` | PowerShell | Automated packaging of `dist/` directory with `SHA256SUMS.txt` generation | ~1,800 | Workspace only |

---

## 4. Documentation & Deployment Guides

| Relative Path in `dist/` | Document Title | Description |
|---|---|---|
| `docs/PHONE_INSTALLATION_CHECKLIST.md` | Phone Installation Checklist | Step-by-step procedure for preparing storage, installing compatibility environment, transferring game data offline, and rolling back |
| `docs/OFFLINE_BUILD_STATUS.md` | Offline Build Status | Detailed report of toolchain status, build outputs, and Android SDK licensing requirements |
| `docs/FINAL_ARCHITECTURE_DECISION.md` | Final Architecture Decision | Exhaustive analysis of Route A (Native Port: BLOCKED) vs Route B (Compatibility Layer: CONDITIONAL) |

---

## 5. Proprietary Content Non-Redistribution Guarantee

In accordance with strict safety directives:
- **NO game executables (`Cyberpunk2077.exe`) are bundled.**
- **NO game data archives (`.archive`), audio, video, textures, or models are included.**
- **NO proprietary Denuvo, Steam DRM, or CDPR engine code is stored in `dist/`.**
- **NO user saves or personal credentials are accessed or exported.**
- All deliverables in `dist/` are 100% project-owned, open-standard, and legally redistributable.
