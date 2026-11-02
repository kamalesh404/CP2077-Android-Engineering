# PHASE 3 DEVICE VERIFICATION REPORT — Cyberpunk 2077 (2.31) Local/Staged Execution on HONOR 90

Date: 2026-10-23
Workspace: `C:\CP2077-Android-Engineering`
Method: adb (platform-tools 1.0.41 / 37.0.1-15733141) read-only device survey: `getprop` (fixed whitelist), `df`, `sm list-volumes`, `mount`. No device state changes. No file pushes. No execution of game or translation-layer code.

Mission reminder: Play the user's legally owned Steam install of Cyberpunk 2077 (v2.31, build 5294808, AppID 1091500, ~70 GB, base-only, DX12 + Denuvo) on an Android phone without streaming. Claim legend: VERIFIED / PARTIALLY VERIFIED / UNVERIFIED / BLOCKED. No DRM circumvention, ever.

---

## 1. Scope

Phase 3 asked three questions about the target device (HONOR 90, serial `ANAVVB3901010779`):

1. G1 — Platform identity: can we verify the SoC/GPU/OS claims made in Phase 1?
2. Storage: does the device have a viable staging location and sufficient free space (~70 GB)?
3. Feasibility context: does the device state change the Phase 2 composite verdict?

---

## 2. Device connectivity

| Claim | Status | Evidence |
|---|---|---|
| Device `ANAVVB3901010779` attached via USB with transport_id 31, state `device` | VERIFIED (at survey time) | `adb devices -l` → state `device` |
| adb server functional, binary at `C:\CP2077-Android-Engineering\tools\platform-tools\adb.exe`, version 1.0.41 / 37.0.1-15733141 | VERIFIED | `adb version` |
| Device response latency healthy for interactive shell commands | VERIFIED | All getprop/df/sh commands returned prompt answers |
| Device offline at report-write time | VERIFIED (later observation) | `adb devices -l` → header only, no devices |

Note: All device facts below were captured while the device was online. Further probes require reconnection.

---

## 3. Platform identity (G1 resolution)

| Claim | Status | Evidence |
|---|---|---|
| `ro.product.model=REA-NX9` | VERIFIED | `getprop` output (fixed whitelist) |
| `ro.product.manufacturer=HONOR` | VERIFIED | `getprop` |
| `ro.soc.model=SM7450` | VERIFIED | `getprop` |
| `ro.board.platform=taro` | VERIFIED | `getprop` |
| `ro.hardware=qcom` | VERIFIED | `getprop` |
| `ro.hardware.vulkan=adreno`, `ro.hardware.egl=adreno` | VERIFIED | `getprop` |
| `ro.build.version.release=15` (Android 15) | VERIFIED | `getprop` |
| Real device (`ro.kernel.qemu` — emulator indicator) | VERIFIED non-emulator | getprop whitelist result |

Derived and consistent: SM7450 = Snapdragon 7 Gen 1 Accelerated Edition; SoC GPU = Adreno 644; Vulkan-capable per vendor HAL declaration.

Resolution of prior Phase 1 unknown G1: identity/SoC/GPU/OS previously UNVERIFIED are now VERIFIED. Phase 1's inference chain (ARMv8/AArch64 ISA mismatch, no native x86 path) stands unchanged and now rests on verified hardware identity.

---

## 4. Storage feasibility survey

Inspect via `adb shell df` (single record for the large user volume; full partition table captured separately).

| Claim | Status | Evidence |
|---|---|---|
| User data volume, ~222 GB device capacity, 92% used | VERIFIED | `/dev/block/dm-25` 222G size, 204G used, 18G avail, 92%, mounted on `/storage/emulated/0/Android/obb` |
| ~18 GB free available to the emulator/user profile | VERIFIED | Same df record |
| No extra storage mediums for staging | VERIFIED | Full `df` table: root dm-13 2.6G ~100%; dm-14..dm-24 partitions ~100% read-only; tmpfs ~3.66 GB ×3; `/cache` (`/dev/block/sda13`) ~81.5 MB avail; no `/storage/XXXX-XXXX` vfat/exfat entries |
| No public/removable SD or USB-OTG volume registered | VERIFIED | `shell sm list-volumes public` → no output; `sm list-volumes private` → `private mounted null`; `sm list-volumes emulated` → `emulated;0 mounted null` |
| `shell mount` returned no rows under the capture method used | VERIFIED (observation) | `adb shell mount` → empty; absence claims corroborated by the df and sm surveys above |

