package com.smartlivestock.licensing.infrastructure;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;
import org.springframework.core.io.Resource;

import java.io.IOException;
import java.io.InputStream;
import java.security.KeyFactory;
import java.security.PublicKey;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

/**
 * {@link LicensePublicKeyRegistry} backed by a JSON key list such as
 * {@code classpath:licensing/license-public-keys.json}:
 * <pre>{@code
 * {
 *   "keys": [
 *     {"keyId": "sl-license-2026q3", "publicKey": "<base64 raw 32B>", "status": "active"}
 *   ]
 * }
 * }</pre>
 * {@code status} is {@code active} (current signing key) or {@code rotated}
 * (kept only so licenses signed before a rotation still verify). Both statuses
 * are trusted for verification; missing/corrupt entries fail fast at load time.
 */
public class ClasspathLicensePublicKeyRegistry implements LicensePublicKeyRegistry {

    /** Fixed SPKI header for Ed25519 public keys (RFC 8410), 12 bytes. */
    private static final byte[] ED25519_SPKI_PREFIX = {
            0x30, 0x2a, 0x30, 0x05, 0x06, 0x03, 0x2b, 0x65, 0x70, 0x03, 0x21, 0x00
    };

    private static final int ED25519_RAW_KEY_LENGTH = 32;

    private static final String STATUS_ACTIVE = "active";
    private static final String STATUS_ROTATED = "rotated";

    private final Map<String, PublicKey> keys = new HashMap<>();

    /**
     * Load the registry from a Spring resource (e.g.
     * {@code classpath:licensing/license-public-keys.json}).
     *
     * @throws DomainException LICENSE_INVALID when the resource is missing or malformed
     */
    public ClasspathLicensePublicKeyRegistry(Resource keysResource) {
        try (InputStream in = open(keysResource)) {
            load(in);
        } catch (IOException e) {
            throw invalid("cannot open public keys resource " + describe(keysResource) + ": " + e.getMessage());
        }
    }

    /** Load the registry from an explicit stream (tests / custom provisioning). */
    public ClasspathLicensePublicKeyRegistry(InputStream keysStream) {
        load(keysStream);
    }

    @Override
    public PublicKey forKeyId(String keyId) {
        PublicKey key = keys.get(keyId);
        if (key == null) {
            throw new DomainException(ErrorCode.LICENSE_INVALID,
                    "license keyId is not trusted: " + keyId);
        }
        return key;
    }

    @Override
    public boolean supports(String keyId) {
        return keyId != null && keys.containsKey(keyId);
    }

    /** Number of trusted keys (current + rotated). */
    public int size() {
        return keys.size();
    }

    // ── Loading ──────────────────────────────────────────────────────

    private void load(InputStream in) {
        JsonNode root;
        try {
            root = new ObjectMapper().readTree(in);
        } catch (IOException e) {
            throw invalid("public keys file is not valid JSON: " + e.getMessage());
        }
        if (root == null || !root.has("keys") || !root.get("keys").isArray() || root.get("keys").isEmpty()) {
            throw invalid("public keys file must contain a non-empty \"keys\" array");
        }
        for (JsonNode entry : root.get("keys")) {
            String keyId = text(entry, "keyId");
            String rawBase64 = text(entry, "publicKey");
            String status = text(entry, "status").toLowerCase(Locale.ROOT);
            if (!STATUS_ACTIVE.equals(status) && !STATUS_ROTATED.equals(status)) {
                throw invalid("key " + keyId + " has unsupported status: " + status);
            }
            if (keys.containsKey(keyId)) {
                throw invalid("duplicate keyId in public keys file: " + keyId);
            }
            keys.put(keyId, decodeEd25519PublicKey(keyId, rawBase64));
        }
    }

    private static PublicKey decodeEd25519PublicKey(String keyId, String rawBase64) {
        byte[] raw;
        try {
            raw = Base64.getDecoder().decode(rawBase64);
        } catch (IllegalArgumentException e) {
            throw invalid("key " + keyId + " publicKey is not valid base64");
        }
        if (raw.length != ED25519_RAW_KEY_LENGTH) {
            throw invalid("key " + keyId + " publicKey must be raw 32 bytes, got " + raw.length);
        }
        byte[] spki = new byte[ED25519_SPKI_PREFIX.length + raw.length];
        System.arraycopy(ED25519_SPKI_PREFIX, 0, spki, 0, ED25519_SPKI_PREFIX.length);
        System.arraycopy(raw, 0, spki, ED25519_SPKI_PREFIX.length, raw.length);
        try {
            KeyFactory factory = KeyFactory.getInstance("Ed25519");
            return factory.generatePublic(new X509EncodedKeySpec(spki));
        } catch (Exception e) {
            throw invalid("key " + keyId + " is not a valid Ed25519 public key: " + e.getMessage());
        }
    }

    private static String text(JsonNode node, String field) {
        JsonNode value = node.get(field);
        if (value == null || !value.isTextual() || value.asText().isBlank()) {
            throw invalid("public key entry is missing non-empty field: " + field);
        }
        return value.asText();
    }

    private static InputStream open(Resource resource) throws IOException {
        if (resource == null || !resource.exists()) {
            throw invalid("public keys resource not found: " + describe(resource));
        }
        return resource.getInputStream();
    }

    private static String describe(Resource resource) {
        return resource == null ? "null" : resource.getDescription();
    }

    private static DomainException invalid(String detail) {
        return new DomainException(ErrorCode.LICENSE_INVALID,
                "license public key registry error: " + detail);
    }
}
