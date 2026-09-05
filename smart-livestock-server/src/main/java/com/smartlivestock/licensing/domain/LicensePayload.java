package com.smartlivestock.licensing.domain;

import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;

import java.time.Instant;
import java.time.format.DateTimeParseException;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

/**
 * Signed payload of an offline license file (design section 3).
 * <p>
 * Field set is fixed; unknown fields are rejected on parse so that a payload
 * can never silently carry unsigned semantics. Serialization to the canonical
 * JSON form (sorted keys, compact separators, UTC instants, integral numbers)
 * is performed by the infrastructure canonical serializer over {@link #toMap()}.
 */
public class LicensePayload {

    /** Current payload schema version produced by the issuer. */
    public static final int CURRENT_VERSION = 1;

    private int payloadVersion;
    private UUID licenseId;
    private Long tenantId;
    private UUID installationId;
    /** SHA-256 hex digest of the host fingerprint this license is bound to. */
    private String fingerprintHash;
    /** Identifier of the issuer key that signed this payload. */
    private String keyId;
    private LicenseType licenseType;
    private String tier;
    private String effectiveTier;
    private Instant issuedAt;
    private Instant expiresAt;
    /** Named resource quotas; keys follow feature keys (e.g. "livestock_management"). */
    private Map<String, Integer> quotas;
    /** Free-form feature switches consumed by the feature gate layer. */
    private Map<String, Object> features;
    /** License replaced by this one; {@code null} for first issuance. */
    private UUID replacesLicenseId;

    /**
     * Convert the payload to a transport/signing map for canonical serialization.
     * Timestamps stay as {@link Instant}; the canonical serializer renders them
     * in UTC {@code yyyy-MM-dd'T'HH:mm:ss'Z'} form. {@code replacesLicenseId} is
     * omitted entirely when absent so the signed form stays deterministic.
     */
    public Map<String, Object> toMap() {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("payloadVersion", payloadVersion);
        map.put("licenseId", licenseId.toString());
        map.put("tenantId", tenantId);
        map.put("installationId", installationId.toString());
        map.put("fingerprintHash", fingerprintHash);
        map.put("keyId", keyId);
        map.put("licenseType", licenseType.name());
        map.put("tier", tier);
        map.put("effectiveTier", effectiveTier);
        map.put("issuedAt", issuedAt);
        map.put("expiresAt", expiresAt);
        map.put("quotas", new LinkedHashMap<>(quotas));
        map.put("features", new LinkedHashMap<>(features));
        if (replacesLicenseId != null) {
            map.put("replacesLicenseId", replacesLicenseId.toString());
        }
        return map;
    }

    /**
     * Parse and validate a payload map decoded from a license envelope.
     *
     * @throws DomainException LICENSE_INVALID when a required field is missing,
     *                         has an unexpected type, or fails validation
     */
    public static LicensePayload fromMap(Map<String, Object> map) {
        requireMap(map);
        LicensePayload payload = new LicensePayload();
        payload.payloadVersion = requireInt(map, "payloadVersion");
        if (payload.payloadVersion != CURRENT_VERSION) {
            throw invalid("unsupported payloadVersion: " + payload.payloadVersion);
        }
        payload.licenseId = requireUuid(map, "licenseId");
        payload.tenantId = requireLong(map, "tenantId");
        payload.installationId = requireUuid(map, "installationId");
        payload.fingerprintHash = requireHex64(map, "fingerprintHash");
        payload.keyId = requireString(map, "keyId");
        payload.licenseType = requireEnum(map, "licenseType", LicenseType.class);
        payload.tier = requireString(map, "tier");
        payload.effectiveTier = requireString(map, "effectiveTier");
        payload.issuedAt = requireInstant(map, "issuedAt");
        payload.expiresAt = requireInstant(map, "expiresAt");
        payload.quotas = requireQuotas(map.get("quotas"));
        payload.features = requireFeatures(map.get("features"));
        payload.replacesLicenseId = optionalUuid(map, "replacesLicenseId");
        if (!payload.expiresAt.isAfter(payload.issuedAt)) {
            throw invalid("expiresAt must be after issuedAt");
        }
        return payload;
    }

    // ── Getters ──────────────────────────────────────────────────────

    public int getPayloadVersion() { return payloadVersion; }

    public UUID getLicenseId() { return licenseId; }

    public Long getTenantId() { return tenantId; }

    public UUID getInstallationId() { return installationId; }

