package com.smartlivestock.iot.interfaces.admin;

import com.smartlivestock.iot.application.TelemetryImportService;
import com.smartlivestock.iot.interfaces.admin.dto.TelemetryImportResultDto;
import com.smartlivestock.iot.interfaces.admin.dto.TelemetryParseResultDto;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.tenant.TenantContext;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

/**
 * Admin endpoints for manual telemetry file import (NIX-79).
 * <p>
 * Two-step flow: {@code /parse} previews the file with zero persistence,
 * {@code /import} re-runs the pipeline and ingests IMPORTABLE rows.
 * Tenant resolution follows the {@link GpsQualityAdminController} precedent:
 * platform_admin has no tenant, so imports fall back to the demo tenant.
 */
@RestController
@RequestMapping("/api/v1/admin/telemetry-import")
@RequiredArgsConstructor
@PreAuthorize("hasRole('PLATFORM_ADMIN')")
public class TelemetryImportAdminController {

    private final TelemetryImportService telemetryImportService;

    // platform_admin has no tenant; telemetry imports fall back to the demo tenant.
    private static final long FALLBACK_TENANT_ID = 1L;

    private Long resolveTenantId() {
        Long tenantId = TenantContext.getCurrentTenant();
        return tenantId != null ? tenantId : FALLBACK_TENANT_ID;
    }

    /**
     * Parse a blade telemetry export (xlsx) and return a per-row preview.
     * Zero persistence.
     */
    @PostMapping(value = "/parse", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<TelemetryParseResultDto>> parse(
            @RequestParam("file") MultipartFile file) {
        TelemetryParseResultDto result = telemetryImportService.parse(file, resolveTenantId());
        return ResponseEntity.ok(ApiResponse.ok(result));
    }

    /**
     * Import a blade telemetry export (xlsx): IMPORTABLE rows are ingested in
     * time-ascending order as MANUAL_IMPORT; duplicates/skips are reported.
     */
    @PostMapping(value = "/import", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<TelemetryImportResultDto>> importFile(
            @RequestParam("file") MultipartFile file) {
        TelemetryImportResultDto result = telemetryImportService.importFile(file, resolveTenantId());
        return ResponseEntity.ok(ApiResponse.ok(result));
    }
}
