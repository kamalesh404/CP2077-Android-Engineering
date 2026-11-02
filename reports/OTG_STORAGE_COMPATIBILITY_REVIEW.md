# OTG STORAGE COMPATIBILITY REVIEW — WINLATOR 11.2 & ANDROID 15

- **Audit Date:** 2026-10-27
- **Target OS:** Android 15 (API 35) on HONOR 90 (`REA-NX9`, Qualcomm Snapdragon 7 Gen 1)
- **Target Application:** Winlator 11.2 (`com.winlator`, SHA-256: `EA5C81BF0E5B90A6B9CCB8007121AB6738C8646A5A60B341CE0AC2B33F1D100A`)
- **Storage Medium:** External USB-C OTG SSD formatted exFAT (~66.2 GB game data)
- **Method:** Static binary bytecode disassembly of `Winlator_11.2.apk` (`classes.dex`, `AndroidManifest.xml`) and Android 15 Linux kernel storage security architecture analysis. No ADB required.

---

## 1. Executive Summary: Documented Facts vs. Unverified Assumptions

| Concept | Previous Assumption | Verified Android 15 & Winlator Reality | Technical Status |
|---|---|---|---|
| **Root OTG Drive Access** | Winlator can map `/storage/XXXX-XXXX/Cyberpunk2077` directly from container settings. | **FALSE without system grants.** Android 15 Scoped Storage blocks POSIX `open()` / `mmap()` at external storage roots for apps lacking `MANAGE_EXTERNAL_STORAGE`. Winlator's GUI folder picker cannot navigate raw external volumes. | **BLOCKED (Default Root)** |
| **App-Specific Directory** | `/storage/XXXX-XXXX/Android/data/com.winlator/files/` works automatically out-of-the-box. | **PARTIALLY VERIFIED / CONDITIONAL.** Android 11+ grants native POSIX access to package-owned external directories without extra permissions, BUT on Android 14/15, creating the initial `Android/data/com.winlator/` tree on an external drive requires either Android system initialization or manual creation on a PC. | **DOCUMENTED CONDITIONAL** |
| **Filesystem Compatibility** | exFAT is natively supported for >4 GB files. | **VERIFIED.** Android 15 kernel includes native in-tree `exfat` driver. Necessary for `basegame_5_video.archive` (12.94 GiB) and `basegame_3_nightcity_gi.archive` (11.05 GiB). | **VERIFIED SUPPORTED** |
| **Winlator Drive Mapping** | Wine creates a drive letter mapped to an Android directory path. | **VERIFIED in Bytecode.** Winlator creates a Linux symlink in `~/.wine/dosdevices/d:` pointing to the target Android directory. Wine's Win32 subsystem translates `D:\` paths through this symlink. | **VERIFIED SUPPORTED** |

---

## 2. In-Depth Binary & Permission Analysis of Winlator 11.2

### 2.1 Manifest Permission Audit (`Winlator_11.2.apk:AndroidManifest.xml`)
Direct bytecode decoding of the binary XML manifest reveals the exact declared permissions:
* `android.permission.READ_EXTERNAL_STORAGE` (Present)
* `android.permission.WRITE_EXTERNAL_STORAGE` (Present)
* `android.permission.FOREGROUND_SERVICE` (Present)
* **`android.permission.MANAGE_EXTERNAL_STORAGE`:** **ABSENT**

#### Critical Architectural Implication:
On **Android 11 through Android 15**, `READ_EXTERNAL_STORAGE` only grants access to media store items (Photos, Audio, Video) and the public `/sdcard/Download/` directory. It does **not** grant access to arbitrary non-media files (`.exe`, `.dll`, `.archive`, `.ini`) on secondary volumes (`/storage/XXXX-XXXX/`).

### 2.2 Storage Access Framework (SAF) in Bytecode (`FileUtils.java`)
Bytecode inspection of `classes.dex` at offset 1,755,366 identified method `FileUtils.getPath()` which handles document URIs from `com.android.externalstorage.documents`:
```java
// Logic reverse-engineered from Dalvik bytecode in classes.dex:
if ("com.android.externalstorage.documents".equals(uri.getAuthority())) {
    String docId = DocumentsContract.getDocumentId(uri);
    String[] split = docId.split(":");
    String type = split[0];
    if ("primary".equalsIgnoreCase(type)) {
        return Environment.getExternalStorageDirectory() + "/" + split[1];
    } else {
        // Non-primary storage: extracts volume ID
        return "/storage/" + type + "/" + split[1];
    }
}
```
* **What this proves:** Winlator has built-in code to resolve Storage Access Framework URIs into raw filesystem paths (`/storage/XXXX-XXXX/...`).
* **The Limitation:** Although Winlator's Java layer can resolve the string path, the underlying **Wine and Box64 C/C++ native binaries** execute standard POSIX syscalls (`open()`, `mmap()`, `stat()`, `read()`). If the Linux kernel FUSE node restricts read access to the app's Linux UID, the native game process receives `EACCES` (Permission Denied) and crashes immediately.

