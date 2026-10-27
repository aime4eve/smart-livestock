-- Migration: create_data_export_jobs
-- Date: 2026-10-26
-- Context: Expired-tenant data export right, GDPR window (NIX-325)

-- One row per export request. Files are generated asynchronously
-- (PENDING -> COMPLETED/FAILED) by DataExportGenerationJob; the package file
-- is deleted by DataExportCleanupJob after the delivery window closes
-- (COMPLETED with downloaded_at set, window passed -> EXPIRED_CLEANED).
CREATE TABLE data_export_jobs (
    id              BIGSERIAL PRIMARY KEY,
    tenant_id       BIGINT NOT NULL,
    farm_id         BIGINT NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'PENDING'
                    CHECK (status IN ('PENDING', 'COMPLETED', 'FAILED', 'EXPIRED_CLEANED')),
    terminated_at   TIMESTAMPTZ NOT NULL,          -- subscription termination instant (window anchor)
    window_ends_at  TIMESTAMPTZ NOT NULL,          -- terminated_at + window-days (30d default)
    requested_by    BIGINT,                        -- users.id (NULL for API-Key requests)
    requested_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at    TIMESTAMPTZ,
    downloaded_at   TIMESTAMPTZ,
    file_path       VARCHAR(512),
    file_size_bytes BIGINT,
    row_counts      JSONB,                         -- per-entity row counts {"livestock": 120, ...}
    error           VARCHAR(1024),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_data_export_jobs_tenant ON data_export_jobs(tenant_id);
CREATE INDEX idx_data_export_jobs_status ON data_export_jobs(status);
