# PHONE INSTALLATION CHECKLIST — Cyberpunk 2077 on HONOR 90

- **Device:** HONOR 90 (`REA-NX9`)
- **SoC:** Qualcomm Snapdragon 7 Gen 1 Accelerated Edition (`SM7450`) / Adreno 644
- **OS:** MagicOS / Android 15
- **Status:** **ALL PHONE ACTIONS PENDING USER APPROVAL** (Phone currently offline / disconnected from ADB)

---

## Pre-Transfer Verification Gates (Must Pass Before Any Phone Transfer)

- [ ] **Gate 1: Storage Space Creation**
  - **Requirement:** At least **75 GB** of free internal storage on the phone (or high-speed USB-OTG Type-C SSD formatted exFAT).
  - **Current Verified Reality:** Phone has only **~18 GiB free** (shortfall of **~47+ GB**).
  - **Action Required:** User must offload photos, videos, or unused applications before game transfer can proceed.

- [ ] **Gate 2: Safe Game File Preparation**
  - **Source Directory:** `C:\Games\steam\steamapps\common\Cyberpunk 2077` (Treated as **READ-ONLY**).
  - **Integrity Check:** Run `java -jar C:\CP2077-Android-Engineering\dist\tools\CP2077PreflightVerifier.jar` to ensure all 159 files are present and `Cyberpunk2077.exe` SHA-256 matches `A7DE82945C03E041FC7339FCF9066224D98DB2F5D80FEA50F7947BB350A60991`.
  - **Omit Flagged Anomaly:** Do **NOT** copy `bin\x64\cyberpunk2077_addresses.json` (132 MB untrusted file).

- [ ] **Gate 3: Official Compatibility Environment Acquisition**
  - **Recommended Tool:** Official Winlator (v8.0+ or Frost/Cmod fork supporting Turnip 24.3+ for Adreno 6xx/7xx).
  - **Acquisition Source:** Official GitHub releases (`brunodev85/winlator/releases`). Never use modified third-party APKs from unverified Telegram or Discord channels.
  - **License:** Open Source (GPL-3.0 / MIT components).

---

## Offline Transfer Procedure (No ADB Required)

### Step 1: Transfer Game Files via Direct USB-C MTP Connection
1. Connect the HONOR 90 to the laptop using the original USB-C data cable.
2. On the phone screen, select **"File Transfer / Android Auto"** (MTP mode).
3. On Windows Explorer, open `This PC \ HONOR 90 \ Internal shared storage`.
4. Create a folder named:
   `Cyberpunk2077`
5. Copy the contents of `C:\Games\steam\steamapps\common\Cyberpunk 2077` to `HONOR 90\Internal shared storage\Cyberpunk2077` **excluding** `cyberpunk2077_addresses.json`.
6. Transfer time estimate: ~25 to 45 minutes over USB 2.0/3.0 protocol (~62 GB total transfer).

### Step 2: Install Compatibility Environment APK
1. On the phone, install the official Winlator APK.
2. Grant requested storage permissions (`All files access` / `MANAGE_EXTERNAL_STORAGE`).
3. Launch Winlator once to allow initial container extraction and OBB initialization.

### Step 3: Import Project Configuration Templates
1. Transfer `config/winlator_cp2077.json` from `C:\CP2077-Android-Engineering\dist\config\` to the phone's `Download/` folder.
2. In Winlator settings:
   - Create Container: Name `CP2077-Adreno644`
   - Screen Resolution: `1280x720` (16:9)
   - Graphics Driver: `Turnip (Adreno) 24.3.0`
   - DX Wrapper: `VKD3D-Proton 2.12`
   - Audio Driver: `ALSA`
   - Win32/x64 Box64 Preset: `Stability` (enforces strict memory ordering for multithreaded REDengine tasks)
   - Drives: Mount `D:` as `/storage/emulated/0/Cyberpunk2077`
3. Copy `config/vkd3d.conf` and `config/dxvk.conf` into the container's Windows system directory (`drive_c/windows/system32`).

---

## Execution & Diagnostic Verification

### Step 4: First Launch Attempt
1. Start the container in Winlator.
2. In the container desktop file manager, navigate to `D:\bin\x64\Cyberpunk2077.exe`.
3. Launch with arguments: `-qualityLevel=Low -skipStartScreen -launcher-skip`.
4. Monitor system logs:
   - **Expected Stage 1:** CPU instruction translation initialization (Box64 loading PE+ headers).
   - **Expected Stage 2:** Wine Win64 DLL loading (`ntdll`, `kernel32`, `d3d12`).
   - **Critical Feasibility Gate (Denuvo):** Check if Denuvo Anti-Tamper triggers an execution fault or requests internet token renewal.
   - **Critical Graphics Gate (Adreno 644):** Check if VKD3D-Proton successfully binds Turnip Vulkan surface without spirv-opt driver crash.

---

## Rollback & Cleanup Procedures

If execution fails, device becomes unstable, or storage needs to be reclaimed immediately:

1. **Reclaim Storage (Instant 62 GB recovery):**
   - In phone File Manager, delete the folder `/storage/emulated/0/Cyberpunk2077`.
   - In phone Settings -> Apps -> Winlator -> Clear Storage / Uninstall.
2. **Laptop State:**
   - Laptop Steam installation remained untouched throughout the entire procedure.
   - Run `java -jar C:\CP2077-Android-Engineering\dist\tools\CP2077PreflightVerifier.jar` to re-confirm zero laptop file modification.
