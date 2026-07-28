-- ============================================================
-- NIX-68: GPS track-line inspection (standard track / LINE test)
--
-- Design (docs/superpowers/specs/2026-07-28-nix68-track-line-inspection-spec.md §6):
--   - gps_quality_tests: new nullable track_line_id (FK ON DELETE SET NULL),
--     chk_test_type_truth evolved to allow test_type='LINE'
--   - New tables: standard_track_lines (+points) for imported line-truth
--     candidates; gps_quality_line_points / line_results / line_deviations
--     as per-test snapshots (D4: point list AND results are snapshotted
--     because DataRetentionService purges gps_logs)
--   - No seed data: standard tracks come from user file imports (NIX-22 §5.4)
-- ============================================================

-- ----------------------------------------------------------
-- 1. Standard track line candidates (imported RTK line truth)
-- ----------------------------------------------------------
CREATE TABLE standard_track_lines (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    name VARCHAR(200) NOT NULL,
    status VARCHAR(10) NOT NULL DEFAULT 'CANDIDATE',   -- CANDIDATE / SELECTED
    point_count INTEGER NOT NULL,                      -- after consecutive-duplicate removal (D6)
    length_m NUMERIC(10,1) NOT NULL,                   -- haversine sum over deduped points
    start_lng NUMERIC(10,7) NOT NULL,                  -- first deduped point (display only)
    start_lat NUMERIC(10,7) NOT NULL,
    source_file VARCHAR(255),                          -- origin file name (traceability only)
    created_at TIMESTAMP NOT NULL DEFAULT NOW()        -- import time
    -- No UNIQUE(name/file): re-importing the same file adds a new candidate (D3)
);
CREATE INDEX idx_stl_tenant ON standard_track_lines(tenant_id, status);

-- ----------------------------------------------------------
-- 2. Standard track line points (no timestamps: metadata not trusted, D6)
-- ----------------------------------------------------------
CREATE TABLE standard_track_line_points (
    id BIGSERIAL PRIMARY KEY,
    line_id BIGINT NOT NULL REFERENCES standard_track_lines(id) ON DELETE CASCADE,
    sequence_no INTEGER NOT NULL,                      -- deduped order, from 1
    longitude NUMERIC(10,7) NOT NULL,
    latitude NUMERIC(10,7) NOT NULL,
    UNIQUE (line_id, sequence_no)
);

-- ----------------------------------------------------------
-- 3. gps_quality_tests: track_line_id + CHECK evolution (NIX-22 style)
-- ----------------------------------------------------------
ALTER TABLE gps_quality_tests ADD COLUMN track_line_id BIGINT
    REFERENCES standard_track_lines(id) ON DELETE SET NULL;

ALTER TABLE gps_quality_tests DROP CONSTRAINT chk_test_type_truth;
ALTER TABLE gps_quality_tests ADD CONSTRAINT chk_test_type_truth CHECK (
    (test_type = 'STATIC'     AND rtk_point_id IS NOT NULL AND route_id IS NULL  AND track_line_id IS NULL) OR
    (test_type = 'DYNAMIC'    AND route_id IS NOT NULL AND rtk_point_id IS NULL  AND track_line_id IS NULL) OR
    (test_type = 'TRAJECTORY' AND rtk_point_id IS NULL AND route_id IS NULL      AND track_line_id IS NULL) OR
    (test_type = 'LINE'       AND track_line_id IS NOT NULL AND rtk_point_id IS NULL AND route_id IS NULL)
);

-- Supports /checks/summary (latest test per device + type)
CREATE INDEX idx_gqt_device_type_time ON gps_quality_tests(device_code, test_type, created_at DESC);
-- Supports cascading SET NULL on candidate deletion and per-line test lookup
CREATE INDEX idx_gqt_track_line ON gps_quality_tests(track_line_id);

-- ----------------------------------------------------------
-- 4. LINE test point-list snapshot (D4)
-- ----------------------------------------------------------
CREATE TABLE gps_quality_line_points (
    id BIGSERIAL PRIMARY KEY,
    test_id BIGINT NOT NULL REFERENCES gps_quality_tests(id) ON DELETE CASCADE,
    sequence_no INTEGER NOT NULL,
    longitude NUMERIC(10,7) NOT NULL,
    latitude NUMERIC(10,7) NOT NULL,
    UNIQUE (test_id, sequence_no)
);

-- ----------------------------------------------------------
-- 5. LINE test result snapshot (D4)
-- ----------------------------------------------------------
CREATE TABLE gps_quality_line_results (
    test_id BIGINT PRIMARY KEY REFERENCES gps_quality_tests(id) ON DELETE CASCADE,
    sample_count INTEGER NOT NULL,
    mean_deviation_m NUMERIC(10,2) NOT NULL,
    p50_m NUMERIC(10,2) NOT NULL,
    p95_m NUMERIC(10,2) NOT NULL,
    max_deviation_m NUMERIC(10,2) NOT NULL,
    within15m_pct NUMERIC(5,1) NOT NULL,
    within25m_pct NUMERIC(5,1) NOT NULL,
    within40m_pct NUMERIC(5,1) NOT NULL,
    grade VARCHAR(12) NOT NULL,                        -- EXCELLENT/USABLE/MARGINAL/UNAVAILABLE
    first_recorded_at TIMESTAMPTZ,
    last_recorded_at TIMESTAMPTZ,
    computed_at TIMESTAMP NOT NULL DEFAULT NOW()       -- system time uses TIMESTAMP (NIX-22 convention)
);

-- ----------------------------------------------------------
-- 6. LINE test per-point deviation snapshot (D4)
-- ----------------------------------------------------------
CREATE TABLE gps_quality_line_deviations (
    id BIGSERIAL PRIMARY KEY,
    test_id BIGINT NOT NULL REFERENCES gps_quality_tests(id) ON DELETE CASCADE,
    sequence_no INTEGER NOT NULL,                      -- ascending by recorded_at
    recorded_at TIMESTAMPTZ NOT NULL,
    longitude NUMERIC(10,7) NOT NULL,
    latitude NUMERIC(10,7) NOT NULL,
    deviation_m NUMERIC(10,2) NOT NULL,
    segment_no INTEGER NOT NULL,                       -- nearest standard-track segment index
    UNIQUE (test_id, sequence_no)
);
CREATE INDEX idx_gld_test ON gps_quality_line_deviations(test_id, sequence_no);
