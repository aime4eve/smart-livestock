-- ============================================================
-- Phase 3: Device health management + agentic-middle-platform integration
--
-- 1. devices table: add platform_device_id + operational telemetry fields
-- 2. device_telemetry_logs: new device-centric operational timeseries (monthly partition)
-- 3. alerts table: add device_id column + extend type constraint
-- ============================================================

-- ----------------------------------------------------------
-- 1. devices — extend with platform linkage + ops metrics
-- ----------------------------------------------------------
ALTER TABLE devices
    ADD COLUMN IF NOT EXISTS platform_device_id BIGINT,
    ADD COLUMN IF NOT EXISTS rssi INTEGER,
    ADD COLUMN IF NOT EXISTS snr NUMERIC(4,1),
    ADD COLUMN IF NOT EXISTS last_gateway VARCHAR(128),
    ADD COLUMN IF NOT EXISTS anti_disassembly_status INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS software_version VARCHAR(50),
    ADD COLUMN IF NOT EXISTS hardware_version VARCHAR(50),
    ADD COLUMN IF NOT EXISTS work_mode VARCHAR(20),
    ADD COLUMN IF NOT EXISTS last_telemetry_synced_at TIMESTAMP;

CREATE UNIQUE INDEX IF NOT EXISTS idx_devices_platform_device_id
    ON devices (platform_device_id) WHERE platform_device_id IS NOT NULL;

-- ----------------------------------------------------------
-- 2. device_telemetry_logs — device operational timeseries (monthly partition)
--    Data source: agentic-middle-platform report-record + datagen
--    Sampling interval: ~30min
-- ----------------------------------------------------------
CREATE TABLE device_telemetry_logs (
    id BIGSERIAL,
    device_id BIGINT NOT NULL REFERENCES devices(id),
    tenant_id BIGINT NOT NULL,
    battery_level INTEGER,
    rssi INTEGER,
    snr NUMERIC(4,1),
    gateway_id VARCHAR(128),
    anti_disassembly_status INTEGER,
    step_number INTEGER,
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    accel_x_raw INTEGER,
    accel_y_raw INTEGER,
    accel_z_raw INTEGER,
    accel_x_g NUMERIC(6,3),
    accel_y_g NUMERIC(6,3),
    accel_z_g NUMERIC(6,3),
    accel_magnitude_g NUMERIC(6,3),
    motion_intensity NUMERIC(4,2),
    activity_class VARCHAR(10),
    roll_degrees NUMERIC(5,2),
    pitch_degrees NUMERIC(5,2),
    report_time TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id, report_time)
) PARTITION BY RANGE (report_time);

CREATE TABLE device_telemetry_logs_2026_07 PARTITION OF device_telemetry_logs
    FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');
CREATE TABLE device_telemetry_logs_2026_08 PARTITION OF device_telemetry_logs
    FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');
CREATE TABLE device_telemetry_logs_2026_09 PARTITION OF device_telemetry_logs
    FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');
CREATE TABLE device_telemetry_logs_2026_10 PARTITION OF device_telemetry_logs
    FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');
CREATE TABLE device_telemetry_logs_default PARTITION OF device_telemetry_logs DEFAULT;

CREATE INDEX idx_dtl_device_time ON device_telemetry_logs(device_id, report_time DESC);
CREATE INDEX idx_dtl_tenant_time ON device_telemetry_logs(tenant_id, report_time DESC);

-- ----------------------------------------------------------
-- 3. alerts — add device_id for device-originated alerts
-- ----------------------------------------------------------
ALTER TABLE alerts
    ADD COLUMN IF NOT EXISTS device_id BIGINT REFERENCES devices(id);

CREATE INDEX IF NOT EXISTS idx_alerts_device_id ON alerts(device_id);

-- Extend type constraint to include device alert types
ALTER TABLE alerts DROP CONSTRAINT IF EXISTS chk_alerts_type;
ALTER TABLE alerts ADD CONSTRAINT chk_alerts_type CHECK (type IN (
    'FENCE_BREACH','FENCE_APPROACH','ZONE_APPROACH','TEMPERATURE_ABNORMAL',
    'DIGESTIVE_ABNORMAL','ESTRUS','EPIDEMIC','AI_ANOMALY',
    'DEVICE_TAMPER','DEVICE_LOW_BATTERY'));
