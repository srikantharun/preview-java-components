package com.example;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;

/**
 * Unit tests for Application.
 */
class ApplicationTest {

    @Test
    void applicationStartsWithoutException() {
        assertDoesNotThrow(() -> Application.main(new String[]{}));
    }
}
