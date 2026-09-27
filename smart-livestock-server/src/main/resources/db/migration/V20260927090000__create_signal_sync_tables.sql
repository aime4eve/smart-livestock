-- Livestock signal synchronization (Phase 1a)

CREATE TABLE farm_signal_revisions (
    farm_id BIGINT PRIMARY KEY REFERENCES farms(id) ON DELETE CASCADE,
    status_revision BIGINT NOT NULL DEFAULT 0,
    position_revision BIGINT NOT NULL DEFAULT 0,
    fence_geometry_revision BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO farm_signal_revisions (farm_id)
SELECT id FROM farms
ON CONFLICT (farm_id) DO NOTHING;

CREATE TABLE livestock_location_snapshots (
    livestock_id BIGINT PRIMARY KEY REFERENCES livestock(id) ON DELETE CASCADE,
    farm_id BIGINT NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    device_id BIGINT NOT NULL REFERENCES devices(id),
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    accuracy DOUBLE PRECISION,
    recorded_at TIMESTAMPTZ NOT NULL,
    source VARCHAR(32) NOT NULL,
    position_revision BIGINT NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_location_snapshot_source CHECK (
        source IN (
            'AGENTIC_PLATFORM', 'THINGSBOARD', 'DATAGEN',
            'HTTP', 'MANUAL_IMPORT'
        )
    )
);

CREATE INDEX idx_location_snapshot_farm_revision
    ON livestock_location_snapshots (farm_id, position_revision);
CREATE INDEX idx_location_snapshot_farm_livestock
    ON livestock_location_snapshots (farm_id, livestock_id);

WITH active_installations AS (
    SELECT
        i.device_id,
        i.livestock_id,
        i.installed_at,
        l.farm_id
    FROM installations i
    JOIN livestock l ON l.id = i.livestock_id
    WHERE i.removed_at IS NULL
      AND l.deleted_at IS NULL
),
latest_valid_positions AS (
    SELECT DISTINCT ON (a.livestock_id)
        a.livestock_id,
        a.farm_id,
        a.device_id,
        g.latitude,
        g.longitude,
        g.accuracy,
        g.recorded_at,
        g.source
    FROM active_installations a
    JOIN gps_logs g ON g.device_id = a.device_id
    WHERE g.recorded_at >= a.installed_at
      AND g.source <> 'MANUAL_IMPORT'
      AND g.latitude BETWEEN -90 AND 90
      AND g.longitude BETWEEN -180 AND 180
      AND NOT (g.latitude = 0 AND g.longitude = 0)
    ORDER BY a.livestock_id, g.recorded_at DESC
)
INSERT INTO livestock_location_snapshots (
    livestock_id, farm_id, device_id, latitude, longitude,
    accuracy, recorded_at, source, position_revision
)
SELECT
    livestock_id, farm_id, device_id, latitude, longitude,
    accuracy, recorded_at, source, 0
FROM latest_valid_positions;

ALTER TABLE health_snapshots
    ADD COLUMN IF NOT EXISTS current_temp_recorded_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS current_temp_source VARCHAR(32),
    ADD COLUMN IF NOT EXISTS current_motility_recorded_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS current_motility_source VARCHAR(32);

UPDATE health_snapshots hs
SET current_temp_recorded_at = t.recorded_at,
    current_temp_source = CASE
        WHEN t.source IN ('AGENTIC_PLATFORM', 'THINGSBOARD', 'DATAGEN', 'HTTP', 'MANUAL_IMPORT')
            THEN t.source
        ELSE NULL
    END
FROM (
    SELECT DISTINCT ON (livestock_id)
        livestock_id, temperature, recorded_at, source
    FROM temperature_logs
    WHERE livestock_id IS NOT NULL
      AND temperature BETWEEN 20 AND 45
    ORDER BY livestock_id, recorded_at DESC
) t
WHERE t.livestock_id = hs.livestock_id
  AND t.temperature = hs.current_temp
  AND hs.current_temp IS NOT NULL
  AND hs.current_temp_recorded_at IS NULL;

UPDATE health_snapshots hs
SET current_motility_recorded_at = m.recorded_at,
    current_motility_source = CASE
        WHEN m.source IN ('AGENTIC_PLATFORM', 'THINGSBOARD', 'DATAGEN', 'HTTP', 'MANUAL_IMPORT')
            THEN m.source
        ELSE NULL
    END
FROM (
    SELECT DISTINCT ON (livestock_id)
        livestock_id, frequency, recorded_at, source
    FROM rumen_motility_logs
    WHERE livestock_id IS NOT NULL
      AND frequency IS NOT NULL
    ORDER BY livestock_id, recorded_at DESC
) m
WHERE m.livestock_id = hs.livestock_id
  AND m.frequency = hs.current_motility
  AND hs.current_motility IS NOT NULL
  AND hs.current_motility_recorded_at IS NULL;