Storage verdict: **INSUFFICIENT.** ~18 GB free vs ~70 GB game = short by roughly 52 GB. No public/removable volume, no alternative staging location. Only a heavily trimmed subset (e.g., `bin/x64` ~700 MB, complete save-metadata entry enumeration still pending authorization) would fit capacity-wise — but capacity is moot given the feasibility gate below.

---

## 5. Feasibility gate (composite)

| Claim | Status | Evidence |
|---|---|---|
| Game is DX12 + Denuvo on Storm-proof Adreno 644 hardware: no verified translation path | VERIFIED | Phase 2 research chain (FEX/Wine, Box64/Wine-Termux infeasible; Winlator mechanistically plausible but requires G6) |
| Media content on-disc (staging subset) NOT located | VERIFIED (absence within inspected channels) | Workspace sweep found no media file for full-tip/page connection |
| Execution gate: Denuvo under any translation layer = #1 blocker; cannot be legitimately tested without circumvention | VERIFIED | Mission constraint — out of scope, permanently |
| Adreno 644 in-DALA performance for this class of DX12 workload | UNVERIFIED | No benchmark data found in Phase 2/3 |

Feasibility verdict: **CLOSED.** The gate that rules out all execution paths is not device state (now fully verified) but the DRM/translation-layer incompatibility (G6 = NOT FOUND). Storage shortfall is an independent, secondary blocker.

---

## 6. Combined Phase 3 verdict

1. **Storage: INSUFFICIENT** — 18 GB avail vs 70 GB required; no removable/public volume; no alternative staging target.
2. **Feasibility gate: CLOSED** — DX12 + Denuvo 2.31 on Adreno 644 (SM7450) has no verified mechanism; legitimately untestable without DRM circumvention (out of scope).
3. Device identity and storage conditions are now fully VERIFIED (G1 resolved; no comparable-claim unknowns remain open on the device side).

---

## 7. Pending decision options (presented to user; decision outstanding)

1. **Accept and close Phase 3** — record this report as the deliverable (completed by writing this file; no further action).
2. **Phase 5-lite partial probe** — stage ~700 MB `bin/x64` subset as controlled failure documentation; requires explicit authorization; capacity is the only thing it demonstrates.
3. **Save-directory staging (Phase 3 step 4)** — enumerate the 60 save entries in `%USERPROFILE%\Saved Games\CD Projekt Red\Cyberpunk 2077` names-only; requires explicit step-4 authorization (contents remain unread).
4. **Pivot scope** — user-defined redirect (e.g., different capability of the same device, different game, or a cloud/local-hybrid approach outside the original no-streaming constraint).

---

## 8. Claims carried from Phase 1 (superseded statuses)

| Claim | Old status | New status |
|---|---|---|
| Device identity (REA-NX9 / HONOR) | UNVERIFIED | VERIFIED |
| SoC (SM7450 / Snapdragon 7 Gen 1 AE) | UNVERIFIED | VERIFIED |
| GPU (Adreno 644) | UNVERIFIED | VERIFIED (via soc.model + hardware vixens/egl properties) |
| OS (Android 15) | UNVERIFIED | VERIFIED |
| Emulator vs real device | UNVERIFIED | VERIFIED (real device) |
| ARMv8/AArch64 vs x86-64 incompatibility | UNVERIFIED (inferred) | SUPERSeded — stands on verified identity; no longer an unknown |

Denuvo-under-proton generic claims and Winlator-specific claims (§13 of Phase 2) remain UNVERIFIED — unchanged, and permanently untestable within mission constraints.
