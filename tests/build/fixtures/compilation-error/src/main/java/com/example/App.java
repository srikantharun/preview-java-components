package com.example;

/**
 * Invalid application with syntax errors.
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
