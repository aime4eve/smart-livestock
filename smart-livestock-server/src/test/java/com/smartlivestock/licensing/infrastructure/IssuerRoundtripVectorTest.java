package com.smartlivestock.licensing.infrastructure;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.licensing.domain.LicenseEnvelope;
import com.smartlivestock.licensing.domain.LicensePayload;
import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInstance;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.time.Instant;
import java.util.Base64;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import static com.smartlivestock.licensing.testsupport.LicenseTestSupport.serializer;
import static com.smartlivestock.licensing.testsupport.LicenseTestSupport.testRegistry;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Round-trip vectors produced by the Python {@code license-issuer} service
 * (task card T6, NIX-184). Reads the files the issuer pytest suite generates
 * under {@code license-issuer/test-vectors/} and asserts that the Java
 * pipeline (canonical serializer + Ed25519 verifier + test trust root)
 * accepts exactly what the Python issuer signed:
 * <ol>
 *   <li>{@code canonical-json-v1.json}: Java and Python canonicalize the same
 *       input byte-for-byte (shared vectors, design section 3)</li>
 *   <li>{@code issuer-roundtrip/}: canonical bytes match, envelope verifies
 *       against the {@code sl-license-test} public key, binding fields match
 *       {@code expected-payload.json}, and a tampered payload is rejected with
 *       {@link ErrorCode#LICENSE_INVALID}</li>
 * </ol>
 * The gradle test working directory must be the {@code smart-livestock-server}
 * module (same requirement as {@code LicenseTestSupport.canonicalVectorFile()}).
 */
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class IssuerRoundtripVectorTest {

    private static final Path VECTORS_FILE =
            Path.of("../license-issuer/test-vectors/canonical-json-v1.json");
    private static final Path ROUNDTRIP_DIR =
            Path.of("../license-issuer/test-vectors/issuer-roundtrip");

    /** Keys whose string values are converted to Instant values before serialization. */
    private static final Set<String> INSTANT_KEYS = Set.of("issuedAt", "expiresAt");

    private static final String TEST_KEY_ID = "sl-license-test";

    private static final ObjectMapper JSON = new ObjectMapper();

    private final CanonicalJsonSerializer serializer = serializer();
    private final Ed25519LicenseVerifier verifier =
            new Ed25519LicenseVerifier(testRegistry(), serializer(),
                    java.time.Duration.ofMinutes(2));

    // ── Shared canonical vectors ─────────────────────────────────────

    @Test
    @DisplayName("shared canonical vectors: Python expected bytes reproduce in Java")
    void canonicalVectorsMatchByteForByte() throws Exception {
        Map<String, Object> vectors = readJsonFile(VECTORS_FILE);
        assertThat(vectors.get("name")).isEqualTo("canonical-json-v1");

        @SuppressWarnings("unchecked")
        List<Map<String, Object>> cases = (List<Map<String, Object>>) vectors.get("cases");
        assertThat(cases).hasSize(3);

        for (Map<String, Object> testCase : cases) {
            String name = (String) testCase.get("name");
            Map<String, Object> input = castMap(testCase.get("input"));
            @SuppressWarnings("unchecked")
            List<String> instantKeys = (List<String>) testCase.get("instantKeys");
            String expected = (String) testCase.get("expectedCanonical");

            Map<String, Object> converted = convertInstants(input, new HashSet<>(instantKeys));
            byte[] produced = serializer.serialize(converted);

            assertThat(new String(produced, StandardCharsets.UTF_8))
                    .as("canonical case '%s'", name)
                    .isEqualTo(expected);
        }
    }

    // ── Issuer round-trip envelope ───────────────────────────────────

    @Test
    @DisplayName("issuer roundtrip: canonical bytes identical and envelope verifies")
    void roundtripEnvelopeVerifies() throws Exception {
        Map<String, Object> expected = readJsonFile(ROUNDTRIP_DIR.resolve("expected-payload.json"));
        String rawEnvelope = Files.readString(ROUNDTRIP_DIR.resolve("issuer-roundtrip.sllicense"),
                StandardCharsets.UTF_8).strip();

        LicenseEnvelope envelope = LicenseEnvelope.parse(rawEnvelope);
        assertThat(envelope.getKeyId()).isEqualTo(expected.get("keyId"));

        // 1. canonical bytes of the expected payload == signed payload bytes
        Map<String, Object> expectedPayload = castMap(expected.get("payload"));
        byte[] canonicalBytes = serializer.serialize(convertInstants(expectedPayload, INSTANT_KEYS));
        byte[] payloadBytes = envelope.decodePayload();
        assertThat(payloadBytes)
                .as("issuer canonical payload must match Java canonical form byte-for-byte")
                .isEqualTo(canonicalBytes);

        // 2. declared digest matches (both envelope field and expected-payload.json)
        String sha256 = sha256Hex(payloadBytes);
        assertThat(sha256).isEqualTo(envelope.getPayloadSha256());
        assertThat(sha256).isEqualTo(expected.get("payloadSha256"));

        // 3. Ed25519 verification against the test trust root
        LicensePayload payload = verifier.verify(envelope);
        assertThat(payload.getKeyId()).isEqualTo(TEST_KEY_ID);
        assertThat(payload.getLicenseId())
                .isEqualTo(UUID.fromString((String) expectedPayload.get("licenseId")));
        assertThat(payload.getTenantId().longValue())
                .isEqualTo(((Number) expectedPayload.get("tenantId")).longValue());
        assertThat(payload.getInstallationId())
                .isEqualTo(UUID.fromString((String) expectedPayload.get("installationId")));
        assertThat(payload.getFingerprintHash())
                .isEqualTo((String) expectedPayload.get("fingerprintHash"));
        assertThat(payload.getLicenseType().name())
                .isEqualTo((String) expectedPayload.get("licenseType"));
        assertThat(payload.getIssuedAt())
                .isEqualTo(Instant.parse((String) expectedPayload.get("issuedAt")));
        assertThat(payload.getExpiresAt())
                .isEqualTo(Instant.parse((String) expectedPayload.get("expiresAt")));
        assertThat(payload.getQuotas())
                .containsAllEntriesOf(castIntMap(expectedPayload.get("quotas")));
        assertThat(payload.getFeatures()).isEmpty();
    }

    @Test
    @DisplayName("issuer roundtrip: tampered payload rejected with LICENSE_INVALID")
    void tamperedRoundtripPayloadRejected() throws Exception {
        String rawEnvelope = Files.readString(ROUNDTRIP_DIR.resolve("issuer-roundtrip.sllicense"),
                StandardCharsets.UTF_8).strip();
        LicenseEnvelope envelope = LicenseEnvelope.parse(rawEnvelope);

        byte[] tamperedPayload = new String(envelope.decodePayload(), StandardCharsets.UTF_8)
                .replace("\"tenantId\":42", "\"tenantId\":43")
                .getBytes(StandardCharsets.UTF_8);

        Map<String, Object> forged = new LinkedHashMap<>();
        forged.put("format", LicenseEnvelope.FORMAT);
        forged.put("keyId", envelope.getKeyId());
        forged.put("payload", Base64.getUrlEncoder().encodeToString(tamperedPayload));
        forged.put("payloadSha256", sha256Hex(tamperedPayload));
        forged.put("signature", envelope.getSignature());
        String forgedJson = JSON.writeValueAsString(forged);

        assertThatThrownBy(() -> verifier.verify(LicenseEnvelope.parse(forgedJson)))
                .isInstanceOfSatisfying(DomainException.class, e ->
                        assertThat(e.getCode()).isEqualTo(ErrorCode.LICENSE_INVALID));
    }

    // ── Helpers ──────────────────────────────────────────────────────

    private Map<String, Object> readJsonFile(Path path) throws Exception {
        if (!Files.isRegularFile(path)) {
            throw new IllegalStateException("issuer vector file not found: "
                    + path.toAbsolutePath()
                    + " (run license-issuer pytest first to generate fixtures)");
        }
        return JSON.readValue(Files.readAllBytes(path), new TypeReference<>() {
        });
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> castMap(Object value) {
        assertThat(value).isInstanceOf(Map.class);
        return (Map<String, Object>) value;
    }

    private static Map<String, Integer> castIntMap(Object value) {
        Map<String, Integer> result = new LinkedHashMap<>();
        castMap(value).forEach((key, item) -> result.put(key, ((Number) item).intValue()));
        return result;
    }

    /** Recursively convert ISO-8601 string values under instantKeys to Instant values. */
    private static Map<String, Object> convertInstants(Map<String, Object> value, Set<String> instantKeys) {
        Map<String, Object> converted = new LinkedHashMap<>();
        for (Map.Entry<String, Object> entry : value.entrySet()) {
            Object item = entry.getValue();
            if (item instanceof Map<?, ?> map) {
                @SuppressWarnings("unchecked")
                Map<String, Object> stringMap = (Map<String, Object>) map;
                converted.put(entry.getKey(), convertInstants(stringMap, instantKeys));
            } else if (item instanceof List<?> list) {
                converted.put(entry.getKey(), list);
            } else if (instantKeys.contains(entry.getKey()) && item instanceof String s) {
                converted.put(entry.getKey(), Instant.parse(s));
            } else {
                converted.put(entry.getKey(), item);
            }
        }
        return converted;
    }

    private static String sha256Hex(byte[] bytes) {
        try {
            return HexFormat.of().formatHex(
                    MessageDigest.getInstance("SHA-256").digest(bytes));
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }
}
