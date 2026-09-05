package com.smartlivestock.licensing.interfaces.admin.dto;

import java.time.Instant;
import java.util.List;

/**
 * Enrollment response of {@code GET /api/v1/admin/deployment-license/enrollment}
 * (design §8, NIX-184).
 * <p>
 * <b>API contract reference for task T9 (NIX-184):</b> the operator feeds
 * {@code installationId}/{@code fingerprintHash} into the license issuer to
 * produce an offline license envelope.
 */
public record EnrollmentResponse(Long tenantId, String installationId, String fingerprintHash,
                                 String publicKeyId, List<String> supportedPublicKeyIds,
                                 Instant generatedAt) {
}
