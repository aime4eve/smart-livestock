package com.smartlivestock.identity.application;

import com.smartlivestock.identity.application.SubscriptionExportPolicy.Decision;
import com.smartlivestock.identity.application.SubscriptionExportPolicy.Eligibility;
import com.smartlivestock.identity.application.SubscriptionExportPolicy.DenialReason;
import com.smartlivestock.identity.domain.model.AuditLog;
import com.smartlivestock.identity.domain.model.DataExportJob;
import com.smartlivestock.identity.domain.repository.AuditLogRepository;
import com.smartlivestock.identity.domain.repository.DataExportJobRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.nio.file.Path;
import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Expired-tenant full-data export right (NIX-325, GDPR window per user
 * ruling 2026-10-26): termination + 30 days to request, 30 days to deliver,
 * machine-readable NDJSON-in-zip, full audit trail (request / delivery /
 * cleanup). See {@link SubscriptionExportPolicy} for who qualifies.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class DataExportApplicationService {

    private final DataExportJobRepository jobRepository;
    private final SubscriptionExportPolicy exportPolicy;
    private final AuditLogRepository auditLogRepository;
    private final DataExportFileWriter fileWriter;

    @Value("${smartlivestock.export.file-retention-days:30}")
    private long fileRetentionDays;

    /**
     * Tenant-initiated request. Only the terminated+window-open state passes;
     * every denial reason and the request itself are audited.
     */
    public DataExportJob requestExport(Long tenantId, Long farmId, Long requestedBy) {
        Decision decision = exportPolicy.assess(tenantId, Instant.now());
        if (!decision.isEligible()) {
            audit(tenantId, requestedBy, "DATA_EXPORT_REQUEST_DENIED",
                    Map.of("reason", decision.denialReason().name(), "farmId", farmId));
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, describeDenial(decision.denialReason()));
        }
        // One in-flight package per farm: a fresh request while one is PENDING or
        // COMPLETED-and-undownloaded would just overwrite the same zip content.
        List<DataExportJob> existing = jobRepository.findByTenantIdOrderByIdDesc(tenantId);
        for (DataExportJob job : existing) {
            if (job.getFarmId().equals(farmId)
                    && (job.getStatus() == DataExportJob.Status.PENDING
                        || (job.getStatus() == DataExportJob.Status.COMPLETED
                            && job.isWindowOpen(Instant.now())))) {
                return job; // idempotent re-request
            }
        }
        Eligibility eligibility = decision.eligibility();
        DataExportJob job = DataExportJob.request(tenantId, farmId,
                eligibility.terminatedAt(), eligibility.windowEndsAt(), requestedBy);
        job = jobRepository.save(job);
        audit(tenantId, requestedBy, "DATA_EXPORT_REQUESTED",
                Map.of("jobId", job.getId(), "farmId", farmId,
                        "windowEndsAt", eligibility.windowEndsAt().toString()));
        return job;
    }

    /** Generation pass: picks up one PENDING job at a time (single-node safe). */
    public void generateNextPending() {
        List<DataExportJob> pending = jobRepository.findByStatus(DataExportJob.Status.PENDING);
        if (pending.isEmpty()) {
            return;
        }
        DataExportJob job = pending.get(0);
        try {
            DataExportFileWriter.ExportResult result =
                    fileWriter.writeFarmExport(job.getTenantId(), job.getFarmId(), job.getId());
            job.markCompleted(result.file().toString(), result.sizeBytes(), result.rowCounts());
            jobRepository.save(job);
            audit(job.getTenantId(), job.getRequestedBy(), "DATA_EXPORT_DELIVERED",
                    Map.of("jobId", job.getId(), "farmId", job.getFarmId(),
                            "fileSizeBytes", result.sizeBytes(), "rowCounts", result.rowCounts()));
        } catch (Exception e) {
            log.error("NIX-325 export generation failed for job {}: {}", job.getId(), e.getMessage(), e);
            job.markFailed(truncate(e.getMessage()));
            jobRepository.save(job);
        }
    }

    /** Cleanup pass: deletes package files whose delivery window has closed. */
    public void cleanupExpiredPackages() {
        List<DataExportJob> expired = jobRepository.findCompletedWithWindowEnded(DataExportJob.Status.COMPLETED);
        for (DataExportJob job : expired) {
            // File grace period runs from first download (or window end, whichever is later).
            Instant keepUntil = job.getWindowEndsAt().plusSeconds(fileRetentionDays * 24 * 3600);
            if (Instant.now().isBefore(keepUntil)) {
                continue;
            }
            fileWriter.deleteQuietly(job.getFilePath());
            job.markCleaned();
            jobRepository.save(job);
            audit(job.getTenantId(), null, "DATA_EXPORT_CLEANED",
                    Map.of("jobId", job.getId(), "farmId", job.getFarmId()));
        }
    }

    public DataExportJob getJobForTenant(Long tenantId, Long jobId) {
        DataExportJob job = jobRepository.findById(jobId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "导出任务不存在: " + jobId));
        if (!job.getTenantId().equals(tenantId)) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "无权访问该导出任务");
        }
        return job;
    }

    public List<DataExportJob> listForTenant(Long tenantId) {
        return jobRepository.findByTenantIdOrderByIdDesc(tenantId);
    }

    /** Records first-download time (delivery evidence for the audit trail). */
    public void markDownloaded(DataExportJob job) {
        job.markDownloaded();
        jobRepository.save(job);
    }

    public Path resolveDownload(DataExportJob job) {
        if (job.getStatus() != DataExportJob.Status.COMPLETED || job.getFilePath() == null) {
            throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "导出包尚未生成或已清理");
        }
        if (!job.isWindowOpen(Instant.now())) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "导出窗口已关闭");
        }
        Path path = Path.of(job.getFilePath());
        if (!java.nio.file.Files.exists(path)) {
            throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "导出包文件已不存在");
        }
        return path;
    }

    private static String describeDenial(DenialReason reason) {
        return switch (reason) {
            case NOT_TERMINATED -> "订阅仍在有效期内，无需使用到期导出通道";
            case WINDOW_CLOSED -> "导出窗口已关闭（终止后 30 天）";
            case NO_SUBSCRIPTION -> "租户无订阅记录";
        };
    }

    private void audit(Long tenantId, Long userId, String action, Map<String, Object> details) {
        try {
            auditLogRepository.save(new AuditLog(
                    UUID.randomUUID().toString(),
                    action,
                    tenantId,
                    userId,
                    action,
                    new HashMap<>(details),
                    Instant.now()));
        } catch (Exception e) {
            log.error("NIX-325 failed to audit {} for tenant {}: {}", action, tenantId, e.getMessage());
        }
    }

    private static String truncate(String message) {
        if (message == null) return "export generation failed";
        return message.length() > 1000 ? message.substring(0, 1000) : message;
    }
}
