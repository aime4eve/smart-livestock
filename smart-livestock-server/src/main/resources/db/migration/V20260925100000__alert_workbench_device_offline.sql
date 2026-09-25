-- Alert workbench V1: add the managed device-offline alert type.
ALTER TABLE alerts DROP CONSTRAINT IF EXISTS chk_alerts_type;
ALTER TABLE alerts ADD CONSTRAINT chk_alerts_type CHECK (type IN (
    'FENCE_BREACH', 'FENCE_APPROACH', 'ZONE_APPROACH', 'TEMPERATURE_ABNORMAL',
    'DIGESTIVE_ABNORMAL', 'ESTRUS', 'EPIDEMIC', 'AI_ANOMALY',
    'DEVICE_TAMPER', 'DEVICE_LOW_BATTERY', 'DEVICE_OFFLINE',
    'LINK_QUALITY', 'OUTLIER', 'RETURN_HOME'));

CREATE INDEX IF NOT EXISTS idx_alerts_farm_type_status_created
    ON alerts(farm_id, type, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_device_type_status
    ON alerts(device_id, type, status);

-- Make the new behavior observable on a fresh deployment: select one installed
-- ACTIVE device, move its signal timestamps behind the 2-hour threshold, and
-- create the matching seed ticket. Data-modifying CTEs keep this to one device.
WITH candidate AS MATERIALIZED (
    SELECT d.id
    FROM installations i
    JOIN livestock l ON l.id = i.livestock_id AND l.deleted_at IS NULL
    JOIN devices d ON d.id = i.device_id
                  AND d.deleted_at IS NULL
                  AND d.status = 'ACTIVE'
    WHERE i.removed_at IS NULL
      AND NOT EXISTS (
          SELECT 1 FROM alerts a
          WHERE a.device_id = d.id
            AND a.type = 'DEVICE_OFFLINE'
            AND a.status = 'ACTIVE'
      )
    ORDER BY d.id
    LIMIT 1
),
stale_device AS (
    UPDATE devices d
    SET last_online_at = NOW() - INTERVAL '3 hours',
        last_telemetry_synced_at = NOW() - INTERVAL '3 hours',
        updated_at = NOW()
    FROM candidate
    WHERE d.id = candidate.id
    RETURNING d.id, d.device_code
),
target AS (
    SELECT i.livestock_id, l.farm_id, sd.id AS device_id, sd.device_code
    FROM stale_device sd
    JOIN installations i ON i.device_id = sd.id AND i.removed_at IS NULL
    JOIN livestock l ON l.id = i.livestock_id AND l.deleted_at IS NULL
)
INSERT INTO alerts (
    farm_id, livestock_id, device_id, type, status, severity,
    message, message_key, message_args, source, created_at, updated_at
)
SELECT target.farm_id, target.livestock_id, target.device_id,
       'DEVICE_OFFLINE', 'ACTIVE', 'WARNING',
       'Device offline: ' || target.device_code,
       'alert.device.offline',
       to_jsonb(ARRAY[target.device_code])::text,
       'RULE',
       NOW() - INTERVAL '3 hours',
       NOW()
FROM target;
