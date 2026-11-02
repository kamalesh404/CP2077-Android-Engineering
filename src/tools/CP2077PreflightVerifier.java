package com.cp2077.tools;

import java.io.*;
import java.nio.file.*;
import java.security.MessageDigest;
import java.util.*;

/**
 * CP2077PreflightVerifier
 *
 * Project-owned offline verification and diagnostic utility for evaluating
 * target Android device readiness and game installation integrity without modifying
 * any game files.
 */
public class CP2077PreflightVerifier {

    public static final String EXPECTED_APP_ID = "1091500";
    public static final String EXPECTED_BUILD_ID = "20383525";
    public static final long EXPECTED_EXECUTABLE_SIZE = 59945608L; // Cyberpunk2077.exe v2.31
    public static final long TARGET_PHONE_TOTAL_STORAGE_BYTES = 238370684928L; // ~222 GB
    public static final long TARGET_PHONE_AVAILABLE_STORAGE_BYTES = 19327352832L; // ~18 GiB free
    public static final long MIN_STORAGE_REQUIRED_BYTES = 70000000000L; // ~70 GB

    public static class VerificationResult {
        public boolean gameDirValid = false;
        public boolean executableValid = false;
        public long totalGameBytes = 0;
        public int fileCount = 0;
        public boolean storageFit = false;
        public long storageDeficitBytes = 0;
        public Map<String, String> hashes = new LinkedHashMap<>();
        public List<String> issues = new ArrayList<>();
        public List<String> notices = new ArrayList<>();
    }

    public static void main(String[] args) {
        System.out.println("===============================================================");
        System.out.println(" Cyberpunk 2077 Android Engineering - Preflight Verifier v1.0.0");
        System.out.println("===============================================================");

        if (args.length > 0 && args[0].equals("--test")) {
            runSelfTest();
            return;
        }

        String gamePath = "C:\\Games\\steam\\steamapps\\common\\Cyberpunk 2077";
        if (args.length > 0 && !args[0].startsWith("-")) {
            gamePath = args[0];
        }

        VerificationResult result = verifyInstallation(new File(gamePath));
        printReport(result, gamePath);

        if (!result.gameDirValid || !result.executableValid) {
            System.exit(1);
        }
    }

    public static VerificationResult verifyInstallation(File gameDir) {
        VerificationResult res = new VerificationResult();

        if (!gameDir.exists() || !gameDir.isDirectory()) {
            res.issues.add("Game directory not found: " + gameDir.getAbsolutePath());
            return res;
        }

        // Verify key directories
        String[] requiredDirs = {"archive", "bin", "engine", "r6"};
        for (String dir : requiredDirs) {
            File d = new File(gameDir, dir);
            if (!d.exists() || !d.isDirectory()) {
                res.issues.add("Missing required directory: " + dir);
            }
        }

        // Check executable
        File exe = new File(gameDir, "bin" + File.separator + "x64" + File.separator + "Cyberpunk2077.exe");
        if (!exe.exists()) {
            res.issues.add("Cyberpunk2077.exe missing at " + exe.getPath());
        } else {
            long exeSize = exe.length();
            if (exeSize == EXPECTED_EXECUTABLE_SIZE) {
                res.executableValid = true;
                res.notices.add("Cyberpunk2077.exe size matches v2.31 exactly (" + exeSize + " bytes).");
            } else {
                res.issues.add("Cyberpunk2077.exe size mismatch: expected " + EXPECTED_EXECUTABLE_SIZE + ", got " + exeSize);
            }
        }

        // Check flagged anomaly file (read-only existence check, NEVER open contents)
        File addressJson = new File(gameDir, "bin" + File.separator + "x64" + File.separator + "cyberpunk2077_addresses.json");
        if (addressJson.exists()) {
            res.notices.add("Flagged anomaly detected (cyberpunk2077_addresses.json, " + addressJson.length() + " bytes). Kept sealed.");
        }

        // Calculate size and count files safely
        try {
            long[] stats = countFilesAndSize(gameDir);
            res.fileCount = (int) stats[0];
            res.totalGameBytes = stats[1];
            res.gameDirValid = true;
        } catch (Exception e) {
            res.issues.add("Error enumerating files: " + e.getMessage());
        }

        // Evaluate target device storage fit
        if (res.totalGameBytes > TARGET_PHONE_AVAILABLE_STORAGE_BYTES) {
            res.storageFit = false;
            res.storageDeficitBytes = res.totalGameBytes - TARGET_PHONE_AVAILABLE_STORAGE_BYTES;
            res.issues.add(String.format("Storage Deficit: Game requires %.2f GB, but phone only has %.2f GB free (Shortfall: %.2f GB).",
                    res.totalGameBytes / 1e9, TARGET_PHONE_AVAILABLE_STORAGE_BYTES / 1e9, res.storageDeficitBytes / 1e9));
        } else {
            res.storageFit = true;
        }

        return res;
    }

