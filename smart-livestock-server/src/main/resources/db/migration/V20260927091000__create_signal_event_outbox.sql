-- Transactional outbox for Signal Sync (Phase 2). Payload is a change hint,
-- never the authoritative state consumed by clients.
CREATE TABLE signal_event_outbox (
    id BIGSERIAL PRIMARY KEY,
    farm_id BIGINT NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    event_type VARCHAR(64) NOT NULL,
    entity_type VARCHAR(32) NOT NULL,
    entity_id BIGINT NOT NULL,
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    status VARCHAR(16) NOT NULL DEFAULT 'PENDING',
    retry_count INTEGER NOT NULL DEFAULT 0,
    available_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    dispatched_at TIMESTAMPTZ,
    last_error TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_signal_event_outbox_status CHECK (
        status IN ('PENDING', 'DISPATCHED', 'FAILED')
    ),
    CONSTRAINT chk_signal_event_outbox_retry_count CHECK (retry_count >= 0)
);

CREATE INDEX idx_signal_event_outbox_pending
    ON signal_event_outbox (status, available_at, id);
CREATE INDEX idx_signal_event_outbox_farm
    ON signal_event_outbox (farm_id, created_at, id);

-- Repeated high-frequency fixes only retain the latest pending notification.
CREATE UNIQUE INDEX uq_signal_event_outbox_pending_entity
    ON signal_event_outbox (farm_id, event_type, entity_type, entity_id)
    WHERE status = 'PENDING';
