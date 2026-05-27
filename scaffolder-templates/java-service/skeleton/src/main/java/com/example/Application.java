package com.example;

/**
 * Main application class for ${{ values.name }}.
 *
 * <p>${{ values.description }}</p>
 */
public class Application {

    /**
     * Application entry point.
     *
     * @param args command line arguments
     */
    public static void main(final String[] args) {
        System.out.println("Starting ${{ values.name }}...");
    }
}
