package com.cp2077.companion;

import android.os.Environment;
import android.os.StatFs;
import java.io.File;

public class StorageAuditor {

    public static final long CP2077_BASE_GAME_BYTES = 66366228927L; // 61.81 GiB

    public static class StorageInfo {
        public long totalBytes;
        public long freeBytes;
        public boolean isSufficient;
        public long deficitBytes;
    }

    public static StorageInfo auditInternalStorage() {
        StorageInfo info = new StorageInfo();
        try {
            File path = Environment.getDataDirectory();
            StatFs stat = new StatFs(path.getPath());
            info.totalBytes = stat.getTotalBytes();
            info.freeBytes = stat.getAvailableBytes();
            if (info.freeBytes >= CP2077_BASE_GAME_BYTES) {
                info.isSufficient = true;
                info.deficitBytes = 0;
            } else {
                info.isSufficient = false;
                info.deficitBytes = CP2077_BASE_GAME_BYTES - info.freeBytes;
            }
        } catch (Exception e) {
            info.totalBytes = 0;
            info.freeBytes = 0;
            info.isSufficient = false;
            info.deficitBytes = CP2077_BASE_GAME_BYTES;
        }
        return info;
    }

    public static boolean checkDeficit(long availableBytes) {
        return availableBytes >= CP2077_BASE_GAME_BYTES;
    }
}
