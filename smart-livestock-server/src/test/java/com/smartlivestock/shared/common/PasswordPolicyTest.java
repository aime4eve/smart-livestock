package com.smartlivestock.shared.common;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullAndEmptySource;
import org.junit.jupiter.params.provider.ValueSource;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Password policy (ruling 2026-10-15): ≥8 chars with upper/lower/digit/special.
 */
class PasswordPolicyTest {

    @ParameterizedTest
    @NullAndEmptySource
    @ValueSource(strings = {"Ab1!", "Abcdefg1", "abcdefg1!", "ABCDEFG1!", "Abcdefg!"})
    void weakPasswords_violate(String password) {
        assertThat(PasswordPolicy.violationKey(password)).isEqualTo(PasswordPolicy.WEAK_KEY);
        assertThat(PasswordPolicy.isStrong(password)).isFalse();
    }

    @Test
    void strongPassword_passes() {
        assertThat(PasswordPolicy.isStrong("Abcdefg1!")).isTrue();
        assertThat(PasswordPolicy.violationKey("Abcdefg1!")).isNull();
        assertThat(PasswordPolicy.isStrong("Kenya@2026")).isTrue();
    }

    @Test
    void sevenCharsWithAllClasses_stillViolates() {
        assertThat(PasswordPolicy.violationKey("Ab1!xyz")).isEqualTo(PasswordPolicy.WEAK_KEY);
    }
}
