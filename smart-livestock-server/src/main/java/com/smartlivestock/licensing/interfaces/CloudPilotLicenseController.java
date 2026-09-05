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
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

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
 * Rejections:
 * - 403 AUTH_FORBIDDEN  — not platform_admin, or ONPREM/pilot disabled
 *                         (message key license.pilot.modeForbidden)
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
     * Grant (or extend) the 365-day hosted pilot trial for the tenant.
     */
    @PostMapping("/{tenantId}/pilot-license")
    public ResponseEntity<ApiResponse<Map<String, Object>>> grantPilotLicense(
            @PathVariable Long tenantId) {
        requirePlatformAdmin();
        modeGuard.requireHostedPilotEnabled();

        CloudPilotLicenseService.PilotLicenseResult result =
            cloudPilotLicenseService.grantPilotLicense(tenantId);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("tenantId", result.tenantId() != null ? String.valueOf(result.tenantId()) : null);
        data.put("status", result.status());
        data.put("trialEndsAt", result.trialEndsAt() != null ? result.trialEndsAt().toString() : null);
        return ResponseEntity.ok(ApiResponse.ok(data));
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
