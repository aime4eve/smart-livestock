-- ============================================================
-- NIX-22: RTK trajectory-import dynamic check
--
-- Design (docs/superpowers/specs/2026-07-22-nix22-rtk-trajectory-import-spec.md):
--   - Allow test_type='TRAJECTORY' on gps_quality_tests (rtk_point_id/route_id both NULL)
--   - New table gps_quality_track_points: per-row pairing snapshot
--     (RTK truth vs device coordinate, matched at import time, D2)
--   - No seed data: trajectory data comes from user file imports
-- ============================================================

-- ----------------------------------------------------------
-- 1. Extend the truth-reference CHECK constraint for TRAJECTORY.
--    test_type is VARCHAR(10); 'TRAJECTORY' fits exactly.
-- ----------------------------------------------------------
ALTER TABLE gps_quality_tests DROP CONSTRAINT chk_test_type_truth;
ALTER TABLE gps_quality_tests ADD CONSTRAINT chk_test_type_truth CHECK (
    (test_type = 'STATIC'     AND rtk_point_id IS NOT NULL AND route_id IS NULL) OR
    (test_type = 'DYNAMIC'    AND route_id IS NOT NULL AND rtk_point_id IS NULL) OR
    (test_type = 'TRAJECTORY' AND rtk_point_id IS NULL AND route_id IS NULL)
);

-- ----------------------------------------------------------
-- 2. Trajectory track points (pairing snapshot per imported row)
-- ----------------------------------------------------------
CREATE TABLE gps_quality_track_points (
    id BIGSERIAL PRIMARY KEY,
    test_id BIGINT NOT NULL REFERENCES gps_quality_tests(id) ON DELETE CASCADE,
    sequence_no INTEGER NOT NULL,                    -- row order within the device's track (from 1)
    collected_at TIMESTAMPTZ NOT NULL,               -- collection time parsed on the UTC+8 baseline
    rtk_latitude NUMERIC(10,7) NOT NULL,
    rtk_longitude NUMERIC(10,7) NOT NULL,
    device_latitude NUMERIC(10,7),                   -- snapshot: FILE=file value / GPS_LOG=gps_logs value
    device_longitude NUMERIC(10,7),
    match_source VARCHAR(10) NOT NULL,               -- FILE / GPS_LOG / UNPAIRED
    -- Plain reference, intentionally no FK: DataRetentionService purges old
    -- gps_logs rows and the pairing snapshot (D2) must survive that purge.
    matched_gps_log_id BIGINT,
    time_diff_seconds INTEGER,                       -- GPS_LOG pairing time diff; FILE=0
    tolerance_seconds INTEGER NOT NULL DEFAULT 60,   -- tolerance used at import time
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (test_id, sequence_no),
    CONSTRAINT chk_track_match CHECK (
        (match_source IN ('FILE','GPS_LOG')
            AND device_latitude IS NOT NULL AND device_longitude IS NOT NULL) OR
        (match_source = 'UNPAIRED'
            AND device_latitude IS NULL AND device_longitude IS NULL)
    )
);

CREATE INDEX idx_gtp_test ON gps_quality_track_points(test_id, sequence_no);
