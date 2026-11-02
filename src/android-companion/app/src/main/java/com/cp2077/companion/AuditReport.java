package com.cp2077.companion;

public class AuditReport {
    public String deviceModel;
    public String manufacturer;
    public String socModel;
    public String abi;
    public int androidVersion;
    public long totalRamBytes;
    public long availRamBytes;
    public long internalTotalBytes;
    public long internalFreeBytes;
    public boolean hasVulkan;
    public int vulkanVersion;
    public boolean storageSufficient;
    public long storageDeficitBytes;
    public String summary;

    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append("=== CP2077 DEVICE READINESS AUDIT ===\n");
        sb.append("Model: ").append(manufacturer).append(" ").append(deviceModel).append("\n");
        sb.append("SoC: ").append(socModel != null ? socModel : "Unknown").append("\n");
        sb.append("ABI: ").append(abi).append("\n");
        sb.append("Android API: ").append(androidVersion).append("\n");
        sb.append(String.format("RAM: Total %.2f GB | Avail %.2f GB\n", totalRamBytes / 1e9, availRamBytes / 1e9));
        sb.append(String.format("Internal Storage: Free %.2f GB of %.2f GB\n", internalFreeBytes / 1e9, internalTotalBytes / 1e9));
        sb.append("Vulkan Hardware: ").append(hasVulkan ? "Supported" : "Not Detected").append("\n");
        sb.append("-------------------------------------\n");
        sb.append("Game Required: ~66.37 GB\n");
        sb.append("Storage Fit: ").append(storageSufficient ? "SUFFICIENT" : "DEFICIT (Short by " + String.format("%.2f GB", storageDeficitBytes / 1e9) + ")").append("\n");
        sb.append("Summary: ").append(summary).append("\n");
        sb.append("=====================================\n");
        return sb.toString();
    }
}
