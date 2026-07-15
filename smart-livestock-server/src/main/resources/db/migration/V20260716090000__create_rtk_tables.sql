-- ============================================================
-- NIX-15: GPS Quality Check — RTK reference points + calibration sessions
--
-- Two decoupled tables:
--   rtk_reference_points    — RTK ground-truth coordinates (no device link)
--   rtk_calibration_sessions — links a device to an RTK point for a static test window
--
-- Audit columns use TIMESTAMP (project convention, 22:0 across all migrations).
-- Business time columns (started_at/ended_at) use TIMESTAMPTZ because they
-- participate directly in `gps_logs.recorded_at BETWEEN started_at AND ended_at`
-- (lesson #17: keep the same time basis as the blade telemetry data).
-- ============================================================

-- ----------------------------------------------------------
-- 1. rtk_reference_points — RTK ground-truth coordinates
-- ----------------------------------------------------------
CREATE TABLE rtk_reference_points (
    id BIGSERIAL PRIMARY KEY,
    location_name VARCHAR(100) NOT NULL,   -- grouping key, e.g. "一期楼顶"
    point_label VARCHAR(50) NOT NULL,      -- point id, e.g. "11号点"
    latitude DECIMAL(10,7) NOT NULL,       -- RTK measured latitude (decimal)
    longitude DECIMAL(10,7) NOT NULL,      -- RTK measured longitude (decimal)
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_rtk_ref_location ON rtk_reference_points(location_name);

-- ----------------------------------------------------------
-- 2. rtk_calibration_sessions — static test window (device × RTK point)
-- ----------------------------------------------------------
CREATE TABLE rtk_calibration_sessions (
    id BIGSERIAL PRIMARY KEY,
    rtk_point_id BIGINT NOT NULL REFERENCES rtk_reference_points(id),
    device_id BIGINT NOT NULL REFERENCES devices(id),
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ,                  -- null = in progress
    status VARCHAR(20) NOT NULL DEFAULT 'IN_PROGRESS',  -- IN_PROGRESS / COMPLETED / CANCELED
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- S1: a device can have at most 1 IN_PROGRESS session (DB-level enforcement)
CREATE UNIQUE INDEX uq_rtk_session_device_active
  ON rtk_calibration_sessions(device_id) WHERE status = 'IN_PROGRESS';

-- S1: time-window overlap is validated in the application layer
CREATE INDEX idx_rtk_session_point ON rtk_calibration_sessions(rtk_point_id);
CREATE INDEX idx_rtk_session_device ON rtk_calibration_sessions(device_id);
CREATE INDEX idx_rtk_session_status ON rtk_calibration_sessions(status);
