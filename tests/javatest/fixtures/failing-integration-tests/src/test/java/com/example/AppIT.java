package com.example;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Integration test class that deliberately fails.
 */
class AppIT {

    @Test
    void testThatFails() {
        App app = new App();
        // This assertion will fail
        assertEquals(5, app.add(2, 2), "Integration test deliberately fails");
    }
}