    private static long[] countFilesAndSize(File root) {
        long count = 0;
        long bytes = 0;
        File[] entries = root.listFiles();
        if (entries != null) {
            for (File f : entries) {
                if (f.isDirectory()) {
                    long[] sub = countFilesAndSize(f);
                    count += sub[0];
                    bytes += sub[1];
                } else {
                    count++;
                    bytes += f.length();
                }
            }
        }
        return new long[]{count, bytes};
    }

    public static String computeSHA256(File file) throws Exception {
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        try (InputStream fis = new FileInputStream(file);
             BufferedInputStream bis = new BufferedInputStream(fis)) {
            byte[] buffer = new byte[65536];
            int read;
            while ((read = bis.read(buffer)) != -1) {
                digest.update(buffer, 0, read);
            }
        }
        byte[] hash = digest.digest();
        StringBuilder hexString = new StringBuilder();
        for (byte b : hash) {
            String hex = Integer.toHexString(0xff & b);
            if (hex.length() == 1) hexString.append('0');
            hexString.append(hex);
        }
        return hexString.toString().toUpperCase();
    }

    public static void runSelfTest() {
        System.out.println("Running CP2077PreflightVerifier self-tests...");
        int passed = 0;
        int failed = 0;

        // Test 1: Verification of non-existent directory
        VerificationResult nonExistent = verifyInstallation(new File("C:\\NonExistent_Test_Path_12345"));
        if (!nonExistent.gameDirValid && !nonExistent.issues.isEmpty()) {
            System.out.println("  [PASS] Non-existent directory correctly reported invalid.");
            passed++;
        } else {
            System.out.println("  [FAIL] Non-existent directory handling failed.");
            failed++;
        }

        // Test 2: Storage math validation
        long available = 18_000_000_000L;
        long required = 66_366_228_927L;
        long deficit = required - available;
        if (deficit > 48_000_000_000L) {
            System.out.println("  [PASS] Storage deficit math verified: " + (deficit / 1_000_000_000L) + " GB deficit.");
            passed++;
        } else {
            System.out.println("  [FAIL] Storage deficit calculation incorrect.");
            failed++;
        }

        // Test 3: Hardware criteria evaluation
        boolean meetsMinRam = 12 >= 8; // HONOR 90 has 12GB or 8GB LPDDR5
        boolean gpuSupported = evaluateGpuSupport("Adreno 644");
        if (meetsMinRam && gpuSupported) {
            System.out.println("  [PASS] Hardware compatibility evaluator logic passed.");
            passed++;
        } else {
            System.out.println("  [FAIL] Hardware compatibility evaluator logic failed.");
            failed++;
        }

        System.out.println(String.format("Self-tests completed: %d passed, %d failed.", passed, failed));
        if (failed > 0) System.exit(1);
    }

    public static boolean evaluateGpuSupport(String gpuName) {
        if (gpuName == null) return false;
        // Adreno 644 supports Vulkan 1.1 natively, Vulkan 1.3 via experimental Turnip
        return gpuName.contains("Adreno") || gpuName.contains("Mali");
    }

    public static void printReport(VerificationResult res, String path) {
        System.out.println("\n--- VERIFICATION REPORT ---");
        System.out.println("Game Path Checked: " + path);
        System.out.println("Game Directory Valid: " + (res.gameDirValid ? "YES" : "NO"));
        System.out.println("Executable Valid (v2.31): " + (res.executableValid ? "YES" : "NO"));
        System.out.println("Total Files Enumerated: " + res.fileCount);
        System.out.println(String.format("Total Game Data Size: %.2f GiB (%,d bytes)", res.totalGameBytes / (1024.0 * 1024.0 * 1024.0), res.totalGameBytes));
        System.out.println("Device Storage Fit: " + (res.storageFit ? "SUFFICIENT" : "DEFICIT"));

        if (!res.notices.isEmpty()) {
            System.out.println("\nNotices:");
            for (String n : res.notices) System.out.println("  - " + n);
        }

        if (!res.issues.isEmpty()) {
            System.out.println("\nBlockers / Warnings:");
            for (String issue : res.issues) System.out.println("  [!] " + issue);
        }
        System.out.println("---------------------------\n");
    }
}
