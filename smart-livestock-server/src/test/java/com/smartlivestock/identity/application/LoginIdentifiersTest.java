package com.smartlivestock.identity.application;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Login identifier classification/normalization (ruling 2026-10-12).
 */
class LoginIdentifiersTest {

    @Test
    void classify_routesByShape() {
        assertThat(LoginIdentifiers.classify("j.doe-01")).isEqualTo(LoginIdentifiers.Kind.ACCOUNT);
        assertThat(LoginIdentifiers.classify("J.Doe-01")).isEqualTo(LoginIdentifiers.Kind.ACCOUNT);
        assertThat(LoginIdentifiers.classify("+254712345678")).isEqualTo(LoginIdentifiers.Kind.PHONE);
        assertThat(LoginIdentifiers.classify("254712345678")).isEqualTo(LoginIdentifiers.Kind.PHONE);
        assertThat(LoginIdentifiers.classify("138 0013-8000")).isEqualTo(LoginIdentifiers.Kind.PHONE);
        assertThat(LoginIdentifiers.classify("a@b.co")).isEqualTo(LoginIdentifiers.Kind.EMAIL);
        assertThat(LoginIdentifiers.classify("  ")).isEqualTo(LoginIdentifiers.Kind.INVALID);
    }

    @Test
    void normalizePhone_addsPlusAndStripsSeparators() {
        assertThat(LoginIdentifiers.normalizePhone("+254 712 345-678")).isEqualTo("+254712345678");
        assertThat(LoginIdentifiers.normalizePhone("254712345678")).isEqualTo("+254712345678");
        assertThat(LoginIdentifiers.normalizePhone("13800138000")).isEqualTo("+13800138000");
        assertThat(LoginIdentifiers.normalizePhone("")).isNull();
    }

    @Test
    void normalizeEmail_lowercases() {
        assertThat(LoginIdentifiers.normalizeEmail("  David@Example.COM ")).isEqualTo("david@example.com");
        assertThat(LoginIdentifiers.normalizeEmail(null)).isNull();
    }

    @Test
    void validators_rejectBadShapes() {
        assertThat(LoginIdentifiers.isValidAccount("ab")).isFalse();
        assertThat(LoginIdentifiers.isValidAccount("1abc")).isFalse();
        assertThat(LoginIdentifiers.isValidAccount("abc")).isTrue();
        assertThat(LoginIdentifiers.isValidEmail("not-an-email")).isFalse();
        assertThat(LoginIdentifiers.isValidPhone("+2541234")).isTrue();
        assertThat(LoginIdentifiers.isValidPhone("12345")).isFalse();
    }
}
