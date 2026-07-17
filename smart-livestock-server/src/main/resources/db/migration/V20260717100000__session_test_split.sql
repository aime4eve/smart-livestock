-- ============================================================
-- NIX-20 Session-Test model split
--
-- Splits the flat gps_quality_tests table into:
--   1. gps_quality_sessions (device + time window = data window)
--   2. gps_quality_tests (session_id + sub-time-range + truth reference)
--
-- Migration strategy: 1:1 mapping (each existing test row becomes
-- one session + one test). Users can manually merge sessions later.
--
-- See: docs/superpowers/specs/2026-07-17-nix20-session-test-model-redesign.md
-- ============================================================

-- ----------------------------------------------------------
-- 1. Create gps_quality_sessions table
-- ----------------------------------------------------------
CREATE TABLE gps_quality_sessions (
    id BIGSERIAL PRIMARY KEY,
    device_id BIGINT NOT NULL REFERENCES devices(id),
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ,
    status VARCHAR(20) NOT NULL DEFAULT 'IN_PROGRESS',
    note TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_gqs_device ON gps_quality_sessions(device_id);
CREATE INDEX idx_gqs_status ON gps_quality_sessions(status);

-- S1: a device can have at most 1 IN_PROGRESS session
CREATE UNIQUE INDEX uq_gqs_device_active
    ON gps_quality_sessions(device_id) WHERE status = 'IN_PROGRESS';

-- ----------------------------------------------------------
-- 2. Populate sessions from existing tests (1:1 mapping)
--    Use test.id as session.id for easy backfill
-- ----------------------------------------------------------
INSERT INTO gps_quality_sessions (
    id, device_id, started_at, ended_at, status, note, created_at, updated_at
)
SELECT
    id, device_id, started_at, ended_at, status, NULL, created_at, updated_at
FROM gps_quality_tests;

-- Sync the sequence so new rows continue from the max id
SELECT setval('gps_quality_sessions_id_seq',
    (SELECT COALESCE(MAX(id), 1) FROM gps_quality_sessions));

-- ----------------------------------------------------------
-- 3. Add new columns to gps_quality_tests
-- ----------------------------------------------------------
ALTER TABLE gps_quality_tests ADD COLUMN session_id BIGINT;
ALTER TABLE gps_quality_tests ADD COLUMN test_started_at TIMESTAMPTZ;
ALTER TABLE gps_quality_tests ADD COLUMN test_ended_at TIMESTAMPTZ;

-- ----------------------------------------------------------
-- 4. Backfill: each test maps to its own session (1:1)
-- ----------------------------------------------------------
UPDATE gps_quality_tests SET
    session_id = id,
    test_started_at = started_at,
    test_ended_at = ended_at;

-- ----------------------------------------------------------
-- 5. Set NOT NULL constraints
-- ----------------------------------------------------------
ALTER TABLE gps_quality_tests ALTER COLUMN session_id SET NOT NULL;
ALTER TABLE gps_quality_tests ALTER COLUMN test_started_at SET NOT NULL;

-- ----------------------------------------------------------
-- 6. Add FK with CASCADE (must be added after backfill)
-- ----------------------------------------------------------
ALTER TABLE gps_quality_tests
    ADD CONSTRAINT fk_gqt_session
    FOREIGN KEY (session_id) REFERENCES gps_quality_sessions(id) ON DELETE CASCADE;

-- ----------------------------------------------------------
-- 7. Drop columns that moved to session
-- ----------------------------------------------------------
-- Drop the old unique index first (references device_id + status on tests table)
DROP INDEX IF EXISTS uq_gqt_device_active;

ALTER TABLE gps_quality_tests DROP COLUMN device_id;
ALTER TABLE gps_quality_tests DROP COLUMN started_at;
ALTER TABLE gps_quality_tests DROP COLUMN ended_at;
ALTER TABLE gps_quality_tests DROP COLUMN status;

-- ----------------------------------------------------------
-- 8. Update indexes on tests table
-- ----------------------------------------------------------
CREATE INDEX idx_gqt_session ON gps_quality_tests(session_id);
-- Keep existing: idx_gqt_type, idx_gqt_point, idx_gqt_route
-- chk_test_type_truth CHECK constraint is unaffected (only tests test_type/rtk_point_id/route_id)

-- NOTE: rtk_calibration_sessions (original table) and gps_quality_tests
-- are both preserved. Only gps_quality_tests structure changed.
