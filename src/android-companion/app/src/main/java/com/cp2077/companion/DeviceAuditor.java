package com.cp2077.companion;

import android.app.ActivityManager;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;

public class DeviceAuditor {

    public static AuditReport runAudit(Context context) {
        AuditReport report = new AuditReport();
        report.deviceModel = Build.MODEL;
        report.manufacturer = Build.MANUFACTURER;
        report.socModel = Build.SOC_MODEL;
        report.abi = Build.SUPPORTED_ABIS.length > 0 ? Build.SUPPORTED_ABIS[0] : "unknown";
        report.androidVersion = Build.VERSION.SDK_INT;

        // RAM info
        ActivityManager actManager = (ActivityManager) context.getSystemService(Context.ACTIVITY_SERVICE);
        ActivityManager.MemoryInfo memInfo = new ActivityManager.MemoryInfo();
        if (actManager != null) {
            actManager.getMemoryInfo(memInfo);
            report.totalRamBytes = memInfo.totalMem;
            report.availRamBytes = memInfo.availMem;
        }

        // Storage info
        StorageAuditor.StorageInfo storage = StorageAuditor.auditInternalStorage();
        report.internalTotalBytes = storage.totalBytes;
        report.internalFreeBytes = storage.freeBytes;
        report.storageSufficient = storage.isSufficient;
        report.storageDeficitBytes = storage.deficitBytes;

        // Vulkan feature check
        PackageManager pm = context.getPackageManager();
        report.hasVulkan = pm.hasSystemFeature(PackageManager.FEATURE_VULKAN_HARDWARE_LEVEL);
        report.vulkanVersion = pm.hasSystemFeature(PackageManager.FEATURE_VULKAN_HARDWARE_VERSION) ? 1 : 0;

        // Composite summary
        if (!report.storageSufficient) {
            report.summary = "BLOCKED: Insufficient phone storage. Required: ~66.37 GB, Available: " 
                + String.format("%.2f GB", report.internalFreeBytes / 1e9);
        } else if (report.totalRamBytes < 6_000_000_000L) {
            report.summary = "WARNING: RAM is below recommended 6GB minimum for Box64/Wine container.";
        } else {
            report.summary = "HARDWARE READY: Device meets base requirements for compatibility testing.";
        }

        return report;
    }
}
