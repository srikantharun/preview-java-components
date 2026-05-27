package com.example;

/**
 * Clean application that follows Google Java Style Guide.
 * This code should pass all lint checks.
 */
public final class Application {

    /** Private constructor to prevent instantiation. */
    private Application() {
    }

    /**
     * Main entry point.
     *
     * @param args command line arguments
     */
    public static void main(final String[] args) {
        System.out.println("Hello from clean code!");
    }

    /**
     * Returns a greeting message.
     *
     * @return greeting string
     */
    public static String getMessage() {
        return "Hello";
    }
}
