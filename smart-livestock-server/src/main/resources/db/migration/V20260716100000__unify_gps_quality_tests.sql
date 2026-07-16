-- ============================================================
-- NIX-20: Unify GPS quality test sessions + create dynamic test routes
--
-- This migration:
--   1. Creates dynamic_test_routes (reusable route definitions)
--   2. Creates dynamic_test_route_points (ordered RTK point sequences)
--   3. Creates gps_quality_tests (unified table for STATIC + DYNAMIC tests)
--   4. Migrates all existing rtk_calibration_sessions data into gps_quality_tests
--      as test_type='STATIC' sessions.
--   5. Preserves rtk_calibration_sessions table (NOT dropped) for rollback safety.
--
-- Design (see docs/superpowers/specs/2026-07-16-nix20-gps-dynamic-quality-spec.md §5):
--   - test_type='STATIC'  → rtk_point_id NOT NULL, route_id NULL
--   - test_type='DYNAMIC' → route_id NOT NULL, rtk_point_id NULL
--   - CHECK constraint enforces this mutual exclusivity
--   - Partial unique index preserves "one IN_PROGRESS per device" rule
-- ============================================================

-- ----------------------------------------------------------
-- 1. dynamic_test_routes — reusable test route definitions
-- ----------------------------------------------------------
CREATE TABLE dynamic_test_routes (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------
-- 2. dynamic_test_route_points — ordered RTK point sequences
-- ----------------------------------------------------------
CREATE TABLE dynamic_test_route_points (
    id BIGSERIAL PRIMARY KEY,
    route_id BIGINT NOT NULL REFERENCES dynamic_test_routes(id) ON DELETE CASCADE,
    rtk_point_id BIGINT NOT NULL REFERENCES rtk_reference_points(id),
    sequence_no INTEGER NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (route_id, sequence_no)
);

CREATE INDEX idx_dtrp_route ON dynamic_test_route_points(route_id, sequence_no);

-- ----------------------------------------------------------
-- 3. gps_quality_tests — unified session table (STATIC + DYNAMIC)
-- ----------------------------------------------------------
CREATE TABLE gps_quality_tests (
    id BIGSERIAL PRIMARY KEY,
    device_id BIGINT NOT NULL REFERENCES devices(id),
    test_type VARCHAR(10) NOT NULL,                          -- STATIC / DYNAMIC
    rtk_point_id BIGINT REFERENCES rtk_reference_points(id), -- STATIC: NOT NULL (via CHECK)
    route_id BIGINT REFERENCES dynamic_test_routes(id),      -- DYNAMIC: NOT NULL (via CHECK)
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ,                                    -- null = in progress
    status VARCHAR(20) NOT NULL DEFAULT 'IN_PROGRESS',      -- IN_PROGRESS / COMPLETED / CANCELED
    note TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    -- mutual exclusivity: STATIC needs rtk_point_id, DYNAMIC needs route_id
    CONSTRAINT chk_test_type_truth CHECK (
        (test_type = 'STATIC'  AND rtk_point_id IS NOT NULL AND route_id IS NULL) OR
        (test_type = 'DYNAMIC' AND route_id IS NOT NULL AND rtk_point_id IS NULL)
    )
);

CREATE INDEX idx_gqt_device ON gps_quality_tests(device_id);
CREATE INDEX idx_gqt_status ON gps_quality_tests(status);
CREATE INDEX idx_gqt_type ON gps_quality_tests(test_type);
CREATE INDEX idx_gqt_point ON gps_quality_tests(rtk_point_id);
CREATE INDEX idx_gqt_route ON gps_quality_tests(route_id);

-- S1: a device can have at most 1 IN_PROGRESS test (DB-level enforcement)
-- Preserves the same constraint from rtk_calibration_sessions
CREATE UNIQUE INDEX uq_gqt_device_active
    ON gps_quality_tests(device_id) WHERE status = 'IN_PROGRESS';

-- ----------------------------------------------------------
-- 4. Data migration: rtk_calibration_sessions → gps_quality_tests
-- ----------------------------------------------------------
INSERT INTO gps_quality_tests (
    id, device_id, test_type, rtk_point_id, route_id,
    started_at, ended_at, status, note, created_at, updated_at
)
SELECT
    id, device_id, 'STATIC', rtk_point_id, NULL,
    started_at, ended_at, status, NULL, created_at, updated_at
FROM rtk_calibration_sessions;

-- Sync the sequence so new rows continue from the max id
SELECT setval('gps_quality_tests_id_seq',
    (SELECT COALESCE(MAX(id), 1) FROM gps_quality_tests));

-- NOTE: rtk_calibration_sessions table is intentionally NOT dropped.
-- Code layer will switch to gps_quality_tests; old table kept for rollback.
