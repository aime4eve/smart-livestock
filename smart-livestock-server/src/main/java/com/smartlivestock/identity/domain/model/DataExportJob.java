package com.smartlivestock.identity.domain.model;

import java.time.Instant;
import java.util.Map;

/**
 * One expired-tenant full-data export request (NIX-325, GDPR window).
 * State machine: PENDING -> COMPLETED | FAILED; COMPLETED -> EXPIRED_CLEANED
 * when the delivery window closes (package file deleted, rows kept).
 */
public class DataExportJob {

    public enum Status { PENDING, COMPLETED, FAILED, EXPIRED_CLEANED }

    private Long id;
    private Long tenantId;
    private Long farmId;
    private Status status;
    private Instant terminatedAt;
    private Instant windowEndsAt;
    private Long requestedBy;
    private Instant requestedAt;
    private Instant completedAt;
    private Instant downloadedAt;
    private String filePath;
    private Long fileSizeBytes;
    private Map<String, Object> rowCounts;
    private String error;
    private Instant createdAt;
    private Instant updatedAt;

    public static DataExportJob request(Long tenantId, Long farmId, Instant terminatedAt,
                                        Instant windowEndsAt, Long requestedBy) {
        DataExportJob job = new DataExportJob();
        job.tenantId = tenantId;
        job.farmId = farmId;
        job.status = Status.PENDING;
        job.terminatedAt = terminatedAt;
        job.windowEndsAt = windowEndsAt;
        job.requestedBy = requestedBy;
        job.requestedAt = Instant.now();
        return job;
    }

    public void markCompleted(String filePath, Long fileSizeBytes, Map<String, Object> rowCounts) {
        this.status = Status.COMPLETED;
        this.completedAt = Instant.now();
        this.filePath = filePath;
        this.fileSizeBytes = fileSizeBytes;
        this.rowCounts = rowCounts;
        this.error = null;
    }

    public void markFailed(String error) {
        this.status = Status.FAILED;
        this.completedAt = Instant.now();
        this.error = error;
    }

    public void markDownloaded() {
        if (this.downloadedAt == null) {
            this.downloadedAt = Instant.now();
        }
    }

    public void markCleaned() {
        this.status = Status.EXPIRED_CLEANED;
        this.filePath = null;
        this.fileSizeBytes = null;
    }

    public boolean isWindowOpen(Instant now) {
        return now.isBefore(windowEndsAt);
    }

    public Long getId() { return id; } public void setId(Long v) { this.id = v; }
    public Long getTenantId() { return tenantId; }
    public Long getFarmId() { return farmId; }
    public Status getStatus() { return status; } public void setStatus(Status v) { this.status = v; }
    public Instant getTerminatedAt() { return terminatedAt; }
    public Instant getWindowEndsAt() { return windowEndsAt; }
    public Long getRequestedBy() { return requestedBy; }
    public Instant getRequestedAt() { return requestedAt; }
    public Instant getCompletedAt() { return completedAt; }
    public Instant getDownloadedAt() { return downloadedAt; }
    public String getFilePath() { return filePath; }
    public Long getFileSizeBytes() { return fileSizeBytes; }
    public Map<String, Object> getRowCounts() { return rowCounts; }
    public String getError() { return error; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }

    // Setters below are for the persistence mapper only — state changes go
    // through the domain methods above.
    public void setTenantId(Long v) { this.tenantId = v; }
    public void setFarmId(Long v) { this.farmId = v; }
    public void setTerminatedAt(Instant v) { this.terminatedAt = v; }
    public void setWindowEndsAt(Instant v) { this.windowEndsAt = v; }
    public void setRequestedBy(Long v) { this.requestedBy = v; }
    public void setRequestedAt(Instant v) { this.requestedAt = v; }
    public void setCompletedAt(Instant v) { this.completedAt = v; }
    public void setDownloadedAt(Instant v) { this.downloadedAt = v; }
    public void setFilePath(String v) { this.filePath = v; }
    public void setFileSizeBytes(Long v) { this.fileSizeBytes = v; }
    public void setRowCounts(Map<String, Object> v) { this.rowCounts = v; }
    public void setError(String v) { this.error = v; }
    public void setCreatedAt(Instant v) { this.createdAt = v; }
    public void setUpdatedAt(Instant v) { this.updatedAt = v; }
}
