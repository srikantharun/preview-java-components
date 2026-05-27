package com.example;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Integration test class (named *IT.java for failsafe plugin).
 */
class AppIT {

    @Test
    void testAddIntegration() {
        App app = new App();
        assertEquals(4, app.add(2, 2), "Integration test: 2 + 2 should equal 4");
    }
}
