package com.smartlivestock.identity.interfaces.open;

import com.smartlivestock.identity.application.DataExportApplicationService;
import com.smartlivestock.identity.domain.model.ApiKey;
import com.smartlivestock.identity.domain.model.DataExportJob;
import com.smartlivestock.shared.tenant.TenantContext;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.security.ApiKeyAuthFilter;
import com.smartlivestock.shared.security.ApiKeyAuthService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.FileSystemResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.nio.file.Path;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Open API — Expired-tenant data export (NIX-325, GDPR window).
 * The API Key's tenant is the subject; the channel only exists for
 * terminated subscriptions inside the 30-day window (ruling 2026-10-26).
 */
@RestController
@RequestMapping("/api/v1/open/data-export")
@RequiredArgsConstructor
public class OpenDataExportController {

    private final ApiKeyAuthService apiKeyAuthService;
    private final DataExportApplicationService dataExportApplicationService;
    private final com.smartlivestock.identity.domain.repository.FarmRepository farmRepository;

    /** GET /api/v1/open/data-export/status — channel state + job history. */
    @GetMapping("/status")
    public ResponseEntity<ApiResponse<Map<String, Object>>> status(HttpServletRequest request) {
        Subject subject = requireSubject(request);
        var jobs = dataExportApplicationService.listForTenant(subject.tenantId());
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("jobs", jobs.stream().map(this::toView).toList());
        return ResponseEntity.ok().body(ApiResponse.ok(data));
    }

    /** POST /api/v1/open/data-export/{farmId}/request — request a package. */
    @PostMapping("/{farmId}/request")
    public ResponseEntity<ApiResponse<Map<String, Object>>> requestExport(
            @PathVariable Long farmId,
            HttpServletRequest request) {
        Subject subject = requireSubject(request);
        com.smartlivestock.identity.domain.model.Farm farm = farmRepository.findById(farmId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "牧场不存在: " + farmId));
        if (!farm.getTenantId().equals(subject.tenantId())) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "无权访问该牧场");
        }
        DataExportJob job = dataExportApplicationService.requestExport(
                subject.tenantId(), farmId, subject.userId());
        return ResponseEntity.ok().body(ApiResponse.ok(toView(job)));
    }

    /** GET /api/v1/open/data-export/jobs/{jobId} — poll one job. */
    @GetMapping("/jobs/{jobId}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getJob(
            @PathVariable Long jobId,
            HttpServletRequest request) {
        Subject subject = requireSubject(request);
        DataExportJob job = dataExportApplicationService.getJobForTenant(subject.tenantId(), jobId);
        return ResponseEntity.ok().body(ApiResponse.ok(toView(job)));
    }

    /** GET /api/v1/open/data-export/jobs/{jobId}/download — stream the zip. */
    @GetMapping("/jobs/{jobId}/download")
    public ResponseEntity<FileSystemResource> download(
            @PathVariable Long jobId,
            HttpServletRequest request) {
        Subject subject = requireSubject(request);
        DataExportJob job = dataExportApplicationService.getJobForTenant(subject.tenantId(), jobId);
        Path path = dataExportApplicationService.resolveDownload(job);
        job.markDownloaded();
        dataExportApplicationService.markDownloaded(job);
        String filename = path.getFileName().toString();
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.APPLICATION_OCTET_STREAM)
                .body(new FileSystemResource(path));
    }

    // ── helpers ────────────────────────────────────────────────

    private Map<String, Object> toView(DataExportJob job) {
        Map<String, Object> view = new LinkedHashMap<>();
        view.put("jobId", job.getId());
        view.put("farmId", job.getFarmId());
        view.put("status", job.getStatus().name());
        view.put("terminatedAt", job.getTerminatedAt());
        view.put("windowEndsAt", job.getWindowEndsAt());
        view.put("requestedAt", job.getRequestedAt());
        view.put("completedAt", job.getCompletedAt());
        view.put("downloadedAt", job.getDownloadedAt());
        view.put("fileSizeBytes", job.getFileSizeBytes());
        view.put("rowCounts", job.getRowCounts());
        if (job.getError() != null) {
            view.put("error", job.getError());
        }
        return view;
    }

    /**
     * Request subject for the dual-channel auth (NIX-324 spec §4.4): the
     * API-Key attribute when present (third-party), otherwise the JWT
     * authenticated tenant (app login). userId is only resolvable on the JWT
     * path here — API-Key requests keep requestedBy null.
     */
    private record Subject(Long tenantId, Long userId) {}

    private Subject requireSubject(HttpServletRequest request) {
        Object attr = request.getAttribute(ApiKeyAuthFilter.ATTR_API_KEY);
        if (attr instanceof ApiKey key) {
            return new Subject(key.getTenantId(), null);
        }
        Long tenantId = TenantContext.getCurrentTenant();
        if (tenantId != null) {
            Long userId = resolveJwtUserId();
            return new Subject(tenantId, userId);
        }
        throw new ApiException(ErrorCode.AUTH_API_KEY_INVALID, "缺少认证上下文（API Key 或登录态）");
    }

    private Long resolveJwtUserId() {
        var auth = org.springframework.security.core.context.SecurityContextHolder
                .getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof Long userId) {
            return userId;
        }
        return null;
    }
}
