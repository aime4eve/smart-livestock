package com.smartlivestock.shared.common;

import java.util.List;
import java.util.regex.Pattern;

/**
 * Platform-wide password policy (ruling 2026-10-15): at least 8 characters
 * with upper-case, lower-case, digit and special character. Every entry
 * point that sets a password goes through {@link #violationKey} so the rule
 * and its message stay in one place.
 */
public final class PasswordPolicy {

    public static final String WEAK_KEY = "error.passwordWeak";

    private static final Pattern UPPER = Pattern.compile("[A-Z]");
    private static final Pattern LOWER = Pattern.compile("[a-z]");
    private static final Pattern DIGIT = Pattern.compile("[0-9]");
    private static final Pattern SPECIAL = Pattern.compile("[^A-Za-z0-9]");

    private PasswordPolicy() {
    }

    /** Null-safe; returns the i18n key of the first violated rule, or null. */
    public static String violationKey(String password) {
        if (password == null || password.length() < 8) return WEAK_KEY;
        if (!UPPER.matcher(password).find()) return WEAK_KEY;
        if (!LOWER.matcher(password).find()) return WEAK_KEY;
        if (!DIGIT.matcher(password).find()) return WEAK_KEY;
        if (!SPECIAL.matcher(password).find()) return WEAK_KEY;
        return null;
    }

    public static boolean isStrong(String password) {
        return violationKey(password) == null;
    }

    /** Enum values for parameterized tests. */
    public static List<String> ruleNames() {
        return List.of("length", "upper", "lower", "digit", "special");
    }
}
