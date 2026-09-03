package com.smartlivestock.licensing.interfaces.admin.dto;

import java.time.Instant;

/**
 * Import result of {@code POST /api/v1/admin/deployment-license} (design §8/§9,
 * NIX-184).
 * <p>
 * <b>API contract reference for task T9 (NIX-184).</b>
 */
public record ImportLicenseResponse(Long tenantId, String licenseId, String licenseType,
                                    String tier, String effectiveTier, Instant expiresAt,
                                    String runtimeStatus) {
}
