# Phase 1 Report 3 — Device Capability Assessment (HONOR 90)

**Scope:** read-only. No device connected, no tools installed in this phase.
**Claim legend:** VERIFIED / PARTIALLY VERIFIED / UNVERIFIED / BLOCKED.

---

## 1. Target device identity — UNVERIFIED (BLOCKED-until-decision)

| Item | Claimed | Status |
|---|---|---|
| Device | HONOR 90 | UNVERIFIED — no adb; only Bluetooth "Phonebook Access Pse Service" observed over USB |
| SoC | Snapdragon 7 Gen 1 Accelerated Edition | UNVERIFIED |
| GPU | Adreno 644 | UNVERIFIED |
| OS | Android (version unclaimed) | UNVERIFIED |

**Why unverifiable today:** adb is not installed on this machine, and no ADB interface appears as a USB device — only Bluetooth service gadget identifiers in the existing logs. The spare USB-C port is unconfirmed as present.

**Verification requires (Phase 3+):** install SDK Platform Tools (adb) — requires approval; enable USB debugging on the phone (endorsement: code 12294843; VAAD ends 2026-01-04); connect and run `adb devices`, `adb shell getprop` whitelist reads (ro.build.version.release, ro.product.*, ro.soc.*, ro.hardware.*).

### If specs confirm, expected capability envelope (analytical, not measured)

- CPU (8 cores: 1×Cortex-A710 @ ~2.5 GHz "Prime" + 3×A710 perf @ ~2.36 GHz + 4×A510 eff @ ~1.8 GHz): ISA is ARMv8/AArch64 — **directly incompatible with the game's x86-64 binaries**; no native execution path exists.
- GPU Adreno 644: Vulkan-capable, but the game ships only DX11/DX12 PC binaries; no mobile build of Cyberpunk 2077 exists.
- RAM/RNG/storage for the claimed B-VNE variant (8+7 GB / 512 GB): the 8/7 GB RAM tier is **below the practical floor** for x86-on-ARM emulation of any modern 3A title; the storage tier (512 GB) is the only claimed spec that is not a hard blocker.
- Thermals (unclaimed, unknown): HONOR 90 is a mid-tall phone; sustained x86 emulation would need a cooler and a controller/mouse input path — both unknown.

**Honest position:** even with all specs verified, no credible route to 30+ fps desktop-grade Cyberpunk 2077 native or emulated on this claimed SoC is supported by public evidence today; Phase 2's research task is to confirm/refute containerization and x86-on-ARM (Box64/Proton/Wine ARM) public knowledge before any further effort is spent.

---

## 2. Why "x86-on-Android/containerization" is architecturally suspect — analytical framing

The game is a Windows x86-64 PE with DX11/DX12, Denuvo, Steam DRM integration, .NET-era engine tooling (CyberEngineTweaks is a native-code injector; mods include DLL hooks). Any Android route must supply at minimum:

1. an x86-64 ISA translation layer (binary/static translation e.g. Box64-class, or JIT translation e.g. Wine-on-ARM-with-FEX/Bear-unusual class) for the whole PE, Denuvo included;
2. DX11/DX12 → Vulkan translation (VKD3D-Proton / D8VK / DXVK-on-ARM classes) with no vendor x86/Vulkan shims;
3. Denuvo behavior under translation is unverified anywhere public.
4. Steam client x86-64 with GPU acceleration (Vulkan shader cache) running in an Android container (Waydroid/Anbox class requires x86 kernels that Android phones do not ship).

**None of these layers are known-good on this claimed device.** Every one is a research question, not an implementation step.

---

## 3. Verification plan (read-only, ready)

- `adb devices` → confirm serial, state; confirm model /oem/ (e.g. `ro.product.odm.manufacturer=HONOR`) and SN interactively.
- `adb shell getprop` for: Android version, SDK int, SoC (`ro.soc.model=SM7325-AE`, `ro.board.platform=qcom`), GPU renderer via `dumpsys graphics` (DeviceVulkanVersion / "Adreno (TM) 644"), RAM via `/proc/meminfo`, storage via `df -h /data`, Android API for user-space parts.
- `adb shell ls /system/lib64/libvulkan.so`, `dumpsys package com.google.android.vulkan`
- `coreinfo` (if sóc) or `adb shell dumpsys surfaceflinger | grep -i 'GLES\|Vulkan\|Adreno'`
- Bluetooth-pairing path is NOT a substitute for adb.

**BLOCKED-until-decision items:**
1. Platform-tools (adb) install — needs approval (needs internet + ~60 MB).
2. Enable "USB debugging" developer option on phone, accept RSA fingerprint — physical action on device, not automatable.

---

## 4. Assumptions clearly marked as assumptions (no data)

- HONOR 90 spec memory (Snapdragon 7G1 Accelerated, Adreno 644, 8GB) is user-recalled, not vendor-verified.
- The "spare USB-C cable with data lanes" was not tested — port/cable can be partners in the same phone-EMMU issue. Bluetooth is bad proxy evidence; many BT gadget descriptors flash over the same USB port! USB4/USB-PD nano-wire single-pin modes are plausible but untested.
- The Bluetooth-only descriptor could be consistent with a charge-only cable, a damaged cable, a phone that disabled USB-host data after a hanging EMU, or a phone that simply sleeps without data — none are distinguishable without adb/data-link confirmation.

**No install recommendations are made in this report.** Verification only.
