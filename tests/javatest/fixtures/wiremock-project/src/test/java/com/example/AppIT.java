package com.example;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Wiremock integration test (runs with -Pwiremock profile).
 */
class AppIT {

    @Test
    void testWithWiremock() {
        App app = new App();
        assertEquals(4, app.add(2, 2), "Wiremock test: 2 + 2 should equal 4");
    }
}
