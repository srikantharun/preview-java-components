package com.example;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for mutation testing with PiTest.
 */
class AppTest {

    @Test
    void testAdd() {
        App app = new App();
        assertEquals(4, app.add(2, 2));
        assertEquals(0, app.add(-1, 1));
    }

    @Test
    void testSubtract() {
        App app = new App();
        assertEquals(0, app.subtract(2, 2));
        assertEquals(3, app.subtract(5, 2));
    }

    @Test
    void testIsPositive() {
        App app = new App();
        assertTrue(app.isPositive(1));
        assertFalse(app.isPositive(0));
        assertFalse(app.isPositive(-1));
    }
}
