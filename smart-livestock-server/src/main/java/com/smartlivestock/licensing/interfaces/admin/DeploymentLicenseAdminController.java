package com.smartlivestock.licensing.interfaces.admin;

import com.smartlivestock.licensing.application.DeploymentLicenseApplicationService;
import com.smartlivestock.licensing.application.LicenseModeGuard;
import com.smartlivestock.licensing.application.PilotLicenseModeGuard;
import com.smartlivestock.licensing.interfaces.admin.dto.DeploymentLicenseResponseAssembler;
import com.smartlivestock.licensing.interfaces.admin.dto.DeploymentLicenseStatusResponse;
import com.smartlivestock.licensing.interfaces.admin.dto.EnrollmentResponse;
import com.smartlivestock.licensing.interfaces.admin.dto.ImportLicenseResponse;
import com.smartlivestock.licensing.interfaces.admin.dto.LicenseModeResponse;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

/**
 * On-premise deployment license management API (design §8, NIX-184 T5).
 * <p>
 * <b>API contract (for task T9 documentation, NIX-184):</b>
 * <pre>
 * Base: /api/v1/admin/deployment-license — all endpoints require the
 * platform_admin role (hand-written guard, TenantAdminController precedent).
 *
 * GET  /enrollment?tenantId={id}   — ONPREM-only. Enrollment info (installation
 *                                    id + host fingerprint) for license issuance.
 * POST /?tenantId={id}             — ONPREM-only. multipart/form-data with
 *                                    {@code file} (UTF-8 license envelope text)
 *                                    and {@code confirm=true}; otherwise
 *                                    VALIDATION_ERROR.
 * GET  /current?tenantId={id}      — ONPREM-only. Full license/runtime/subscription
 *                                    status view.
 * GET  /mode                       — any mode. Reports {mode, pilotLicenseEnabled}
 *                                    so the frontend can detect the feature set.
 * </pre>
 * Rejections:
 * <ul>
 *   <li>403 AUTH_FORBIDDEN — not platform_admin, or HOSTED mode hitting an
 *       ONPREM-only endpoint (message key {@code license.onpremOnly})</li>
 *   <li>400 VALIDATION_ERROR — missing/empty file, size limit, or confirm=false</li>
 *   <li>403 LICENSE_* — envelope refused by the validation pipeline (§9)</li>
 * </ul>
 */
@RestController
@RequestMapping("/api/v1/admin/deployment-license")
@RequiredArgsConstructor
public class DeploymentLicenseAdminController {

    /** License envelopes are small JSON text files; 512 KiB is a generous cap. */
    public static final int MAX_ENVELOPE_BYTES = 512 * 1024;

    private final DeploymentLicenseApplicationService applicationService;
    private final LicenseModeGuard licenseModeGuard;
    private final PilotLicenseModeGuard pilotLicenseModeGuard;

    /**
     * GET /api/v1/admin/deployment-license/enrollment?tenantId=
     * Return (or lazily create) the tenant's installation registration.
     */
    @GetMapping("/enrollment")
    public ResponseEntity<ApiResponse<EnrollmentResponse>> enrollment(
            @RequestParam("tenantId") Long tenantId) {
        requirePlatformAdmin();
        licenseModeGuard.requireOnPrem();

        EnrollmentResponse response = DeploymentLicenseResponseAssembler.toResponse(
                applicationService.enroll(tenantId));
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    /**
     * POST /api/v1/admin/deployment-license?tenantId=
     * Import an offline license envelope (multipart {@code file} as UTF-8
     * text); {@code confirm} must be {@code true} — the import drives the
     * tenant subscription (design §9 mapping).
     */
    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<ImportLicenseResponse>> importLicense(
            @RequestParam("tenantId") Long tenantId,
            @RequestParam(name = "file", required = false) MultipartFile file,
            @RequestParam(name = "confirm", required = false) Boolean confirm) {
        requirePlatformAdmin();
        licenseModeGuard.requireOnPrem();

        String rawEnvelope = readEnvelope(file);
        // A missing confirm flag is treated as "not confirmed" on purpose:
        // the application service owns the license.import.confirmRequired rejection.
        ImportLicenseResponse response = DeploymentLicenseResponseAssembler.toResponse(
                applicationService.importLicense(tenantId, rawEnvelope,
                        Boolean.TRUE.equals(confirm)));
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    /**
     * GET /api/v1/admin/deployment-license/current?tenantId=
     * Current license, runtime state, subscription mapping and tamper-guard
     * anchors for the tenant.
     */
    @GetMapping("/current")
    public ResponseEntity<ApiResponse<DeploymentLicenseStatusResponse>> current(
            @RequestParam("tenantId") Long tenantId) {
        requirePlatformAdmin();
        licenseModeGuard.requireOnPrem();

        DeploymentLicenseStatusResponse response = DeploymentLicenseResponseAssembler.toResponse(
                applicationService.currentStatus(tenantId));
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    /**
     * GET /api/v1/admin/deployment-license/mode
     * Report the deployment mode and pilot-license availability. Unlike the
     * other endpoints this is usable in every mode (frontend bootstrapping).
     */
    @GetMapping("/mode")
    public ResponseEntity<ApiResponse<LicenseModeResponse>> mode() {
        requirePlatformAdmin();

        return ResponseEntity.ok(ApiResponse.ok(new LicenseModeResponse(
                licenseModeGuard.modeName(),
                pilotLicenseModeGuard.isHostedPilotEnabled())));
    }

    // ── Guards / helpers ─────────────────────────────────────────────

    /** Hand-written platform_admin guard (TenantAdminController precedent). */
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

    /**
     * Read the uploaded envelope as UTF-8 text. Missing/empty files and
     * oversized uploads are rejected up front with VALIDATION_ERROR; content
     * parsing failures are owned by the application service (LICENSE_INVALID).
     */
    private String readEnvelope(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "license.import.fileRequired");
        }
        if (file.getSize() > MAX_ENVELOPE_BYTES) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "license.import.fileTooLarge");
        }
        try {
            return new String(file.getBytes(), StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "license.import.fileUnreadable");
        }
    }
}
