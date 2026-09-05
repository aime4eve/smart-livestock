package com.smartlivestock.licensing.interfaces.admin.dto;

/**
 * Deployment mode report of {@code GET /api/v1/admin/deployment-license/mode}
 * (NIX-184 T5). Available in every mode so the frontend can detect which
 * feature set to render (cloud subscription self-service vs. offline license
 * management).
 * <p>
 * <b>API contract reference for task T9 (NIX-184).</b>
 */
public record LicenseModeResponse(String mode, boolean pilotLicenseEnabled) {
}
