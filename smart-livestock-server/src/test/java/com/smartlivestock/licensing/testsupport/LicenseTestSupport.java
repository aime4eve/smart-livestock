package com.smartlivestock.licensing.testsupport;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.licensing.domain.LicenseEnvelope;
import com.smartlivestock.licensing.infrastructure.CanonicalJsonSerializer;
import com.smartlivestock.licensing.infrastructure.ClasspathLicensePublicKeyRegistry;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyFactory;
import java.security.MessageDigest;
import java.security.PrivateKey;
import java.security.Signature;
import java.security.spec.PKCS8EncodedKeySpec;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Shared fixture helpers for licensing unit tests: loads the test Ed25519 key
 * ({@code sl-license-test}) from the test classpath and builds well-formed
 * license envelopes for verification scenarios.
 */
public final class LicenseTestSupport {

    public static final String TEST_KEY_ID = "sl-license-test";
    public static final String FORMAT = "SMART_LIVESTOCK_LICENSE_V1";

    /** Fingerprint digest used by fixture payloads (64 hex chars). */
    public static final String FINGERPRINT_HASH =
            "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";

    private static final ObjectMapper JSON = new ObjectMapper();

    private LicenseTestSupport() {
    }

    public static CanonicalJsonSerializer serializer() {
        return new CanonicalJsonSerializer();
    }

    /** Registry backed by {@code classpath:licensing/license-public-keys.json} (test resources). */
    public static ClasspathLicensePublicKeyRegistry testRegistry() {
        try (InputStream in = LicenseTestSupport.class.getClassLoader()
                .getResourceAsStream("licensing/license-public-keys.json")) {
            if (in == null) {
                throw new IllegalStateException("test license-public-keys.json not on classpath");
            }
            return new ClasspathLicensePublicKeyRegistry(in);
        } catch (Exception e) {
            throw new IllegalStateException("cannot load test license public keys", e);
        }
    }

    /** Private key parsed from {@code classpath:licensing/sl-license-test.pem}. */
    public static PrivateKey testPrivateKey() {
        try (InputStream in = LicenseTestSupport.class.getClassLoader()
                .getResourceAsStream("licensing/sl-license-test.pem")) {
            if (in == null) {
                throw new IllegalStateException("sl-license-test.pem not on test classpath");
            }
            String pem = new String(in.readAllBytes(), StandardCharsets.UTF_8)
                    .replaceAll("-----BEGIN [A-Z ]+-----", "")
                    .replaceAll("-----END [A-Z ]+-----", "")
                    .replaceAll("\\s", "");
            byte[] der = Base64.getDecoder().decode(pem);
            return KeyFactory.getInstance("Ed25519")
                    .generatePrivate(new PKCS8EncodedKeySpec(der));
        } catch (Exception e) {
            throw new IllegalStateException("cannot load test Ed25519 private key", e);
        }
    }

    /** A fully valid payload map; times are Instant values relative to now. */
    public static Map<String, Object> validPayloadMap() {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("payloadVersion", 1);
        payload.put("licenseId", "3f2b8a5e-0c1d-4e2f-9a8b-7c6d5e4f3a2b");
        payload.put("tenantId", 42L);
        payload.put("installationId", "9e1c2b3a-4d5e-4f60-8a71-9b0c1d2e3f40");
        payload.put("fingerprintHash", FINGERPRINT_HASH);
        payload.put("keyId", TEST_KEY_ID);
        payload.put("licenseType", "TRIAL");
        payload.put("tier", "BASIC");
        payload.put("effectiveTier", "PREMIUM");
        payload.put("issuedAt", Instant.now().minusSeconds(3600).truncatedTo(java.time.temporal.ChronoUnit.SECONDS));
        payload.put("expiresAt", Instant.now().plusSeconds(365 * 86400L).truncatedTo(java.time.temporal.ChronoUnit.SECONDS));
        Map<String, Object> quotas = new LinkedHashMap<>();
        quotas.put("livestock_management", 1000);
        quotas.put("fence_management", 100);
        quotas.put("worker_management", 50);
        quotas.put("device_management", 1000);
        payload.put("quotas", quotas);
        payload.put("features", new LinkedHashMap<String, Object>());
        return payload;
    }

    /** Canonical bytes for a payload map. */
    public static byte[] canonical(Map<String, Object> payloadMap) {
        return serializer().serialize(payloadMap);
    }

    /** Sign canonical payload bytes with the test private key. */
    public static byte[] sign(byte[] canonicalPayloadBytes) {
        try {
            Signature signer = Signature.getInstance("Ed25519");
            signer.initSign(testPrivateKey());
            signer.update(canonicalPayloadBytes);
            return signer.sign();
        } catch (Exception e) {
            throw new IllegalStateException("cannot sign test payload", e);
        }
    }

    public static String sha256Hex(byte[] bytes) {
        try {
            return HexFormat.of().formatHex(
                    MessageDigest.getInstance("SHA-256").digest(bytes));
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }

    /** Build a signed, well-formed envelope for the given payload map. */
    public static LicenseEnvelope buildEnvelope(Map<String, Object> payloadMap) {
        return LicenseEnvelope.parse(buildEnvelopeJson(payloadMap));
    }

    /** Raw envelope JSON for the given payload map, signed with the test key. */
    public static String buildEnvelopeJson(Map<String, Object> payloadMap) {
        byte[] canonicalBytes = canonical(payloadMap);
        String payloadB64u = Base64.getUrlEncoder().encodeToString(canonicalBytes);
        String sha256 = sha256Hex(canonicalBytes);
        String signatureB64u = Base64.getUrlEncoder().encodeToString(sign(canonicalBytes));
        return envelopeJson((String) payloadMap.get("keyId"), payloadB64u, sha256, signatureB64u);
    }

    /** Envelope JSON with explicit parts (used for tampering scenarios). */
    public static String envelopeJson(String keyId, String payloadB64u, String sha256Hex,
                                      String signatureB64u) {
        Map<String, Object> envelope = new LinkedHashMap<>();
        envelope.put("format", FORMAT);
        envelope.put("keyId", keyId);
        envelope.put("payload", payloadB64u);
        envelope.put("payloadSha256", sha256Hex);
        envelope.put("signature", signatureB64u);
        try {
            return JSON.writeValueAsString(envelope);
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }

    /** Path of the shared canonical JSON vectors relative to the module dir. */
    public static Path canonicalVectorFile() {
        Path path = Path.of("../license-issuer/test-vectors/canonical-json-v1.json");
        if (!Files.isRegularFile(path)) {
            throw new IllegalStateException(
                    "shared canonical vectors not found at " + path.toAbsolutePath()
                            + " (gradle test working dir must be the smart-livestock-server module)");
        }
        return path;
    }
}
