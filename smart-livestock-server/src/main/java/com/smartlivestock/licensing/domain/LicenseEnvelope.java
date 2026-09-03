package com.smartlivestock.licensing.domain;

import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;

import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.Base64;
import java.util.Locale;
import java.util.Map;
import java.util.regex.Pattern;

/**
 * Outer envelope of an offline license file (".sllicense", design section 3).
 * <p>
 * Structure:
 * <pre>{@code
 * {
 *   "format": "SMART_LIVESTOCK_LICENSE_V1",
 *   "keyId": "sl-license-2026q3",
 *   "payload": "<base64url canonical JSON>",
 *   "payloadSha256": "<hex>",
 *   "signature": "<base64url Ed25519 signature over the canonical payload bytes>"
 * }
 * }</pre>
 * {@link #parse(String)} performs structural validation only (field presence,
 * format identifier, encodability); cryptographic verification lives in the
 * infrastructure verifier.
 */
public class LicenseEnvelope {

    /** Envelope format identifier; anything else is rejected. */
    public static final String FORMAT = "SMART_LIVESTOCK_LICENSE_V1";

    private static final Pattern HEX_64 = Pattern.compile("^[0-9a-fA-F]{64}$");

    private final String keyId;
    private final String payload;
    private final String payloadSha256;
    private final String signature;

    private LicenseEnvelope(String keyId, String payload, String payloadSha256, String signature) {
        this.keyId = keyId;
        this.payload = payload;
        this.payloadSha256 = payloadSha256;
        this.signature = signature;
    }

    /**
     * Parse the raw JSON text of a {@code .sllicense} file and validate its structure.
     *
     * @throws DomainException LICENSE_INVALID when the JSON is unreadable, a field is
     *                         missing, the format identifier is unknown, or the
     *                         payload/signature are not base64url-decodable
     */
    public static LicenseEnvelope parse(String rawJson) {
        if (rawJson == null || rawJson.isBlank()) {
            throw invalid("license file is empty");
        }
        Map<String, Object> fields = readJson(rawJson);
        String format = requireString(fields, "format");
        if (!FORMAT.equals(format)) {
            throw invalid("unsupported license format: " + format);
        }
        String keyId = requireString(fields, "keyId");
        String payload = requireString(fields, "payload");
        String payloadSha256 = requireString(fields, "payloadSha256");
        String signature = requireString(fields, "signature");
        if (!HEX_64.matcher(payloadSha256).matches()) {
            throw invalid("payloadSha256 must be a 64-character sha256 hex digest");
        }
        decodeBase64Url(payload, "payload");
        decodeBase64Url(signature, "signature");
        return new LicenseEnvelope(keyId, payload, payloadSha256.toLowerCase(Locale.ROOT), signature);
    }

    public String getKeyId() { return keyId; }

    /** base64url-encoded canonical JSON payload bytes. */
    public String getPayload() { return payload; }

    /** Declared SHA-256 hex digest of the canonical payload bytes. */
    public String getPayloadSha256() { return payloadSha256; }

    /** base64url-encoded Ed25519 signature over the canonical payload bytes. */
    public String getSignature() { return signature; }

    /** Decode the payload field into its raw canonical JSON bytes. */
    public byte[] decodePayload() {
        return Base64.getUrlDecoder().decode(payload);
    }

    /** Decode the signature field into its raw Ed25519 signature bytes. */
    public byte[] decodeSignature() {
        return Base64.getUrlDecoder().decode(signature);
    }

    // ── Helpers ──────────────────────────────────────────────────────

    private static DomainException invalid(String detail) {
        return new DomainException(ErrorCode.LICENSE_INVALID, "license envelope invalid: " + detail);
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> readJson(String rawJson) {
        try {
            Object root = new ObjectMapper().readValue(rawJson, Object.class);
            if (!(root instanceof Map)) {
                throw invalid("license file must contain a JSON object");
            }
            return (Map<String, Object>) root;
        } catch (DomainException e) {
            throw e;
        } catch (Exception e) {
            throw invalid("not valid JSON: " + e.getMessage());
        }
    }

    private static String requireString(Map<String, Object> fields, String name) {
        Object value = fields.get(name);
        if (!(value instanceof String s) || s.isBlank()) {
            throw invalid(name + " is required");
        }
        return s;
    }

    private static void decodeBase64Url(String value, String field) {
        try {
            Base64.getUrlDecoder().decode(value);
        } catch (IllegalArgumentException e) {
            throw invalid(field + " must be base64url encoded");
        }
    }
}
