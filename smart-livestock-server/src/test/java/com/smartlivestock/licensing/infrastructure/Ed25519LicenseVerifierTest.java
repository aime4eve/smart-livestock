package com.smartlivestock.licensing.infrastructure;

import com.smartlivestock.licensing.domain.HostFingerprint;
import com.smartlivestock.licensing.domain.LicenseBinding;
import com.smartlivestock.licensing.domain.LicenseEnvelope;
import com.smartlivestock.licensing.domain.LicensePayload;
import com.smartlivestock.licensing.domain.LicenseValidationResult;
import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.Map;
import java.util.UUID;

import static com.smartlivestock.licensing.testsupport.LicenseTestSupport.FINGERPRINT_HASH;
import static com.smartlivestock.licensing.testsupport.LicenseTestSupport.TEST_KEY_ID;
import static com.smartlivestock.licensing.testsupport.LicenseTestSupport.buildEnvelope;
import static com.smartlivestock.licensing.testsupport.LicenseTestSupport.buildEnvelopeJson;
import static com.smartlivestock.licensing.testsupport.LicenseTestSupport.canonical;
import static com.smartlivestock.licensing.testsupport.LicenseTestSupport.envelopeJson;
import static com.smartlivestock.licensing.testsupport.LicenseTestSupport.serializer;
import static com.smartlivestock.licensing.testsupport.LicenseTestSupport.sha256Hex;
import static com.smartlivestock.licensing.testsupport.LicenseTestSupport.sign;
import static com.smartlivestock.licensing.testsupport.LicenseTestSupport.testRegistry;
import static com.smartlivestock.licensing.testsupport.LicenseTestSupport.validPayloadMap;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class Ed25519LicenseVerifierTest {

    private static final Instant NOW = Instant.now().truncatedTo(java.time.temporal.ChronoUnit.SECONDS);

    private Ed25519LicenseVerifier verifier;

    @BeforeEach
    void setUp() {
        verifier = new Ed25519LicenseVerifier(testRegistry(), serializer(), Duration.ofMinutes(2));
    }

    private static LicenseBinding binding(Long tenantId, String installationId, String fingerprintHex) {
        return new LicenseBinding(tenantId, UUID.fromString(installationId),
                HostFingerprint.of(fingerprintHex));
    }

    private static LicenseBinding matchingBinding() {
        return binding(42L, "9e1c2b3a-4d5e-4f60-8a71-9b0c1d2e3f40", FINGERPRINT_HASH);
    }

    @Nested
    @DisplayName("verify: cryptographic pipeline")
    class Verify {

        @Test
        @DisplayName("sign/verify round trip accepts a well-formed license")
        void roundTrip() {
            LicenseEnvelope envelope = buildEnvelope(validPayloadMap());

            LicensePayload payload = verifier.verify(envelope);

            assertThat(payload.getLicenseId().toString())
                    .isEqualTo("3f2b8a5e-0c1d-4e2f-9a8b-7c6d5e4f3a2b");
            assertThat(payload.getKeyId()).isEqualTo(TEST_KEY_ID);
        }

        @Test
        @DisplayName("tampered signature is rejected with LICENSE_INVALID")
        void tamperedSignature() {
            String json = buildEnvelopeJson(validPayloadMap());
            String tampered = json.replaceAll("\"signature\":\"([^\"]{4})", "\"signature\":\"AAAA");

            assertThatThrownBy(() -> verifier.verify(LicenseEnvelope.parse(tampered)))
                    .isInstanceOfSatisfying(DomainException.class, e ->
                            assertThat(e.getCode()).isEqualTo(ErrorCode.LICENSE_INVALID));
        }

        @Test
        @DisplayName("tampered payload is rejected with LICENSE_INVALID")
        void tamperedPayload() {
            Map<String, Object> payloadMap = validPayloadMap();
            byte[] canonicalBytes = canonical(payloadMap);
            String payloadB64u = Base64.getUrlEncoder().encodeToString(canonicalBytes);
            String signatureB64u = Base64.getUrlEncoder().encodeToString(sign(canonicalBytes));

            // Same signature, different payload bytes (extra tenant appended).
            byte[] tamperedBytes = (new String(canonicalBytes, StandardCharsets.UTF_8))
                    .replace("\"tenantId\":42", "\"tenantId\":43")
                    .getBytes(StandardCharsets.UTF_8);
            String tamperedJson = envelopeJson(TEST_KEY_ID,
                    Base64.getUrlEncoder().encodeToString(tamperedBytes),
                    sha256Hex(tamperedBytes),
                    signatureB64u);

            assertThatThrownBy(() -> verifier.verify(LicenseEnvelope.parse(tamperedJson)))
                    .isInstanceOfSatisfying(DomainException.class, e ->
                            assertThat(e.getCode()).isEqualTo(ErrorCode.LICENSE_INVALID));
        }

        @Test
        @DisplayName("payloadSha256 mismatch is rejected with LICENSE_INVALID")
        void payloadShaMismatch() {
            Map<String, Object> payloadMap = validPayloadMap();
            byte[] canonicalBytes = canonical(payloadMap);
            String payloadB64u = Base64.getUrlEncoder().encodeToString(canonicalBytes);
            String wrongSha = sha256Hex("other-bytes".getBytes(StandardCharsets.UTF_8));
            String signatureB64u = Base64.getUrlEncoder().encodeToString(sign(canonicalBytes));

            String json = envelopeJson(TEST_KEY_ID, payloadB64u, wrongSha, signatureB64u);

            assertThatThrownBy(() -> verifier.verify(LicenseEnvelope.parse(json)))
                    .isInstanceOfSatisfying(DomainException.class, e -> {
                        assertThat(e.getCode()).isEqualTo(ErrorCode.LICENSE_INVALID);
                        assertThat(e.getMessage()).contains("payloadSha256");
                    });
        }

        @Test
        @DisplayName("unsupported keyId is rejected with LICENSE_INVALID")
        void unsupportedKeyId() {
            Map<String, Object> payloadMap = validPayloadMap();
            payloadMap.put("keyId", "sl-license-unknown");
            String json = buildEnvelopeJson(payloadMap);

            assertThatThrownBy(() -> verifier.verify(LicenseEnvelope.parse(json)))
                    .isInstanceOfSatisfying(DomainException.class, e -> {
                        assertThat(e.getCode()).isEqualTo(ErrorCode.LICENSE_INVALID);
                        assertThat(e.getMessage()).contains("not trusted");
                    });
        }

        @Test
        @DisplayName("payload signed correctly but carrying a different keyId than the envelope is rejected")
        void keyIdMismatchBetweenEnvelopeAndPayload() {
            // Registry maps an alias keyId to the SAME trusted key, so the
            // signature verifies but the payload/envelope keyId guard trips.
            String aliasJson = "{\"keys\":["
                    + "{\"keyId\":\"" + TEST_KEY_ID + "\",\"publicKey\":\"TjwpF7USYaTreaj5AbVHJ/+BLIdBplea+c3+20jRJ1w=\",\"status\":\"active\"},"
                    + "{\"keyId\":\"alias-key\",\"publicKey\":\"TjwpF7USYaTreaj5AbVHJ/+BLIdBplea+c3+20jRJ1w=\",\"status\":\"active\"}"
                    + "]}";
            Ed25519LicenseVerifier aliasVerifier = new Ed25519LicenseVerifier(
                    new ClasspathLicensePublicKeyRegistry(
                            new java.io.ByteArrayInputStream(aliasJson.getBytes(StandardCharsets.UTF_8))),
                    serializer(), Duration.ofMinutes(2));

            Map<String, Object> payloadMap = validPayloadMap();
            byte[] canonicalBytes = canonical(payloadMap);
            String payloadB64u = Base64.getUrlEncoder().encodeToString(canonicalBytes);
            String signatureB64u = Base64.getUrlEncoder().encodeToString(sign(canonicalBytes));
            String json = envelopeJson("alias-key", payloadB64u, sha256Hex(canonicalBytes), signatureB64u);

            assertThatThrownBy(() -> aliasVerifier.verify(LicenseEnvelope.parse(json)))
                    .isInstanceOfSatisfying(DomainException.class, e -> {
                        assertThat(e.getCode()).isEqualTo(ErrorCode.LICENSE_INVALID);
                        assertThat(e.getMessage()).contains("keyId");
                    });
        }
    }

    @Nested
    @DisplayName("validate: binding and time window")
    class Validate {

        @Test
        @DisplayName("matching binding and valid window succeeds")
        void success() {
            LicenseValidationResult result =
                    verifier.validate(buildEnvelope(validPayloadMap()), matchingBinding(), NOW);

            assertThat(result.isValid()).isTrue();
            assertThat(result.getPayload()).isNotNull();
            assertThat(result.getErrorCode()).isEmpty();
        }

        @Test
        @DisplayName("tenant mismatch reports LICENSE_BINDING_MISMATCH")
        void tenantMismatch() {
            LicenseValidationResult result = verifier.validate(
                    buildEnvelope(validPayloadMap()),
                    binding(43L, "9e1c2b3a-4d5e-4f60-8a71-9b0c1d2e3f40", FINGERPRINT_HASH),
                    NOW);

            assertThat(result.isValid()).isFalse();
            assertThat(result.getErrorCode()).contains(ErrorCode.LICENSE_BINDING_MISMATCH);
        }

        @Test
        @DisplayName("installation mismatch reports LICENSE_BINDING_MISMATCH")
        void installationMismatch() {
            LicenseValidationResult result = verifier.validate(
                    buildEnvelope(validPayloadMap()),
                    binding(42L, "00000000-0000-0000-0000-000000000001", FINGERPRINT_HASH),
                    NOW);

            assertThat(result.isValid()).isFalse();
            assertThat(result.getErrorCode()).contains(ErrorCode.LICENSE_BINDING_MISMATCH);
        }

        @Test
        @DisplayName("fingerprint mismatch reports LICENSE_BINDING_MISMATCH")
        void fingerprintMismatch() {
            String otherFingerprint = "b".repeat(64);
            LicenseValidationResult result = verifier.validate(
                    buildEnvelope(validPayloadMap()),
                    binding(42L, "9e1c2b3a-4d5e-4f60-8a71-9b0c1d2e3f40", otherFingerprint),
                    NOW);

            assertThat(result.isValid()).isFalse();
            assertThat(result.getErrorCode()).contains(ErrorCode.LICENSE_BINDING_MISMATCH);
        }

        @Test
        @DisplayName("expired license reports LICENSE_EXPIRED")
        void expiredLicense() {
            Map<String, Object> payloadMap = validPayloadMap();
            payloadMap.put("issuedAt", NOW.minusSeconds(2 * 365 * 86400L));
            payloadMap.put("expiresAt", NOW.minusSeconds(86400));

            LicenseValidationResult result =
                    verifier.validate(buildEnvelope(payloadMap), matchingBinding(), NOW);

            assertThat(result.isValid()).isFalse();
            assertThat(result.getErrorCode()).contains(ErrorCode.LICENSE_EXPIRED);
            assertThat(result.getPayload()).isNotNull();
        }

        @Test
        @DisplayName("issuedAt in the future beyond tolerance reports LICENSE_INVALID")
        void notYetValid() {
            Map<String, Object> payloadMap = validPayloadMap();
            payloadMap.put("issuedAt", NOW.plusSeconds(3600));
            payloadMap.put("expiresAt", NOW.plusSeconds(365 * 86400L));

            LicenseValidationResult result =
                    verifier.validate(buildEnvelope(payloadMap), matchingBinding(), NOW);

            assertThat(result.isValid()).isFalse();
            assertThat(result.getErrorCode()).contains(ErrorCode.LICENSE_INVALID);
            assertThat(result.getMessage()).hasValueSatisfying(
                    message -> assertThat(message).contains("not valid yet"));
        }

        @Test
        @DisplayName("issuedAt slightly in the future within tolerance is accepted")
        void toleranceAbsorbsClockSkew() {
            Map<String, Object> payloadMap = validPayloadMap();
            payloadMap.put("issuedAt", NOW.plusSeconds(60));
            payloadMap.put("expiresAt", NOW.plusSeconds(365 * 86400L));

            LicenseValidationResult result =
                    verifier.validate(buildEnvelope(payloadMap), matchingBinding(), NOW);

            assertThat(result.isValid()).isTrue();
        }

        @Test
        @DisplayName("crypto failures surface as LICENSE_INVALID results, not exceptions")
        void cryptoFailureBecomesResult() {
            Map<String, Object> payloadMap = validPayloadMap();
            payloadMap.put("keyId", "sl-license-unknown");

            LicenseValidationResult result =
                    verifier.validate(buildEnvelope(payloadMap), matchingBinding(), NOW);

            assertThat(result.isValid()).isFalse();
            assertThat(result.getErrorCode()).contains(ErrorCode.LICENSE_INVALID);
            assertThat(result.getPayload()).isNull();
        }
    }
}
