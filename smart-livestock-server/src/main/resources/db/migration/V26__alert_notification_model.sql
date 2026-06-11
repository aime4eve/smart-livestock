-- ============================================================
-- V26: Alert Notification Model — notification center model + fence zones + buffer zones
-- ============================================================

-- 1. alert_read_status: per-user read tracking
CREATE TABLE alert_read_status (
    id            BIGSERIAL PRIMARY KEY,
    alert_id      BIGINT NOT NULL REFERENCES alerts(id),
    user_id       BIGINT NOT NULL REFERENCES users(id),
    read_at       TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(alert_id, user_id)
);
CREATE INDEX idx_alert_read_user ON alert_read_status(user_id);
CREATE INDEX idx_alert_read_alert ON alert_read_status(alert_id);

-- 2. fence_zones: key monitoring areas inside fences
CREATE TABLE fence_zones (
    id            BIGSERIAL PRIMARY KEY,
    fence_id      BIGINT NOT NULL REFERENCES fences(id),
    farm_id       BIGINT NOT NULL,
    name          VARCHAR(100) NOT NULL,
    zone_type     VARCHAR(30) NOT NULL,
    vertices      JSONB NOT NULL,
    alert_radius  INTEGER DEFAULT 20,
    severity      VARCHAR(10) DEFAULT 'INFO',
    active        BOOLEAN DEFAULT TRUE,
    created_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
CREATE INDEX idx_fence_zones_fence ON fence_zones(fence_id);
CREATE INDEX idx_fence_zones_farm ON fence_zones(farm_id);

-- 3. alerts table: extend with resolved fields
ALTER TABLE alerts ADD COLUMN IF NOT EXISTS resolved_type VARCHAR(20);
ALTER TABLE alerts ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMP WITH TIME ZONE;

-- 4. fences table: extend with buffer zone fields
ALTER TABLE fences ADD COLUMN IF NOT EXISTS buffer_distance INTEGER DEFAULT 50;
ALTER TABLE fences ADD COLUMN IF NOT EXISTS buffer_polygon JSONB;

-- 5. Drop old CHECK constraints BEFORE data migration
ALTER TABLE alerts DROP CONSTRAINT IF EXISTS chk_alerts_status;
ALTER TABLE alerts DROP CONSTRAINT IF EXISTS chk_alerts_type;

-- 6. Data migration: old 4-state → new 3-state
UPDATE alerts SET status = 'ACTIVE' WHERE status IN ('PENDING', 'ACKNOWLEDGED');
UPDATE alerts SET status = 'DISMISSED', resolved_type = 'MANUAL_DISMISS',
    resolved_at = COALESCE(handled_at, acknowledged_at, NOW())
    WHERE status = 'HANDLED';
UPDATE alerts SET status = 'AUTO_RESOLVED', resolved_type = 'AUTO',
    resolved_at = COALESCE(handled_at, acknowledged_at, NOW())
    WHERE status = 'ARCHIVED';

-- 7. Rename BEHAVIOR_ABNORMAL → DIGESTIVE_ABNORMAL
UPDATE alerts SET type = 'DIGESTIVE_ABNORMAL' WHERE type = 'BEHAVIOR_ABNORMAL';

-- 8. Backfill alert_read_status from acknowledged_by
INSERT INTO alert_read_status (alert_id, user_id, read_at)
SELECT id, acknowledged_by, COALESCE(acknowledged_at, NOW())
FROM alerts WHERE acknowledged_by IS NOT NULL
ON CONFLICT DO NOTHING;

-- 9. Add new CHECK constraints with updated enum values
ALTER TABLE alerts ADD CONSTRAINT chk_alerts_status
    CHECK (status IN ('ACTIVE', 'DISMISSED', 'AUTO_RESOLVED'));
ALTER TABLE alerts ADD CONSTRAINT chk_alerts_type
    CHECK (type IN ('FENCE_BREACH', 'FENCE_APPROACH', 'ZONE_APPROACH',
                     'TEMPERATURE_ABNORMAL', 'DIGESTIVE_ABNORMAL', 'ESTRUS', 'EPIDEMIC'));

-- NOTE: old columns (acknowledged_by, acknowledged_at, handled_by, handled_at) retained
-- for backward compatibility during frontend migration window.
