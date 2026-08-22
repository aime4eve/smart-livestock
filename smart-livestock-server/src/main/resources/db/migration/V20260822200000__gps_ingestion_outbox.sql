-- Durable GPS ingestion outbox. Telemetry ingest enqueues one small task in its
-- own transaction; a background worker writes gps_logs independently.
CREATE TABLE gps_ingestion_tasks (
    id BIGSERIAL PRIMARY KEY,
    device_id BIGINT NOT NULL REFERENCES devices(id),
    latitude DECIMAL(10,7) NOT NULL,
    longitude DECIMAL(10,7) NOT NULL,
    accuracy DECIMAL(6,2),
    recorded_at TIMESTAMP NOT NULL,
    source VARCHAR(20) NOT NULL,
    status VARCHAR(10) NOT NULL DEFAULT 'PENDING',
    attempts INTEGER NOT NULL DEFAULT 0,
    next_attempt_at TIMESTAMP NOT NULL DEFAULT NOW(),
    last_error TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_gps_ingestion_tasks_device_recorded_at UNIQUE (device_id, recorded_at),
    CONSTRAINT chk_gps_ingestion_tasks_status CHECK (status IN ('PENDING', 'FAILED')),
    CONSTRAINT chk_gps_ingestion_tasks_attempts CHECK (attempts >= 0)
);

CREATE INDEX idx_gps_ingestion_tasks_ready
    ON gps_ingestion_tasks(status, next_attempt_at, recorded_at);
