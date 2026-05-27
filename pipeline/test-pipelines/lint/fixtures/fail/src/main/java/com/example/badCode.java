package com.example;

// Missing Javadoc - Checkstyle violation
// Class name should be PascalCase - Checkstyle violation (badCode instead of BadCode)
public class badCode {

    // Missing Javadoc for public field
    public String CONSTANT_THAT_ISNT = "not final";  // Should be final for constant naming

    // Unused private field - SpotBugs violation
    private String unusedField = "never used";

    // Missing Javadoc
    public void method_with_underscores() {  // Method naming violation
        String x = null;
        // Potential null pointer - SpotBugs violation
        System.out.println(x.toString());
    }

    // Missing @param and @return Javadoc
    public String getmessage() {  // Should be getMessage (camelCase)
        return "bad";
    }
}
