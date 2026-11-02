# Phase 1 Report 4 — Evidence and Unknowns Ledger

**Scope:** read-only artifacts observed on this machine during Phase 1. Nothing was opened, modified, or executed.
**Claim legend:** VERIFIED / PARTIALLY VERIFIED / UNVERIFIED / BLOCKED.

---

## 1. Install evidence

| Item | Value | Status |
|---|---|---|
| Game path | `C:\Games\steam\steamapps\common\Cyberpunk 2077` | VERIFIED (dirs exist; counts at `dir /a /s`) |
| Version string | 2.31 (recalled, no metadata retour) | PARTIALLY VERIFIED — BuildID `20383525` in `appmanifest_1091500.acf` |
| PE binary | `bin\x64\Cyberpunk2077.exe` | VERIFIED; PE+ x64, size 59,945,608, CompileSt ??? (not decoded; not opened) |
| `bin\x64\version.txt` | expected, **not observed** | BLOCKED-unknown existence |
| `bin\x64\version.def` | expected, **not observed** | BLOCKED-unknown existence |
| Depot list | single depot 1091501, manifest 5294808 | VERIFIED from appmanifest fields |
| StateFlags | 4 (fully installed) | VERIFIED |
| Installed size (manifest `SizeOnDisk`) | 66,366,228,927 B (~61.8 GiB) | VERIFIED |
| Physical size on disk | ~61.81 GiB (159 files + dirs enumerated) | VERIFIED |
| Root dirs observed | `archive`, `bin`, `engine`, `r6` — no `dlc` | VERIFIED |
| Phantom Liberty (AppID 1734410) | `appmanifest_1734410.acf` absent; `archive\pc\ep1` absent | VERIFIED (absence) — base-only install |
| `appmanifest_1091500.acf` | Steam-internal; read-only, never modified | VERIFIED read; SHA-256 `53C28F0AC35D52A0081F3DEB5811EC28892695F7E58F56F3EC7F23F1C1F32004` recorded |
| Steam libraries | Only `C:\Games\steam` in `libraryfolders.vdf`; apps: 227300, 228980, 1091500, 1682970, 4252340 | VERIFIED read-only |

**Anomaly (unknown):** `bin\x64\cyberpunk2077_addresses.json`, 132,079,509 B — unknown origin, not opened, not used. Flagged as explicit unknown; no action taken Phase 1.

---

## 2. Save-data evidence

| Item | Value | Status |
|---|---|---|
| Saves path | `%USERPROFILE%\Saved Games\CD Projekt Red\Cyberpunk 2077` | VERIFIED (60 entries names-only) |
| Save names present | AutoSave-0..19, EndGameSave-0..2, ManualSave-875..947, PointOfNoReturnSave-0..6, QuickSave-0..9, `steam_autocloud.vdf`, `user.gls` | VERIFIED (names-only; contents NEVER read) |
| `%LOCALAPPDATA%\RED\Cyberpunk 2077` | absent | VERIFIED (absence) |

Saves were listed for Phase-4 restore planning only — contents never opened per safety policy.

---

## 3. Hardware evidence (laptop)

| Item | Value | Status |
|---|---|---|
| Machine | MSI Cyborg 15 A12UCX | VERIFIED from user info |
| CPU | i5-12450H, 8C/12T, x86_64 | VERIFIED |
| GPU | NVIDIA RTX 2050 4 GB (4096 MiB, driver 610.78) | VERIFIED |
| RAM | 15.71 GB total | VERIFIED |
| Windows | build 26200 | VERIFIED |
| Disk | C: 86.7 GB free of 456.4 GB | VERIFIED |

Implication for Phase 4: RTX 2050 4 GB VRAM is a **hard practical ceiling** for any 4K+ desktop gaming; it is also the only local machine available for building/transferring artifacts.

---

## 4. Toolchain evidence

| Item | Availability |
|---|---|
| git 2.55.0.windows.2 | present |
| gh 2.97.0 | present |
| node v24.18.0 | present |
| Python 3.12.7 | present |
| JDK 21.0.12.1 | present |
| npm / npx | installed but `.ps1` blocked by PowerShell execution policy; use `npm.cmd`/`npx.cmd` or change policy (approval needed) |
| adb, fastboot, docker, cmake, ninja, clang, gcc, rustc, cargo, go, ffmpeg, scrcpy, jq, 7z, openssl | **NOT installed** |

---

## 5. Explicit unknowns (carried into Phase 2+)

1. `cyberpunk2077_addresses.json` (132 MB) — purpose and origin unknown; treat as hostile/foreign until identified.
2. Phone identity (HONOR 90, SWG7G1-AE, Adreno 644, Android version, RAM/storage) — all UNVERIFIED without adb.
3. Whether ANY credible public containerized/Proton/x86-on-ARM pipeline for this game class exists on a Snapdragon-A710 Android-phone-class device — research question, not yet investigated.
4. Existence of `version.txt` / `version.def` inside `bin\x64`.
5. Whether the spare USB-C procedure tests data lanes (passthrough-cable vs charge-cable vs disabled-USB-data on phone).
6. Windows "Honor Virtual Display Device" driver trace in the machine (from earlier logs) — provence and timeline unknown; irrelevant to Phase 1 but noted for machine hygiene later.

No write occurred to the game install, Steam state, saves, registry, or phone in Phase 1.
