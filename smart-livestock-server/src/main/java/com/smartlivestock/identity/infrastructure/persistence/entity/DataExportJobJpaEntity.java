package com.smartlivestock.identity.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;
import java.util.Map;

@Entity
@Table(name = "data_export_jobs")
@Getter
@Setter
public class DataExportJobJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long tenantId;

    @Column(nullable = false)
    private Long farmId;

    @Column(nullable = false, length = 20)
    private String status;

    @Column(name = "terminated_at", nullable = false)
    private Instant terminatedAt;

    @Column(name = "window_ends_at", nullable = false)
    private Instant windowEndsAt;

    @Column(name = "requested_by")
    private Long requestedBy;

    @Column(name = "requested_at", nullable = false)
    private Instant requestedAt;

    @Column(name = "completed_at")
    private Instant completedAt;

    @Column(name = "downloaded_at")
    private Instant downloadedAt;

    @Column(name = "file_path", length = 512)
    private String filePath;

    @Column(name = "file_size_bytes")
    private Long fileSizeBytes;

    @Column(name = "row_counts")
    @Convert(converter = DataExportRowCountsConverter.class)
    private Map<String, Object> rowCounts;

    @Column(length = 1024)
    private String error;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    void onCreate() {
        Instant now = Instant.now();
        if (createdAt == null) createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = Instant.now();
    }
}
