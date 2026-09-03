package com.smartlivestock.licensing.domain;

import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class HostFingerprintTest {

    private static final String HEX = "0123456789abcdef".repeat(4);

    @Test
    @DisplayName("accepts 64-char hex and normalizes to lowercase")
    void acceptsAndNormalizesHex() {
        HostFingerprint fingerprint = HostFingerprint.of(HEX.toUpperCase());

        assertThat(fingerprint.getValue()).isEqualTo(HEX);
    }

    @Test
    @DisplayName("strips surrounding whitespace before validation")
    void stripsWhitespace() {
        assertThat(HostFingerprint.of("  " + HEX + "\n").getValue()).isEqualTo(HEX);
    }

    @Test
    @DisplayName("rejects non-hex or wrong-length digests with LICENSE_INVALID")
    void rejectsMalformedDigests() {
        assertThatThrownBy(() -> HostFingerprint.of("zzzz"))
                .isInstanceOfSatisfying(DomainException.class, e ->
                        assertThat(e.getCode()).isEqualTo(ErrorCode.LICENSE_INVALID));
        assertThatThrownBy(() -> HostFingerprint.of("a".repeat(63)))
                .isInstanceOf(DomainException.class);
        assertThatThrownBy(() -> HostFingerprint.of(null))
                .isInstanceOf(DomainException.class);
    }

    @Test
    @DisplayName("matches compares normalized digests")
    void matchesNormalized() {
        HostFingerprint fingerprint = HostFingerprint.of(HEX);

        assertThat(fingerprint.matches(HEX.toUpperCase())).isTrue();
        assertThat(fingerprint.matches("deadbeef")).isFalse();
        assertThat(fingerprint.matches(null)).isFalse();
    }
}
