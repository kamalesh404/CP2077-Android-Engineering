# COMPATIBILITY MATRIX — Cyberpunk 2077 on Android Architecture

- **Date:** 2026-10-27
- **Workspace:** `C:\CP2077-Android-Engineering`
- **Target Target SoC/GPU:** Qualcomm Snapdragon 7 Gen 1 Accelerated Edition (`SM7450`) / Adreno 644
- **Game Version:** Cyberpunk 2077 v2.31, Build 5294808, DirectX 12, Steam DRM + Denuvo Anti-Tamper

---

## 1. Technical Architecture Evaluation Matrix

| Architecture Route | Underlying Technology | Theoretical Viability | Laptop Feasibility | Device Feasibility | Legal & Safety Status | Composite Verdict |
|---|---|---|---|---|---|---|
| **Route A: Native Android Game Port** | Decompile x86_64 PE, rebuild REDengine 4 against Android NDK (ARM64/Vulkan) | **IMPOSSIBLE** | ❌ Blocked (No engine source code) | ❌ Blocked (Binary incompatible) | ❌ **PROHIBITED** (Requires reverse engineering & DRM cracking) | **BLOCKED** |
| **Route B1: Winlator Container** | Wine 9.x + Box64 + VKD3D-Proton 2.12 + Turnip Mesa driver | **CONDITIONALLY VIABLE** | ✅ Config templates generated | ⚠️ Untested (Storage shortfall + Adreno 644 DX12 performance unknown) | ✅ Fully legal (Uses owned game files without modification) | **PRIMARY CANDIDATE (CONDITIONAL GO)** |
| **Route B2: Termux / Box64 / Mobox** | PRoot / Chroot Ubuntu ARM64 + Box64 + DXVK/VKD3D | **LOW-TO-MEDIUM** | ✅ Scripts supported | ❌ High complexity, lack of standard GUI container for game pads | ✅ Fully legal | **FALLBACK CANDIDATE** |
| **Route B3: FEX-Emu / ARM64EC Wine** | FEX-Emu usermode x86_64 translation | **MEDIUM** | ⚠️ Linux host required | ❌ Kernel syscall requirements may conflict with standard Android 15 seccomp | ✅ Fully legal | **EXPERIMENTAL / DEFERRED** |
| **Route C: Project-Owned Tooling** | Java 21 / Android SDK / PowerShell / Git | **100% VIABLE** | ✅ Fully built & verified | ✅ Compatible with any Android 9.0+ device | ✅ 100% Project-owned & open-source | **ACTIVE & VERIFIED** |

---

## 2. Hardware Subsystem Compatibility

| Subsystem | Requirement for Cyberpunk 2077 | HONOR 90 Specification | Compatibility Assessment | Status |
|---|---|---|---|---|
| **Instruction Set Architecture (ISA)** | x86_64 (Intel/AMD) | ARMv8 / AArch64 (Cortex-A710 / A510) | Requires software binary translation (Box64 or FEX-Emu). ~30–50% CPU IPC translation penalty. | **PARTIALLY VERIFIED** |
| **Graphics API** | DirectX 12 (Feature Level 12_0) | Vulkan 1.1 (Vendor driver), Vulkan 1.3 (Turnip driver) | VKD3D-Proton translates D3D12 to Vulkan. Turnip supports Adreno 6xx/7xx, but Adreno 644 is a midrange GPU with limited bandwidth (877 GOps FP32). Expected framerate < 15 FPS at 720p low. | **UNVERIFIED / PROBABLE BOTTLENECK** |
| **Memory (RAM)** | 8 GB minimum (12 GB recommended) | 8 GB or 12 GB LPDDR5 | Device RAM is sufficient for baseline container allocation (4096 MB VRAM cap configured). | **VERIFIED** |
| **Storage Capacity** | ~66.37 GB (~61.81 GiB) | ~18 GiB free user space (204 GB / 222 GB used) | **Severe Shortfall:** Game exceeds free space by ~47 GB. Physical transfer impossible without cleanup. | **BLOCKED (Storage Shortfall)** |
| **Anti-Tamper (DRM)** | Denuvo Anti-Tamper + Steam DRM | Android Linux kernel translation | Denuvo anti-tamper performs CPUID, timing, and hypervisor detection. Highly prone to crashing under Box64 translation without official offline token validation. | **BLOCKED (DRM Gate)** |

---

## 3. Verdict Summary

- **Route A (Native Port)** must **NEVER** be pursued, claimed, or represented as achievable.
- **Route B (Compatibility Layer via Winlator)** is the **ONLY** structurally coherent route for running the user's legally owned game on Android.
- Successful execution of Route B is strictly gated by two external prerequisites:
  1. Phone storage expansion (at least 75 GB free required).
  2. Denuvo compatibility under ARM64 Box64/Wine translation.
