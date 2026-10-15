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

    /**
     * Phone lookup candidates for legacy compatibility (ruling follow-up
     * 2026-10-15). The stored form may predate the E.164 rollout: legacy
     * bare 11-digit CN numbers were kept without a country code, while the
     * dial-code picker now merges to +86… / +254…. Returns distinct
     * candidates in lookup order; empty input yields an empty list.
     */
    public static java.util.List<String> phoneCandidates(String raw) {
        String digits = raw == null ? ""
                : raw.trim().replaceAll("[\\s\\-()]", "");
        if (digits.startsWith("+")) digits = digits.substring(1);
        else if (digits.startsWith("00")) digits = digits.substring(2);
        if (digits.isEmpty() || !digits.matches("[0-9]+")) {
            return java.util.List.of();
        }
        java.util.LinkedHashSet<String> out = new java.util.LinkedHashSet<>();
        // CN mobile: E.164 and bare legacy forms both exist in stored data
        if (digits.length() == 11 && digits.startsWith("1")) {
            out.add("+86" + digits);
        }
        if (digits.length() == 13 && digits.startsWith("86")
                && digits.charAt(2) == '1') {
            out.add(digits.substring(2));
        }
        // KE full form (254 + 9 digits) typed under a +254 picker
        if (digits.length() == 12 && digits.startsWith("254")) {
            out.add("+" + digits);
        }
        out.add("+" + digits); // generic E.164
        out.add(digits);       // legacy bare form
        return java.util.List.copyOf(out);
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
