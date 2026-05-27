package com.example;

/**
 * Invalid Java application for testing java/build component.
 * This has a syntax error and should fail to compile.
 */
public class App {

    public static void main(String[] args) {
        // Missing semicolon - syntax error
        System.out.println("This will not compile")
    }

    public String getMessage() {
        return "Hello"  // Missing semicolon
    }
}
