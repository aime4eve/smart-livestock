package com.smartlivestock.licensing.infrastructure;

import com.smartlivestock.licensing.domain.LicenseBinding;
import com.smartlivestock.licensing.domain.LicenseEnvelope;
import com.smartlivestock.licensing.domain.LicensePayload;
import com.smartlivestock.licensing.domain.LicenseValidationResult;
import com.smartlivestock.licensing.domain.LicenseValidator;
import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.PublicKey;
import java.security.Signature;
import java.time.Duration;
import java.time.Instant;
import java.util.HexFormat;
import java.util.Map;

/**
 * Ed25519 verification pipeline for offline licenses (design section 9,
 * steps 4-7):
 * <ol>
 *   <li>envelope structure and format identifier (done at {@code parse})</li>
 *   <li>keyId resolution against the built-in public key registry</li>
 *   <li>base64url payload decode and SHA-256 digest comparison</li>
 *   <li>Ed25519 signature verification over the canonical payload bytes</li>
 *   <li>binding comparison (tenant / installation / fingerprint)</li>
 *   <li>time window check with configurable tolerance</li>
 * </ol>
 * Cryptographic failures map to {@link ErrorCode#LICENSE_INVALID};
 * binding failures surface as {@link ErrorCode#LICENSE_BINDING_MISMATCH} in
 * the validation result.
 */
public class Ed25519LicenseVerifier implements LicenseValidator {

    private final LicensePublicKeyRegistry registry;
    private final CanonicalJsonSerializer canonicalSerializer;
    private final Duration timeTolerance;

    public Ed25519LicenseVerifier(LicensePublicKeyRegistry registry,
                                  CanonicalJsonSerializer canonicalSerializer,
                                  Duration timeTolerance) {
        this.registry = registry;
        this.canonicalSerializer = canonicalSerializer;
        this.timeTolerance = timeTolerance == null ? Duration.ZERO : timeTolerance;
    }

    /**
     * Cryptographic verification only (no binding/time checks).
     *
     * @throws DomainException LICENSE_INVALID on any pipeline failure
     */
    public LicensePayload verify(LicenseEnvelope envelope) {
        if (envelope == null) {
            throw invalid("envelope is required");
        }
        PublicKey publicKey = registry.forKeyId(envelope.getKeyId());

        byte[] payloadBytes = envelope.decodePayload();
        String actualSha256 = sha256Hex(payloadBytes);
        if (!actualSha256.equals(envelope.getPayloadSha256())) {
            throw invalid("payloadSha256 mismatch");
        }

        byte[] signatureBytes = envelope.decodeSignature();
        try {
            Signature verifier = Signature.getInstance("Ed25519");
            verifier.initVerify(publicKey);
            verifier.update(payloadBytes);
            if (!verifier.verify(signatureBytes)) {
                throw invalid("Ed25519 signature verification failed");
            }
        } catch (DomainException e) {
            throw e;
        } catch (Exception e) {
            throw invalid("Ed25519 signature verification error: " + e.getMessage());
        }

        Map<String, Object> payloadMap = canonicalSerializer.parse(payloadBytes);
        LicensePayload payload = LicensePayload.fromMap(payloadMap);
        if (!envelope.getKeyId().equals(payload.getKeyId())) {
            throw invalid("payload keyId does not match envelope keyId");
        }
        return payload;
    }

    @Override
    public LicenseValidationResult validate(LicenseEnvelope envelope, LicenseBinding binding,
                                            Instant now) {
        LicensePayload payload;
        try {
            payload = verify(envelope);
        } catch (DomainException e) {
            return LicenseValidationResult.failure(e.getCode(), e.getMessage());
        }

        if (!binding.getTenantId().equals(payload.getTenantId())
                || !binding.getInstallationId().equals(payload.getInstallationId())
                || !binding.getFingerprint().matches(payload.getFingerprintHash())) {
            return LicenseValidationResult.failure(payload, ErrorCode.LICENSE_BINDING_MISMATCH,
                    "license is bound to a different tenant/installation/host fingerprint");
        }

        // Tolerance absorbs small clock skew on freshly installed hosts.
        if (payload.getIssuedAt().isAfter(now.plus(timeTolerance))) {
            return LicenseValidationResult.failure(payload, ErrorCode.LICENSE_INVALID,
                    "license is not valid yet (issuedAt in the future)");
        }
        if (!payload.getExpiresAt().isAfter(now)) {
            return LicenseValidationResult.failure(payload, ErrorCode.LICENSE_EXPIRED,
                    "license expired at " + payload.getExpiresAt());
        }
        return LicenseValidationResult.success(payload);
    }

    // ── Helpers ──────────────────────────────────────────────────────

    private static String sha256Hex(byte[] bytes) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(bytes));
        } catch (NoSuchAlgorithmException e) {
            // JRE guarantee: SHA-256 is always available.
            throw new IllegalStateException("SHA-256 algorithm unavailable", e);
        }
    }

    private static DomainException invalid(String detail) {
        return new DomainException(ErrorCode.LICENSE_INVALID, "license verification failed: " + detail);
    }
}
