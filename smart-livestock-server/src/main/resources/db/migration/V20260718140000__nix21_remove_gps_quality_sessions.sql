-- ============================================================
-- NIX-21: GPS Quality Check — Remove session model, simplify test table
--
-- Design (see docs/superpowers/specs/2026-07-18-nix21-batch-import-spec.md):
--   - Eliminates gps_quality_sessions (redundant abstraction, added in V20260717100000)
--   - Eliminates rtk_calibration_sessions (unused since NIX-20)
--   - Moves device_id + status back to gps_quality_tests
--   - Renames test_started_at/test_ended_at back to started_at/ended_at
--   - Adds device_code for direct device EUI reference (non-FK)
--   - Adds batch_import_id for import tracking
--   - Adds error_message for import failure details
--
-- Column migration (gps_quality_tests):
--   BEFORE (after V20260717100000):
--     id, test_type, rtk_point_id, route_id, session_id,
--     test_started_at, test_ended_at, note, created_at, updated_at
--   AFTER:
--     id, test_type, rtk_point_id, route_id,
--     device_code, device_id, batch_import_id, status, error_message,
--     started_at, ended_at, note, created_at, updated_at
-- ============================================================

-- ----------------------------------------------------------
-- 1. Add new columns to gps_quality_tests
-- ----------------------------------------------------------
ALTER TABLE gps_quality_tests ADD COLUMN device_code VARCHAR(100);
ALTER TABLE gps_quality_tests ADD COLUMN device_id BIGINT REFERENCES devices(id);
ALTER TABLE gps_quality_tests ADD COLUMN batch_import_id BIGINT;
ALTER TABLE gps_quality_tests ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'READY';
ALTER TABLE gps_quality_tests ADD COLUMN error_message TEXT;

-- ----------------------------------------------------------
-- 2. Backfill: populate device_id, device_code, status from sessions
--    Existing data has 1:1 test-to-session mapping. The session table
--    holds device_id; join through devices to get device_code (EUI).
-- ----------------------------------------------------------
UPDATE gps_quality_tests gqt
SET
    device_code = d.device_code,
    device_id = gqs.device_id,
    status = 'READY'
FROM gps_quality_sessions gqs
JOIN devices d ON d.id = gqs.device_id
WHERE gqt.session_id = gqs.id;

-- ----------------------------------------------------------
-- 3. Rename columns: test_started_at -> started_at, test_ended_at -> ended_at
--    chk_test_type_truth CHECK constraint is unaffected (only references
--    test_type / rtk_point_id / route_id, not time columns).
-- ----------------------------------------------------------
ALTER TABLE gps_quality_tests RENAME COLUMN test_started_at TO started_at;
ALTER TABLE gps_quality_tests RENAME COLUMN test_ended_at TO ended_at;

-- ----------------------------------------------------------
-- 4. Drop session FK + column
--    idx_gqt_session (on session_id) is auto-dropped with the column.
-- ----------------------------------------------------------
ALTER TABLE gps_quality_tests DROP CONSTRAINT IF EXISTS fk_gqt_session;
ALTER TABLE gps_quality_tests DROP COLUMN session_id;

-- ----------------------------------------------------------
-- 5. Drop obsolete tables
--    gps_quality_sessions: session abstraction no longer needed (NIX-21)
--    rtk_calibration_sessions: replaced by gps_quality_tests in NIX-20,
--       kept for rollback safety until now
-- ----------------------------------------------------------
DROP TABLE IF EXISTS gps_quality_sessions;
DROP TABLE IF EXISTS rtk_calibration_sessions;

-- ----------------------------------------------------------
-- 6. Set NOT NULL constraints after backfill
--    device_code is always required (device EUI from import or FK join)
--    device_id is nullable for unregistered devices
-- ----------------------------------------------------------
ALTER TABLE gps_quality_tests ALTER COLUMN device_code SET NOT NULL;

-- ----------------------------------------------------------
-- 7. Create indexes for new columns
--    idx_gqt_type already existed from V20260716100000 on test_type;
--    idx_gqt_device and idx_gqt_status were auto-dropped when columns
--    device_id and status were removed by V20260717100000.
-- ----------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_gqt_device_id ON gps_quality_tests(device_id);
CREATE INDEX IF NOT EXISTS idx_gqt_status ON gps_quality_tests(status);
CREATE INDEX IF NOT EXISTS idx_gqt_type ON gps_quality_tests(test_type);
