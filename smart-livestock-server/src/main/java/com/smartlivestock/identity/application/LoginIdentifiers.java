package com.smartlivestock.identity.application;

import java.util.Locale;
import java.util.regex.Pattern;

/**
 * Normalization + classification of login identifiers (ruling 2026-10-12).
 * Login accepts ACCOUNT / PHONE (E.164; WhatsApp shares the number) / EMAIL;
 * the display username never logs in.
 */
public final class LoginIdentifiers {

    private static final Pattern ACCOUNT = Pattern.compile("^[A-Za-z][A-Za-z0-9._-]{2,31}$");
    private static final Pattern EMAIL = Pattern.compile("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$");
    private static final Pattern E164 = Pattern.compile("^\\+?[0-9]{6,15}$");
    private static final Pattern PHONE_LIKE = Pattern.compile("^\\+?[0-9][0-9 \\-()]*$");

    private LoginIdentifiers() {
    }

    public enum Kind { ACCOUNT, PHONE, EMAIL, INVALID }

    public static boolean isValidEmail(String raw) {
        return raw != null && EMAIL.matcher(raw.trim()).matches();
    }

    public static boolean isValidAccount(String raw) {
        return raw != null && ACCOUNT.matcher(raw.trim()).matches();
    }

    /** E.164 with or without the leading plus; digits-only, 6-15 long. */
    public static boolean isValidPhone(String raw) {
        return raw != null && E164.matcher(raw.trim()).matches();
    }

    /** Canonical storage form: phone keeps its plus (added when absent). */
    public static String normalizePhone(String raw) {
        if (raw == null) return null;
        String digits = raw.replaceAll("[\\s\\-()]", "");
        if (digits.isEmpty()) return null;
        return digits.startsWith("+") ? digits : "+" + digits;
    }

    /** Canonical email: trimmed lowercase. */
    public static String normalizeEmail(String raw) {
        return raw == null || raw.isBlank() ? null : raw.trim().toLowerCase(Locale.ROOT);
    }

    /** Canonical account: trimmed as-typed (case preserved; compared lower). */
    public static String normalizeAccount(String raw) {
        return raw == null || raw.isBlank() ? null : raw.trim();
    }

    /** Classifies raw input for login routing. */
    public static Kind classify(String raw) {
        if (raw == null || raw.isBlank()) return Kind.INVALID;
        String v = raw.trim();
        if (v.contains("@")) return Kind.EMAIL;
        if (PHONE_LIKE.matcher(v).matches()) return Kind.PHONE;
        return Kind.ACCOUNT;
    }
}
