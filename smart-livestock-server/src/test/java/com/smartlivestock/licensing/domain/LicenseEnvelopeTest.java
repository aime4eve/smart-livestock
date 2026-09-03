package com.smartlivestock.licensing.domain;

import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.Map;

import static com.smartlivestock.licensing.testsupport.LicenseTestSupport.TEST_KEY_ID;
import static com.smartlivestock.licensing.testsupport.LicenseTestSupport.canonical;
import static com.smartlivestock.licensing.testsupport.LicenseTestSupport.envelopeJson;
import static com.smartlivestock.licensing.testsupport.LicenseTestSupport.sha256Hex;
import static com.smartlivestock.licensing.testsupport.LicenseTestSupport.sign;
import static com.smartlivestock.licensing.testsupport.LicenseTestSupport.validPayloadMap;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class LicenseEnvelopeTest {

    private static final String PAYLOAD_SHA = "aa".repeat(32);

    @Nested
    @DisplayName("parse: structural validation")
    class Parse {

        @Test
        void parsesWellFormedEnvelope() {
            String json = envelopeJson(TEST_KEY_ID, "cGF5bG9hZA", PAYLOAD_SHA, "c2lnbmF0dXJl");

            LicenseEnvelope envelope = LicenseEnvelope.parse(json);

            assertThat(envelope.getKeyId()).isEqualTo(TEST_KEY_ID);
            assertThat(envelope.getPayload()).isEqualTo("cGF5bG9hZA");
            assertThat(envelope.getPayloadSha256()).isEqualTo(PAYLOAD_SHA);
            assertThat(envelope.getSignature()).isEqualTo("c2lnbmF0dXJl");
        }

        @Test
        void decodesPayloadAndSignatureBytes() {
            byte[] canonicalBytes = canonical(validPayloadMap());
            String payloadB64u = Base64.getUrlEncoder().encodeToString(canonicalBytes);
            byte[] signature = sign(canonicalBytes);
            String json = envelopeJson(TEST_KEY_ID, payloadB64u, sha256Hex(canonicalBytes),
                    Base64.getUrlEncoder().encodeToString(signature));

            LicenseEnvelope envelope = LicenseEnvelope.parse(json);

            assertThat(envelope.decodePayload()).isEqualTo(canonicalBytes);
            assertThat(envelope.decodeSignature()).isEqualTo(signature);
        }

        @Test
        void rejectsBlankInput() {
            assertThatThrownBy(() -> LicenseEnvelope.parse(" "))
                    .isInstanceOfSatisfying(DomainException.class, e ->
                            assertThat(e.getCode()).isEqualTo(ErrorCode.LICENSE_INVALID));
        }

        @Test
        void rejectsNonJsonInput() {
            assertThatThrownBy(() -> LicenseEnvelope.parse("not json at all"))
                    .isInstanceOfSatisfying(DomainException.class, e -> {
                        assertThat(e.getCode()).isEqualTo(ErrorCode.LICENSE_INVALID);
                        assertThat(e.getMessage()).contains("not valid JSON");
                    });
        }

        @Test
        void rejectsUnsupportedFormat() {
            String json = envelopeWithFormat("SOME_OTHER_FORMAT_V9");

            assertThatThrownBy(() -> LicenseEnvelope.parse(json))
                    .isInstanceOfSatisfying(DomainException.class, e ->
                            assertThat(e.getCode()).isEqualTo(ErrorCode.LICENSE_INVALID));
        }

        @Test
        void rejectsMissingSignature() {
            Map<String, Object> envelope = baseParts();
            envelope.remove("signature");
            String json = toJson(envelope);

            assertThatThrownBy(() -> LicenseEnvelope.parse(json))
                    .isInstanceOfSatisfying(DomainException.class, e ->
                            assertThat(e.getMessage()).contains("signature"));
        }

        @Test
        void rejectsPayloadSha256ThatIsNotHex64() {
            String json = envelopeJson(TEST_KEY_ID, "cGF5bG9hZA", "abc123", "c2lnbmF0dXJl");

            assertThatThrownBy(() -> LicenseEnvelope.parse(json))
                    .isInstanceOfSatisfying(DomainException.class, e ->
                            assertThat(e.getMessage()).contains("payloadSha256"));
        }

        @Test
        void rejectsPayloadThatIsNotBase64Url() {
            String json = envelopeJson(TEST_KEY_ID, "not!!base64url", PAYLOAD_SHA, "c2lnbmF0dXJl");

            assertThatThrownBy(() -> LicenseEnvelope.parse(json))
                    .isInstanceOfSatisfying(DomainException.class, e ->
                            assertThat(e.getMessage()).contains("payload"));
        }

        @Test
        void normalizesPayloadSha256ToLowerCase() {
            String json = envelopeJson(TEST_KEY_ID, "cGF5bG9hZA", PAYLOAD_SHA.toUpperCase(),
                    "c2lnbmF0dXJl");

            assertThat(LicenseEnvelope.parse(json).getPayloadSha256()).isEqualTo(PAYLOAD_SHA);
        }
    }

    // ── Helpers ──────────────────────────────────────────────────────

    private Map<String, Object> baseParts() {
        Map<String, Object> envelope = new LinkedHashMap<>();
        envelope.put("format", "SMART_LIVESTOCK_LICENSE_V1");
        envelope.put("keyId", TEST_KEY_ID);
        envelope.put("payload", "cGF5bG9hZA");
        envelope.put("payloadSha256", PAYLOAD_SHA);
        envelope.put("signature", "c2lnbmF0dXJl");
        return envelope;
    }

    private String envelopeWithFormat(String format) {
        Map<String, Object> envelope = baseParts();
        envelope.put("format", format);
        return toJson(envelope);
    }

    private String toJson(Map<String, Object> envelope) {
        try {
            return new com.fasterxml.jackson.databind.ObjectMapper()
                    .writeValueAsString(envelope);
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }
}
