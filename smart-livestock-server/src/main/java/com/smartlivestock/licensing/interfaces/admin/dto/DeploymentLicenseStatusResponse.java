package com.smartlivestock.licensing.interfaces.admin.dto;

import java.time.Instant;

/**
 * Full current-status response of
 * {@code GET /api/v1/admin/deployment-license/current} (design §8, NIX-184).
 * <p>
 * <b>API contract reference for task T9 (NIX-184).</b>
 */
public record DeploymentLicenseStatusResponse(Long tenantId, String installationId,
                                              String fingerprintHash, String runtimeStatus,
                                              String licenseId, String licenseType, String tier,
                                              String effectiveTier, Instant issuedAt,
                                              Instant expiresAt, Instant acceptedAt,
                                              Instant lastValidatedAt, String lastResult,
                                              String lastErrorCode, Instant maxObservedAt,
                                              String protectionReason, String subscriptionStatus,
                                              Instant subscriptionTrialEndsAt) {
}
