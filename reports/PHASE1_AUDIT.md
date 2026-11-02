# PHASE 1 AUDIT — Cyberpunk 2077 Source Install

Date: 2026-10-23
Workspace: `C:\CP2077-Android-Engineering` (all artifacts here; the game install itself is never written to)
Method: read-only filesystem inspection only. No game file, Steam config file, save file, or registry value was modified during Phase 1.

**Mission reminder:** Phase 1 is read-only-first. Every claim below is classified: VERIFIED / PARTIALLY VERIFIED / UNVERIFIED / BLOCKED.

---

## 1. Install Identity

| Claim | Status | Evidence |
|---|---|---|
| Game root exists at `C:\Games\steam\steamapps\common\Cyberpunk 2077` | VERIFIED | directory list returned `archive`, `bin`, `engine`, `r6` subdirs plus launcher files |
| Single Steam library `C:\Games\steam` | VERIFIED | `libraryfolders.vdf` contains exactly one path entry with this game among apps 227300, 228980, 1091500, 1682970, 4252340 |
| Steam AppID 1091500 (Cyberpunk 2077) | VERIFIED | `appmanifest_1091500.acf` parsed and hashed |
| Steam AppID 1734410 (Phantom Liberty) installed | UNVERIFIED — treated as ABSENT | `appmanifest_1734410.acf` does not exist AND `archive\pc\ep1` Test-Path returned False → **Phantom Liberty NOT installed (base-only build)** |
| Build state | VERIFIED | StateFlags=4 (fully installed), buildid=20383525, depot 1091501 |
| Language | VERIFIED |english per manifest `language` key |
| Install on-disk size | PARTIALLY VERIFIED | observed 159 files / 61.81 GiB vs manifest SizeOnDisk=66,366,228,927 B (~61.81 GiB) — close agreement; discrepancy within filesystem-vs-manifest normal range |

Manifest SHA-256: `53C28F0AC35D52A0081F3DEB5811EC28892695F7E58F56F3EC7F23F1C1F32004`

## 2. Game Version

| Claim | Status | Evidence |
|---|---|---|
| Game version 2.31, build 5294808 | PARTIALLY VERIFIED | `bin\x64\Cyberpunk2077.exe` reports ProductVersion=2.31 / FileVersion=3.0.5294808; `version.txt` NOT FOUND at game root, so exact numeric build could not be cross-checked against a second authoritative source |
| 64-bit executable | VERIFIED | PE x64, 59,945,608 bytes |

## 3. Files / Dirs Present at Root

VERIFIED subdirectories: `archive`, `bin`, `engine`, `r6`. No `dlc` dir present.
Notable root files: `launcher-configuration.json`, `REDlauncher-4.2.0.4.msi`, `REDprelauncher.exe`.

## 4. Anomalies

1. **`bin\x64\cyberpunk2077_addresses.json` — 132,079,509 bytes (~132 MB).** This is not a vanilla-file-looking artifact for a shipped game build; origin and purpose are unknown (kind: reverse-engineering/guid/IDDB display file for debuggers or tooling). Flagged in `EVIDENCE_AND_UNKNOWNS.md` as an explicit unknown. It was **not opened** in Phase 1.
2. Phantom Liberty absence (see above) — marketing claims vs install reality.

## 5. User Data (observed names only, never read)

- Saves: `%USERPROFILE%\Saved Games\CD Projekt Red\Cyberpunk 2077` — 60 entries (AutoSave-0..19, EndGameSave-0..2, ManualSave-875..947, PointOfNoReturnSave-0..6, QuickSave-0..9, steam_autocloud.vdf, user.gls). Contents never read. Status: VERIFIED (directory+names), contents UNVERIFIED.
- Config dir `%LOCALAPPDATA%\RED\Cyberpunk 2077` — absent. Classified UNVERIFIED-absent (may be created on launch; absence recorded, not claimed impossible).

## 6. Toolchain Available Right Now

- VERIFIED: git 2.55.0.windows.2, gh 2.97.0, node v24.18.0, Python 3.12.7, JDK 21.0.12.1
- MISSING: adb, fastboot, docker, cmake, ninja, clang, gcc, rustc, cargo, go, ffmpeg, scrcpy, jq, 7z, openssl
- BLOCKED-until-decision: installing adb (requires user approval). Phone-side verification therefore stays UNVERIFIED.
- BUG-NOTED: `npm` / `npx` .ps1 wrappers are blocked by PowerShell execution policy; use `npm.cmd` or change policy (approval needed).

## 7. Hardware Baseline

MSI Cyborg 15 A12UCX — i5-12450H (8C/12T), RTX 2050 4 GB (4096 MiB, driver 610.78), RAM 15.71 GB, Windows 11 build 26200, C: 86.7 GB free of 456.4 GB.

## 8. Phase 1 Verdict

- Install: genuine Steam copy, base-only v2.31, fully installed, English. Safe baseline.
- Phone: HONOR 90, claimed Snapdragon 7 Gen 1 Accelerated Edition / Adreno 644 — still UNVERIFIED (no adb).
- Deliverables written: this file, `SOURCE_INSTALLATION_SAFETY.md`, `DEVICE_CAPABILITY_ASSESSMENT.md`, `EVIDENCE_AND_UNKNOWNS.md`, `README.md`, `.gitignore`.
- Next: Phase 2 — read-only research (containerization/proton/x86-on-Android feasibility). No installs, builds, transfers, or benchmarks without explicit user approval each phase.
