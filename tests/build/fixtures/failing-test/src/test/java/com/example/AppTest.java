package com.example;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Test that deliberately fails.
 * Build should pass with -DskipTests.
 */
class AppTest {

    @Test
    void testThatFails() {
        App app = new App();
        // This assertion will fail
        assertEquals(5, app.add(2, 2), "This test deliberately fails");
    }
}
