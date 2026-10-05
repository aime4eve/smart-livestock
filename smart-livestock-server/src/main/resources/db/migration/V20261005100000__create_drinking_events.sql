-- Migration: create_drinking_events
-- Date: 2026-10-05
-- Context: Health

-- NIX-256 Task 3: rumen-temperature drinking events with the marking loop
-- data plane (spec §15.1). Ordinary table, not partitioned: ~10 rows per
-- animal per day (tens of thousands daily at herd scale) — verified outside
-- the PartitionMaintenanceService table list, no conflict.
--
-- Deviations from the research doc §6.1 baseline (spec §15 additions):
--   * label / confidence columns for the marking loop;
--   * note for manual back-filled events (POST /manual carries an optional
--     note, same convention as physiology_events.note);
--   * temp_drop / min_temp are NULLable because MANUAL rows carry no
--     temperature observation — NULL is honest, a fake 0.00 is not.

CREATE TABLE drinking_events (
    id              BIGSERIAL PRIMARY KEY,
    device_id       BIGINT NOT NULL REFERENCES devices(id),
    livestock_id    BIGINT REFERENCES livestock(id),
    event_start_at  TIMESTAMP NOT NULL,      -- descent onset ≈ drinking start (app writes UTC Instant, #17)
    event_end_at    TIMESTAMP NOT NULL,      -- trough ≈ drinking end
    temp_drop       NUMERIC(10,2),           -- start − trough; NULL on MANUAL rows (#13: DECIMAL(10,2) minimum)
    min_temp        NUMERIC(10,2),           -- trough temperature; NULL on MANUAL rows
    source          VARCHAR(20) NOT NULL,    -- passthrough of the temperature point source + MANUAL / ALGORITHM_CANDIDATE (dynamic, no CHECK by design)
    label           VARCHAR(12) NOT NULL DEFAULT 'UNLABELED',
    confidence      NUMERIC(4,3) NOT NULL DEFAULT 1.0,
    algorithm_version VARCHAR(10) NOT NULL,
    note            VARCHAR(500),
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (device_id, event_start_at, algorithm_version),
    CONSTRAINT drinking_events_label_check
        CHECK (label IN ('UNLABELED', 'CONFIRMED', 'REJECTED'))
);
CREATE INDEX idx_drinking_events_livestock_time ON drinking_events (livestock_id, event_start_at DESC);
