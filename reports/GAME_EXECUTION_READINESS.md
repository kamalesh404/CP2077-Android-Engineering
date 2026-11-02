# GAME EXECUTION READINESS — CYBERPUNK 2077 ON ANDROID

- **Date:** 2026-10-27
- **Workspace:** `C:\CP2077-Android-Engineering`
- **Target Device:** HONOR 90 (`REA-NX9`) — Qualcomm Snapdragon 7 Gen 1 Accelerated Edition (`SM7450`), Adreno 644, Android 15
- **Original Steam Source:** `C:\Games\steam\steamapps\common\Cyberpunk 2077` (v2.31, Build 5294808, 61.81 GiB, 159 files, strictly read-only)
- **Primary Goal:** Local execution of legally owned Cyberpunk 2077 on Android (No streaming, No cloud gaming).
- **Execution Level Status:** **COMPATIBILITY ENVIRONMENT PREPARED (OFFLINE) | GATED BY PHYSICAL STORAGE & DENUVO RUNTIME**

---

## 1. Actual Game-Running Software Prepared

Rather than relying on experimental custom helper apps, the project has acquired and verified the premier, production-grade Android compatibility application:

* **Application:** **Winlator 11.2 (v11.2.0)**
* **Official Publisher:** BrunoDev85 ([github.com/brunodev85/winlator](https://github.com/brunodev85/winlator))
* **Target Architecture:** Android ARM64 (`aarch64`)
* **Core Emulation & Translation Stack (Verified Inside Package):**
  1. **CPU Binary Translation:** `Box64 v0.4.4` (`assets/box64/box64-0.4.4.tzst`)
     - Implements dynamic x86_64 to ARM64 binary translation (Dynarec).
     - Configured with `BOX64_DYNAREC_SAFEFLAGS=1`, `BOX64_STRONG_MEM=1`, and `BOX64_MAXCPU=4` to handle REDengine 4's multithreaded task scheduler and PhysX3 memory synchronization.
  2. **DirectX 12 Graphics Translation:** `VKD3D-Proton 2.14.1` (`assets/dxwrapper/vkd3d-2.14.1.tzst`)
     - Translates Direct3D 12 API calls and HLSL shader bytecode directly to Vulkan 1.3 SPIR-V.
     - Custom override profile [`dist/config/vkd3d.conf`](file:///C:/CP2077-Android-Engineering/dist/config/vkd3d.conf) forces `vkd3d_raytracing=0` and limits descriptor heaps to 65,536 to prevent mobile VRAM exhaustion.
  3. **Direct3D 11 Fallback:** `DXVK 2.4.1` (`assets/dxwrapper/dxvk-2.4.1.tzst`)
  4. **GPU Vulkan Driver:** `Mesa Turnip 26.2.0` (`assets/graphics_driver/turnip-26.2.0.tzst`)
     - Open-source Qualcomm Adreno driver providing native Vulkan 1.3 capabilities on Snapdragon Adreno 6xx/7xx hardware (specifically Adreno 644).
  5. **OS API Translation:** `Wine 9.2 vanilla x86_64`
  6. **Input Management:** Native Android multi-touch virtual gamepad + XInput raw controller mapping.

---

## 2. Genuinely Existing APKs and Artifact Locations

No synthetic or empty APK targets are claimed. The following binary packages genuinely exist on the laptop and are ready for deployment:

| Deliverable Name | File Type | Actual On-Disk Path | Size (Bytes) | SHA-256 Checksum | Origin / Verification |
|---|---|---|---|---|---|
| **Winlator 11.2 APK** | Android Package (`.apk`) | [`dist/compatibility/Winlator_11.2.apk`](file:///C:/CP2077-Android-Engineering/dist/compatibility/Winlator_11.2.apk) | 157,549,075 | `EA5C81BF0E5B90A6B9CCB8007121AB6738C8646A5A60B341CE0AC2B33F1D100A` | **Official Google/GitHub Release** (Matches official release digest exactly) |
| **Preflight Verifier** | Standalone Java JAR | [`dist/tools/CP2077PreflightVerifier.jar`](file:///C:/CP2077-Android-Engineering/dist/tools/CP2077PreflightVerifier.jar) | 6,331 | `37DBC096ECFCE2719B27830DF4E9789178E44EB8E2D560A812C451E91C68E6A7` | **Project-Owned** (Compiled with JDK 21; audits local Steam install) |
| **Test Harness** | Standalone Java JAR | [`dist/tools/CP2077TestHarness.jar`](file:///C:/CP2077-Android-Engineering/dist/tools/CP2077TestHarness.jar) | 3,845 | `E9B4FCF40F24DCFD1C02DD9CE722B3B47FAF5BACDE68D9719B8B35C75CC96E87` | **Project-Owned** (5/5 automated unit tests passed) |
| **Container Profile** | JSON Configuration | [`dist/config/winlator_cp2077.json`](file:///C:/CP2077-Android-Engineering/dist/config/winlator_cp2077.json) | 1,288 | `132718E17A748957EEA419992BE6E35F971E86663F19CF5C99264585B3386001` | **Project-Owned** (Tuned for Turnip 26.2.0 + VKD3D 2.14.1 + SM7450) |

---

## 3. Technical Credibility of Full Game Execution Path

### 3.1 Structural Compatibility
* **Architecture:** The path is structurally valid. Winlator 11.2 bundles Box64 0.4.4, Wine 9.2, and VKD3D 2.14.1, which together satisfy the x86_64 Windows PE + DirectX 12 API requirements of `Cyberpunk2077.exe`.
* **Vulkan Support:** Snapdragon 7 Gen 1 (SM7450) contains the Adreno 644 GPU. Turnip 26.2.0 exposes Vulkan 1.3 on this hardware, fulfilling the driver requirements for VKD3D-Proton.

### 3.2 Performance Reality & Hardware Bottlenecks
* **GPU Compute:** Adreno 644 delivers **877 GFLOPS (FP32)**. For comparison, the Steam Deck GPU delivers 1,600 GFLOPS and runs Cyberpunk 2077 at 30–40 FPS at 720p Low with FSR 2.1. On Adreno 644, emulating DX12 through VKD3D will result in an estimated **5 to 15 FPS**, with significant stuttering in crowded Night City zones.
* **Thermal Throttling:** Extended CPU/GPU translation workloads on passively cooled phones will induce thermal throttling after 5–10 minutes of execution.

### 3.3 Critical Blocker: Denuvo Anti-Tamper & Steam DRM
* `Cyberpunk2077.exe` v2.31 is compiled with Steam DRM and Denuvo Anti-Tamper.
* Denuvo performs low-level CPUID, hypervisor, and thread-timing checks. Under usermode x86_64-to-ARM64 emulation, these checks frequently trigger protection faults, causing silent termination or crash loops before reaching the main menu.
* **Safety Mandate:** Under our strict charter, DRM circumvention, cracks, or anti-tamper patching are **permanently prohibited**. The game must launch through legitimate Steam token validation.

---

## 4. Storage & Transfer Requirements

### 4.1 Storage Math Breakdown
* **Original Steam Game on Laptop:** **66,366,228,927 bytes** (**61.81 GiB** / ~66.37 GB).
* **Working Runtime Headroom:** **~70–75 GB** (Game archives + Wine container filesystem + Mesa shader cache + temporary swap).
* **HONOR 90 Internal Free Storage:** **~18 GiB** (92% used, ~204 GB used of 222 GB partition).
* **Storage Deficit:** **47.04 GB Shortfall**.

### 4.2 Viable Solutions (No Game Asset Destruction)
* Non-destructive asset removal was analyzed in [`reports/ASSET_REDUCTION_FEASIBILITY.md`](file:///C:/CP2077-Android-Engineering/reports/ASSET_REDUCTION_FEASIBILITY.md). Excluding non-English text saves only ~137 MB, and deleting cinematics breaks gameplay while still leaving >47 GiB.
* **Solution A (Recommended — Zero Internal Impact):**
  Connect a portable **USB-C OTG SSD** (128 GB or 256 GB, formatted exFAT).
  Winlator supports mounting external USB-OTG volumes directly as drive `D:`.
* **Solution B (Internal Storage Freeing):**
  User offloads photos, videos, or large apps from the phone to free at least **65 GB** before transferring the game folder.

---

## 5. Laptop-Side Test Results

| Test Category | Target Component | Result | Details |
|---|---|---|---|
| **Original Game Audit** | `Verify-GameIntegrity.ps1` | **PASSED** | 159 files verified, 0 modified. Executable hash `A7DE82945C...` verified. Untrusted file `cyberpunk2077_addresses.json` sealed. |
| **Preflight Self-Test** | `CP2077PreflightVerifier.jar --test` | **PASSED (3/3)** | Storage deficit math, directory structure, and hardware criteria verified. |
| **Architecture Regression** | `CP2077TestHarness.jar` | **PASSED (5/5)** | Validated Route A rejection, storage deficit calculation, Winlator JSON schema, VKD3D flags, and read-only safety rules. |
| **Winlator APK Verification** | `Winlator_11.2.apk` | **PASSED** | SHA-256 matches official release `ea5c81bf0e5b...` exactly. Package contents verified (Box64 0.4.4, VKD3D 2.14.1, Turnip 26.2.0 present). |
| **Device Execution / Launch** | Physical HONOR 90 Launch | **PENDING** | Phone currently offline / disconnected. |

---

## 6. Next Concrete Steps to Launch the Actual Game

When the phone is available:

1. **Resolve Storage:**
   - Either clear 65+ GB on the HONOR 90 internal storage, or plug in a USB-C OTG SSD formatted exFAT.
2. **Install Winlator 11.2:**
   - Copy `Winlator_11.2.apk` from `dist/compatibility/` to the phone via USB-C file transfer.
   - Install the APK and grant storage management permissions.
3. **Stage the Game Data:**
   - Copy the folder `C:\Games\steam\steamapps\common\Cyberpunk 2077` to the phone storage (or OTG SSD) as `Cyberpunk2077`, **omitting** `cyberpunk2077_addresses.json`.
4. **Import Configuration & First Launch:**
   - Import `dist/config/winlator_cp2077.json` into Winlator.
   - Copy `dist/config/vkd3d.conf` into `drive_c/windows/system32/`.
   - Start the container and execute `Cyberpunk2077.exe -qualityLevel=Low -skipStartScreen -launcher-skip`.
   - Observe whether Denuvo Anti-Tamper completes offline startup checks and whether VKD3D initializes the Turnip 26.2.0 surface.
