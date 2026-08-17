-- Datagen admin console: farm-level controls, persistent device assignments,
-- derived-data source tracking, and farm-scoped audit metadata.

CREATE TABLE datagen_farm_controls (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id),
    farm_id BIGINT NOT NULL REFERENCES farms(id),
    scenario_id BIGINT NOT NULL REFERENCES synthesis_scenarios(id),
    enabled BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_datagen_farm_controls_farm UNIQUE (farm_id)
);

CREATE INDEX idx_datagen_controls_tenant_farm
    ON datagen_farm_controls(tenant_id, farm_id);
CREATE INDEX idx_datagen_controls_scenario
    ON datagen_farm_controls(scenario_id);

CREATE TABLE datagen_device_assignments (
    id BIGSERIAL PRIMARY KEY,
    control_id BIGINT NOT NULL
        REFERENCES datagen_farm_controls(id) ON DELETE CASCADE,
    device_id BIGINT NOT NULL REFERENCES devices(id),
    first_assigned_at TIMESTAMP NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    removed_at TIMESTAMP,
    CONSTRAINT uq_datagen_assignments_control_device UNIQUE (control_id, device_id)
);

CREATE INDEX idx_datagen_assignments_control
    ON datagen_device_assignments(control_id);
CREATE UNIQUE INDEX uq_datagen_active_assignments_device
    ON datagen_device_assignments(device_id)
    WHERE removed_at IS NULL;

ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS farm_id BIGINT;
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS operator_role VARCHAR(20);
CREATE INDEX IF NOT EXISTS idx_audit_logs_farm_occurred
    ON audit_logs(farm_id, occurred_at DESC);

ALTER TABLE temperature_logs
    ADD COLUMN IF NOT EXISTS source VARCHAR(20) NOT NULL DEFAULT 'UNKNOWN';
ALTER TABLE temperature_logs DROP CONSTRAINT IF EXISTS chk_temperature_logs_source;
ALTER TABLE temperature_logs ADD CONSTRAINT chk_temperature_logs_source
    CHECK (source IN ('AGENTIC_PLATFORM','DATAGEN','HTTP','MANUAL_IMPORT','UNKNOWN'));

ALTER TABLE rumen_motility_logs
    ADD COLUMN IF NOT EXISTS source VARCHAR(20) NOT NULL DEFAULT 'UNKNOWN';
ALTER TABLE rumen_motility_logs DROP CONSTRAINT IF EXISTS chk_rumen_motility_logs_source;
ALTER TABLE rumen_motility_logs ADD CONSTRAINT chk_rumen_motility_logs_source
    CHECK (source IN ('AGENTIC_PLATFORM','DATAGEN','HTTP','MANUAL_IMPORT','UNKNOWN'));

ALTER TABLE activity_logs
    ADD COLUMN IF NOT EXISTS source VARCHAR(20) NOT NULL DEFAULT 'UNKNOWN';
ALTER TABLE activity_logs DROP CONSTRAINT IF EXISTS chk_activity_logs_source;
ALTER TABLE activity_logs ADD CONSTRAINT chk_activity_logs_source
    CHECK (source IN ('AGENTIC_PLATFORM','DATAGEN','HTTP','MANUAL_IMPORT','UNKNOWN'));

ALTER TABLE estrus_scores
    ADD COLUMN IF NOT EXISTS source VARCHAR(20) NOT NULL DEFAULT 'UNKNOWN';
ALTER TABLE estrus_scores DROP CONSTRAINT IF EXISTS chk_estrus_scores_source;
ALTER TABLE estrus_scores ADD CONSTRAINT chk_estrus_scores_source
    CHECK (source IN ('AGENTIC_PLATFORM','DATAGEN','HTTP','MANUAL_IMPORT','UNKNOWN'));

ALTER TABLE anomaly_scores
    ADD COLUMN IF NOT EXISTS source VARCHAR(20) NOT NULL DEFAULT 'UNKNOWN';
ALTER TABLE anomaly_scores DROP CONSTRAINT IF EXISTS chk_anomaly_scores_source;
ALTER TABLE anomaly_scores ADD CONSTRAINT chk_anomaly_scores_source
    CHECK (source IN ('AGENTIC_PLATFORM','DATAGEN','HTTP','MANUAL_IMPORT','UNKNOWN'));

ALTER TABLE alerts DROP CONSTRAINT IF EXISTS chk_alerts_source;
ALTER TABLE alerts ADD CONSTRAINT chk_alerts_source
    CHECK (source IN ('RULE','AI','DATAGEN'));

-- Ensure the console always has a runnable baseline scenario. Farm controls
-- remain stopped, so this does not silently resume data generation.
INSERT INTO synthesis_scenarios
    (name, status, type, penetration_rate, window_start, window_end, interval_seconds)
SELECT '默认持续合成', 'RUNNING', 'NORMAL', 1.0, NOW(), NOW() + INTERVAL '365 days', 30
WHERE NOT EXISTS (
    SELECT 1 FROM synthesis_scenarios WHERE name = '默认持续合成'
);

UPDATE synthesis_scenarios
SET status = 'RUNNING',
    window_end = CASE
        WHEN window_end <= NOW() THEN NOW() + INTERVAL '365 days'
        ELSE window_end
    END
WHERE name = '默认持续合成';

INSERT INTO datagen_farm_controls (tenant_id, farm_id, scenario_id, enabled)
SELECT f.tenant_id, f.id, s.id, FALSE
FROM farms f
CROSS JOIN synthesis_scenarios s
WHERE f.deleted_at IS NULL
  AND s.name = '默认持续合成'
ON CONFLICT (farm_id) DO NOTHING;

-- Reconstruct device/farm ownership from installation history. Active rows are
-- reserved for devices that are currently valid console candidates; removed
-- installations remain queryable for safe historical data cleanup.
INSERT INTO datagen_device_assignments
    (control_id, device_id, first_assigned_at, created_at, removed_at)
SELECT c.id,
       i.device_id,
       MIN(i.installed_at),
       NOW(),
       CASE WHEN EXISTS (
           SELECT 1
           FROM installations current_i
           JOIN livestock current_l ON current_l.id = current_i.livestock_id
           JOIN devices current_d ON current_d.id = current_i.device_id
           WHERE current_i.device_id = i.device_id
             AND current_i.removed_at IS NULL
             AND current_l.farm_id = c.farm_id
             AND current_d.deleted_at IS NULL
             AND current_d.status = 'ACTIVE'
             AND current_d.device_type IN ('TRACKER', 'CAPSULE')
       ) THEN NULL ELSE COALESCE(MAX(i.removed_at), NOW()) END
FROM installations i
JOIN livestock l ON l.id = i.livestock_id
JOIN farms f ON f.id = l.farm_id
JOIN datagen_farm_controls c ON c.farm_id = f.id
JOIN devices d ON d.id = i.device_id
WHERE f.deleted_at IS NULL
GROUP BY c.id, c.farm_id, i.device_id
ON CONFLICT (control_id, device_id) DO NOTHING;
