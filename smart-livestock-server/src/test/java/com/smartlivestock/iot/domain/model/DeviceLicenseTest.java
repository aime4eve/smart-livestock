package com.smartlivestock.iot.domain.model;

import com.smartlivestock.shared.common.ApiException;
import org.junit.jupiter.api.Test;

import java.time.Instant;

import static org.assertj.core.api.Assertions.*;

class DeviceLicenseTest {

    private DeviceLicense createActiveLicense() {
        return new DeviceLicense(
            1L,             // deviceId
            10L,            // tenantId
            "LIC-KEY-001",  // licenseKey
            Instant.now().plusSeconds(86400) // expiresAt = 1 day from now
        );
    }

    @Test
    void shouldCreateActiveLicense() {
        DeviceLicense license = createActiveLicense();

        assertThat(license.getDeviceId()).isEqualTo(1L);
        assertThat(license.getTenantId()).isEqualTo(10L);
        assertThat(license.getLicenseKey()).isEqualTo("LIC-KEY-001");
        assertThat(license.getStatus()).isEqualTo(LicenseStatus.ACTIVE);
        assertThat(license.getActivatedAt()).isNotNull();
        assertThat(license.getExpiresAt()).isNotNull();
    }

    @Test
    void shouldBeValidWhenNotExpired() {
        DeviceLicense license = createActiveLicense();

        assertThat(license.isValid()).isTrue();
        assertThat(license.isExpired()).isFalse();
    }

    @Test
    void shouldBeExpiredWhenPastExpiry() {
        DeviceLicense license = new DeviceLicense(
            1L, 10L, "LIC-KEY-002",
            Instant.now().minusSeconds(1) // already expired
        );

        assertThat(license.isExpired()).isTrue();
        assertThat(license.isValid()).isFalse();
    }

    @Test
    void shouldRevokeActiveLicense() {
        DeviceLicense license = createActiveLicense();

        license.revoke();

        assertThat(license.getStatus()).isEqualTo(LicenseStatus.REVOKED);
    }

    @Test
    void shouldRejectRevokeAlreadyRevoked() {
        DeviceLicense license = createActiveLicense();
        license.revoke();

        assertThatThrownBy(license::revoke)
            .isInstanceOf(ApiException.class)
            .hasMessageContaining("REVOKED");
    }

    @Test
    void shouldDetectExpiredStatusOnCheck() {
        DeviceLicense license = new DeviceLicense(
            1L, 10L, "LIC-KEY-003",
            Instant.now().minusSeconds(3600)
        );

        assertThat(license.isExpired()).isTrue();
        assertThat(license.isValid()).isFalse();
    }
}
