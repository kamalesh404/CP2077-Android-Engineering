package com.cp2077.companion;

import org.junit.Test;
import static org.junit.Assert.*;

public class StorageAuditorTest {

    @Test
    public void testStorageRequirementConstant() {
        assertEquals("Base game bytes must match 66366228927", 66366228927L, StorageAuditor.CP2077_BASE_GAME_BYTES);
    }

    @Test
    public void testCheckDeficitCalculation() {
        long availableSmall = 18_000_000_000L;
        assertFalse("18 GB must be evaluated as insufficient", StorageAuditor.checkDeficit(availableSmall));

        long availableSufficient = 80_000_000_000L;
        assertTrue("80 GB must be evaluated as sufficient", StorageAuditor.checkDeficit(availableSufficient));
    }
}
