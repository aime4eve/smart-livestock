package com.smartlivestock.licensing.interfaces;

import com.smartlivestock.licensing.application.CloudPilotLicenseService;
import com.smartlivestock.licensing.application.PilotLicenseModeGuard;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.time.format.DateTimeParseException;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Hosted pilot license endpoint (design §7, NIX-184).
 * <p>
 * <b>API contract (for task T9 documentation, NIX-184):</b>
 * <pre>
 * POST /api/v1/admin/tenants/{tenantId}/pilot-license
 * Auth: platform_admin role required (Bearer token).
 * Mode gate: HOSTED deployment + smartlivestock.pilot-license.enabled=true;
 *            ONPREM (or disabled) returns 403 AUTH_FORBIDDEN.
 * Success 200:
 * {
 *   "code": "OK",
 *   "message": "success",
 *   "requestId": "&lt;uuid&gt;",
 *   "data": {
 *     "tenantId": "3",
 *     "status": "TRIAL",
 *     "trialEndsAt": "2027-09-03T08:00:00Z"
 *   }
 * }
 * Optional request body (follow-up to ruling 2026-10-12):
 * {
 *   "trialEndsAt": "2027-09-30T21:00:00Z"   // ISO-8601 UTC, must be future
 * }
 * - Provided → per-tenant deadline stored on this tenant's subscription row
 *   (audit deadlineSource=REQUESTED); Kenya example: 2027-10-01 00:00 EAT.
 * - Absent   → platform default smartlivestock.trial.ends-at (CONFIGURED),
 *              or legacy rolling now+365d when unconfigured (ROLLING).
 * Rejections:
 * - 403 AUTH_FORBIDDEN  — not platform_admin, or ONPREM/pilot disabled
 *                         (message key license.pilot.modeForbidden)
 * - 400 VALIDATION_ERROR — trialEndsAt unparseable
 *                         (license.pilot.invalidDeadline) or in the past
 *                         (license.pilot.deadlineInPast)
 * - 409 STATE_CONFLICT  — subscription exists in a state other than an
 *                         active TRIAL (message key
 *                         license.pilot.stateConflict, arg = current status)
 * </pre>
 */
@RestController
@RequestMapping("/api/v1/admin/tenants")
@RequiredArgsConstructor
public class CloudPilotLicenseController {

    private final CloudPilotLicenseService cloudPilotLicenseService;
    private final PilotLicenseModeGuard modeGuard;

    /**
     * POST /api/v1/admin/tenants/{tenantId}/pilot-license
     * Grant (or align) the hosted pilot trial; optional per-tenant deadline.
     */
    @PostMapping("/{tenantId}/pilot-license")
    public ResponseEntity<ApiResponse<Map<String, Object>>> grantPilotLicense(
            @PathVariable Long tenantId,
            @RequestBody(required = false) Map<String, Object> body) {
        requirePlatformAdmin();
        modeGuard.requireHostedPilotEnabled();

        CloudPilotLicenseService.PilotLicenseResult result = cloudPilotLicenseService.grantPilotLicense(
                tenantId, parseRequestedDeadline(body), parseRequestedLocalDate(body));

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("tenantId", result.tenantId() != null ? String.valueOf(result.tenantId()) : null);
        data.put("status", result.status());
        data.put("trialEndsAt", result.trialEndsAt() != null ? result.trialEndsAt().toString() : null);
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    /** Operator-local calendar date ("2027-10-01"); converted via the tenant's own timezone. */
    private java.time.LocalDate parseRequestedLocalDate(Map<String, Object> body) {
        if (body == null) return null;
        Object raw = body.get("localDate");
        if (raw == null || raw.toString().isBlank()) return null;
        try {
            return java.time.LocalDate.parse(raw.toString().trim());
        } catch (Exception e) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "license.pilot.invalidLocalDate", new Object[]{raw.toString()});
        }
    }

    private Instant parseRequestedDeadline(Map<String, Object> body) {
        if (body == null) {
            return null;
        }
        Object raw = body.get("trialEndsAt");
        if (raw == null || raw.toString().isBlank()) {
            return null;
        }
        try {
            return Instant.parse(raw.toString().trim());
        } catch (DateTimeParseException e) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "license.pilot.invalidDeadline", new Object[]{raw.toString()});
        }
    }

    private void requirePlatformAdmin() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "license.pilot.operatorMissing");
        }
        boolean isAdmin = auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_PLATFORM_ADMIN"));
        if (!isAdmin) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "license.pilot.platformAdminRequired");
        }
    }
}
