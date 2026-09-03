package com.smartlivestock.licensing.domain;

import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

import static com.smartlivestock.licensing.testsupport.LicenseTestSupport.FINGERPRINT_HASH;
import static com.smartlivestock.licensing.testsupport.LicenseTestSupport.TEST_KEY_ID;
import static com.smartlivestock.licensing.testsupport.LicenseTestSupport.validPayloadMap;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class LicensePayloadTest {

    @Nested
    @DisplayName("fromMap: happy path")
    class FromMap {

        @Test
        void parsesAllFields() {
            Map<String, Object> map = validPayloadMap();

            LicensePayload payload = LicensePayload.fromMap(map);

            assertThat(payload.getPayloadVersion()).isEqualTo(1);
            assertThat(payload.getLicenseId().toString()).isEqualTo("3f2b8a5e-0c1d-4e2f-9a8b-7c6d5e4f3a2b");
            assertThat(payload.getTenantId()).isEqualTo(42L);
            assertThat(payload.getInstallationId().toString())
                    .isEqualTo("9e1c2b3a-4d5e-4f60-8a71-9b0c1d2e3f40");
            assertThat(payload.getFingerprintHash()).isEqualTo(FINGERPRINT_HASH);
            assertThat(payload.getKeyId()).isEqualTo(TEST_KEY_ID);
            assertThat(payload.getLicenseType()).isEqualTo(LicenseType.TRIAL);
            assertThat(payload.getTier()).isEqualTo("BASIC");
            assertThat(payload.getEffectiveTier()).isEqualTo("PREMIUM");
            assertThat(payload.getIssuedAt()).isBefore(Instant.now());
            assertThat(payload.getExpiresAt()).isAfter(Instant.now());
            assertThat(payload.getQuotas())
                    .containsEntry("livestock_management", 1000)
                    .containsEntry("device_management", 1000);
            assertThat(payload.getFeatures()).isEmpty();
            assertThat(payload.getReplacesLicenseId()).isNull();
        }

        @Test
        void parsesOptionalReplacesLicenseId() {
            Map<String, Object> map = validPayloadMap();
            map.put("replacesLicenseId", "5a4b3c2d-1e0f-4a5b-8c9d-0e1f2a3b4c5d");

            assertThat(LicensePayload.fromMap(map).getReplacesLicenseId().toString())
                    .isEqualTo("5a4b3c2d-1e0f-4a5b-8c9d-0e1f2a3b4c5d");
        }

        @Test
        void toMapRoundTripsThroughFromMap() {
            LicensePayload original = LicensePayload.fromMap(validPayloadMap());

            LicensePayload parsed = LicensePayload.fromMap(original.toMap());

            assertThat(parsed.getLicenseId()).isEqualTo(original.getLicenseId());
            assertThat(parsed.getTenantId()).isEqualTo(original.getTenantId());
            assertThat(parsed.getInstallationId()).isEqualTo(original.getInstallationId());
            assertThat(parsed.getFingerprintHash()).isEqualTo(original.getFingerprintHash());
            assertThat(parsed.getKeyId()).isEqualTo(original.getKeyId());
            assertThat(parsed.getLicenseType()).isEqualTo(original.getLicenseType());
            assertThat(parsed.getIssuedAt()).isEqualTo(original.getIssuedAt());
            assertThat(parsed.getExpiresAt()).isEqualTo(original.getExpiresAt());
            assertThat(parsed.getQuotas()).isEqualTo(original.getQuotas());
        }
    }

    @Nested
    @DisplayName("fromMap: rejections map to LICENSE_INVALID")
    class FromMapRejections {

        @Test
        void rejectsUnsupportedPayloadVersion() {
            Map<String, Object> map = validPayloadMap();
            map.put("payloadVersion", 2);

            assertThatThrownBy(() -> LicensePayload.fromMap(map))
                    .isInstanceOfSatisfying(DomainException.class, e ->
                            assertThat(e.getCode()).isEqualTo(ErrorCode.LICENSE_INVALID));
        }

        @Test
        void rejectsUnknownLicenseType() {
            Map<String, Object> map = validPayloadMap();
            map.put("licenseType", "REPLACEMENT");

            assertThatThrownBy(() -> LicensePayload.fromMap(map))
                    .isInstanceOfSatisfying(DomainException.class, e ->
                            assertThat(e.getMessage()).contains("licenseType"));
        }

        @Test
        void rejectsMissingRequiredField() {
            Map<String, Object> map = validPayloadMap();
            map.remove("licenseId");

            assertThatThrownBy(() -> LicensePayload.fromMap(map))
                    .isInstanceOfSatisfying(DomainException.class, e ->
                            assertThat(e.getMessage()).contains("licenseId"));
        }

        @Test
        void rejectsNonUuidLicenseId() {
            Map<String, Object> map = validPayloadMap();
            map.put("licenseId", "not-a-uuid");

            assertThatThrownBy(() -> LicensePayload.fromMap(map))
                    .isInstanceOfSatisfying(DomainException.class, e ->
                            assertThat(e.getCode()).isEqualTo(ErrorCode.LICENSE_INVALID));
        }

        @Test
        void rejectsNonHexFingerprintHash() {
            Map<String, Object> map = validPayloadMap();
            map.put("fingerprintHash", "zzzz");

            assertThatThrownBy(() -> LicensePayload.fromMap(map))
                    .isInstanceOfSatisfying(DomainException.class, e ->
                            assertThat(e.getCode()).isEqualTo(ErrorCode.LICENSE_INVALID));
        }

        @Test
        void rejectsExpiresAtBeforeIssuedAt() {
            Map<String, Object> map = validPayloadMap();
            map.put("issuedAt", "2027-01-01T00:00:00Z");
            map.put("expiresAt", "2026-01-01T00:00:00Z");

            assertThatThrownBy(() -> LicensePayload.fromMap(map))
                    .isInstanceOfSatisfying(DomainException.class, e ->
                            assertThat(e.getMessage()).contains("expiresAt"));
        }

        @Test
        void rejectsNonIntegerQuotaValues() {
            Map<String, Object> map = validPayloadMap();
            Map<String, Object> quotas = new LinkedHashMap<>();
            quotas.put("livestock_management", "many");
            map.put("quotas", quotas);

            assertThatThrownBy(() -> LicensePayload.fromMap(map))
                    .isInstanceOfSatisfying(DomainException.class, e ->
                            assertThat(e.getMessage()).contains("quotas"));
        }

        @Test
        void rejectsQuotasThatAreNotAnObject() {
            Map<String, Object> map = validPayloadMap();
            map.put("quotas", 100);

            assertThatThrownBy(() -> LicensePayload.fromMap(map))
                    .isInstanceOfSatisfying(DomainException.class, e ->
                            assertThat(e.getMessage()).contains("quotas"));
        }
    }
}