    public String getFingerprintHash() { return fingerprintHash; }

    public String getKeyId() { return keyId; }

    public LicenseType getLicenseType() { return licenseType; }

    public String getTier() { return tier; }

    public String getEffectiveTier() { return effectiveTier; }

    public Instant getIssuedAt() { return issuedAt; }

    public Instant getExpiresAt() { return expiresAt; }

    public Map<String, Integer> getQuotas() { return new LinkedHashMap<>(quotas); }

    public Map<String, Object> getFeatures() { return new LinkedHashMap<>(features); }

    public UUID getReplacesLicenseId() { return replacesLicenseId; }

    // ── Parsing helpers ──────────────────────────────────────────────

    private static DomainException invalid(String detail) {
        return new DomainException(ErrorCode.LICENSE_INVALID, "license payload invalid: " + detail);
    }

    private static void requireMap(Map<String, Object> map) {
        if (map == null || map.isEmpty()) {
            throw invalid("payload must be a non-empty JSON object");
        }
    }

    private static String requireString(Map<String, Object> map, String field) {
        Object value = map.get(field);
        if (!(value instanceof String s) || s.isBlank()) {
            throw invalid(field + " must be a non-empty string");
        }
        return s;
    }

    private static int requireInt(Map<String, Object> map, String field) {
        Object value = map.get(field);
        if (!(value instanceof Number n)) {
            throw invalid(field + " must be an integer");
        }
        return n.intValue();
    }

    private static Long requireLong(Map<String, Object> map, String field) {
        Object value = map.get(field);
        if (!(value instanceof Number n)) {
            throw invalid(field + " must be an integer");
        }
        return n.longValue();
    }

    private static UUID requireUuid(Map<String, Object> map, String field) {
        String value = requireString(map, field);
        try {
            return UUID.fromString(value);
        } catch (IllegalArgumentException e) {
            throw invalid(field + " must be a UUID");
        }
    }

    private static UUID optionalUuid(Map<String, Object> map, String field) {
        Object value = map.get(field);
        if (value == null) {
            return null;
        }
        try {
            return UUID.fromString(value.toString());
        } catch (IllegalArgumentException e) {
            throw invalid(field + " must be a UUID");
        }
    }

    private static String requireHex64(Map<String, Object> map, String field) {
        String value = requireString(map, field);
        return HostFingerprint.of(value).getValue();
    }

    private static <E extends Enum<E>> E requireEnum(Map<String, Object> map, String field,
                                                     Class<E> enumType) {
        String value = requireString(map, field);
        try {
            return Enum.valueOf(enumType, value);
        } catch (IllegalArgumentException e) {
            throw invalid(field + " must be one of " + enumType.getSimpleName()
                    + " but was '" + value + "'");
        }
    }

    private static Instant requireInstant(Map<String, Object> map, String field) {
        Object value = map.get(field);
        // Accept both canonical string form (decoded JSON) and Instant form
        // (in-memory map before canonical serialization).
        if (value instanceof Instant instant) {
            return instant;
        }
        String s = requireString(map, field);
        try {
            return Instant.parse(s);
        } catch (DateTimeParseException e) {
            throw invalid(field + " must be a UTC instant (yyyy-MM-dd'T'HH:mm:ss'Z')");
        }
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Integer> requireQuotas(Object value) {
        if (!(value instanceof Map<?, ?> raw)) {
            throw invalid("quotas must be an object");
        }
        Map<String, Integer> quotas = new LinkedHashMap<>();
        for (Map.Entry<?, ?> entry : ((Map<Object, Object>) raw).entrySet()) {
            if (!(entry.getKey() instanceof String key) || key.isBlank()) {
                throw invalid("quotas keys must be non-empty strings");
            }
            if (!(entry.getValue() instanceof Number n)) {
                throw invalid("quotas." + key + " must be an integer");
            }
            quotas.put(key, n.intValue());
        }
        return quotas;
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> requireFeatures(Object value) {
        if (value == null) {
            return new LinkedHashMap<>();
        }
        if (!(value instanceof Map<?, ?> raw)) {
            throw invalid("features must be an object");
        }
        Map<String, Object> features = new LinkedHashMap<>();
        for (Map.Entry<?, ?> entry : ((Map<Object, Object>) raw).entrySet()) {
            if (!(entry.getKey() instanceof String key) || key.isBlank()) {
                throw invalid("features keys must be non-empty strings");
            }
            features.put(key, entry.getValue());
        }
        return features;
    }
}