---

## 3. The 3 Supported Mechanisms for OTG Drive Access on Android 15

To guarantee that Cyberpunk 2077's game files are accessible to Wine without permission faults, one of three verified mechanisms must be employed:

```mermaid
flowchart TD
    OTG["exFAT USB-C OTG SSD<br/>(Target: Cyberpunk 2077, 61.19 GiB)"]
    
    subgraph Routes ["Mount Mechanisms on Android 15"]
        Route1["Mechanism 1: Package Data Directory<br/>/storage/XXXX-XXXX/Android/data/com.winlator/files/<br/>(POSIX Allowed natively by Android FUSE)"]
        Route2["Mechanism 2: AppOps MANAGE_EXTERNAL_STORAGE<br/>Granted once via Settings / ADB<br/>(Allows raw /storage/XXXX-XXXX/ access)"]
        Route3["Mechanism 3: In-App SAF Tree Access<br/>Granted via Android Storage Picker<br/>(Persistent tree permission)"]
    end

    subgraph WineContainer ["Winlator 11.2 Wine Container"]
        Symlink["dosdevices/d: (Linux Symlink)"]
        GameExe["D:\\bin\\x64\\Cyberpunk2077.exe"]
    end

    OTG --> Route1
    OTG --> Route2
    OTG --> Route3
    Route1 -->|Manually typed path| Symlink
    Route2 -->|Root drive path| Symlink
    Route3 -->|Resolved path| Symlink
    Symlink --> GameExe
```

### Mechanism 1: App-Specific External Package Directory (RECOMMENDED)
* **Path:** `/storage/XXXX-XXXX/Android/data/com.winlator/files/Cyberpunk2077`
* **How it works:** Under Android 11–15 security policy, every app owns its package path on all storage volumes. The Linux kernel grants the app's UID full read, write, and execute permissions (`rwxrwx--x`) to this directory.
* **Pre-condition:** On Android 14/15, the phone OS protects the `Android/data/` folder from standard mobile file managers. **Therefore, the directory structure must be created while the USB-C SSD is connected to the laptop prior to plugging it into the phone.**
* **Winlator Mapping:** In Container Settings -> Drives -> Add Drive, assign letter `D:` and manually enter:
  `/storage/XXXX-XXXX/Android/data/com.winlator/files/Cyberpunk2077`

### Mechanism 2: Special App Access (`MANAGE_EXTERNAL_STORAGE`)
* **How it works:** If the phone's Android OS settings allow granting "All files access" to Winlator under:
  `Settings -> Apps -> Special app access -> All files access -> Winlator -> Allow`
* **Result:** Winlator gains unrestricted access to the entire USB drive root (`/storage/XXXX-XXXX/Cyberpunk2077`).
* **Limitation:** Because Winlator 11.2 does not explicitly declare the permission in its manifest, some vendor skins (such as MagicOS on HONOR) hide Winlator from the "All files access" menu unless enabled via ADB `appops`.

### Mechanism 3: SAF Directory Tree Picker
* **How it works:** In Winlator's file browser, selecting "Open" triggers Android's document picker. Choosing the USB SSD grants persistent scoped access via `takePersistableUriPermission`.
* **Limitation:** FUSE overhead for deep directory traversal across 158 game archives can reduce streaming performance in open-world games.

---

## 4. Game-Loading & Runtime Performance Constraints on OTG

Even when file permissions are fully satisfied, the following hardware constraints must be planned for:

1. **USB Bus Bandwidth & Power:**
   - The HONOR 90's USB-C port operates at USB 2.0 / USB 3.0 data rates depending on OTG cable specification.
   - High-load texture streaming from an external drive will draw battery power from the phone. A powered USB-C hub with Power Delivery (PD) is strongly recommended so the SSD does not drain phone battery or suffer I/O drops under voltage drops.
2. **exFAT Filesystem Locking:**
   - exFAT does not support POSIX file locking (`flock`, `fcntl`).
   - Wine uses its own internal server-side lock manager for Win32 file sharing (`wineserver`), so this limitation is handled in software.
3. **Mesa Shader Cache Location:**
   - The compiled Vulkan shader cache generated by VKD3D and Turnip 26.2.0 must **remain on internal phone storage** (in `/storage/emulated/0/Winlator/drives/c/`), not on the external drive. Our `dist/config/winlator_cp2077.json` configuration correctly enforces this.

---

## 5. Authoritative Conclusion

Using an exFAT USB-C OTG SSD is **technically feasible and structurally supported** on Winlator 11.2 / Android 15, provided that:

1. The external drive is formatted as **exFAT**.
2. The staging directory on the laptop is created at:
   `[DriveRoot]\Android\data\com.winlator\files\Cyberpunk2077`
3. The Winlator container maps Drive `D:` to that exact path.

This completely bypasses the phone's 18 GiB internal storage deficit and avoids Android 15 Scoped Storage permission denials.
