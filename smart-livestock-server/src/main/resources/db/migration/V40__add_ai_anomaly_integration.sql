-- V40: AI anomaly detection integration tables
-- Phase A design §6: anomaly_scores + health_snapshots AI columns + alerts source/type

-- §6.1: anomaly_scores table (monthly partitioned, aligned with health time-series tables)
CREATE TABLE anomaly_scores (
    id BIGSERIAL,
    tenant_id BIGINT NOT NULL,
    farm_id BIGINT NOT NULL,
    livestock_id BIGINT NOT NULL,
    window_start TIMESTAMP NOT NULL,
    window_end TIMESTAMP NOT NULL,
    anomaly_score DECIMAL(4,3) NOT NULL,
    anomaly_type VARCHAR(32) NOT NULL,
    contributions JSONB,
    capability_used VARCHAR(32) NOT NULL,
    n_eff INTEGER,
    model_meta JSONB,
    label VARCHAR(16),
    labeled_by BIGINT,
    labeled_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

-- Create default partition (required for INSERT to work without explicit monthly partitions)
CREATE TABLE anomaly_scores_default PARTITION OF anomaly_scores DEFAULT;

CREATE INDEX idx_anomaly_livestock ON anomaly_scores (farm_id, livestock_id, created_at DESC);
CREATE INDEX idx_anomaly_unlabeled ON anomaly_scores (farm_id, anomaly_score DESC)
    WHERE label IS NULL;

-- §6.2: health_snapshots AI columns
ALTER TABLE health_snapshots ADD COLUMN IF NOT EXISTS ai_anomaly_score DECIMAL(4,3);
ALTER TABLE health_snapshots ADD COLUMN IF NOT EXISTS ai_anomaly_type  VARCHAR(32);
ALTER TABLE health_snapshots ADD COLUMN IF NOT EXISTS ai_assessed_at   TIMESTAMP;

-- §6.3: alerts source column + AI_ANOMALY type
ALTER TABLE alerts ADD COLUMN IF NOT EXISTS source VARCHAR(16) NOT NULL DEFAULT 'RULE';
ALTER TABLE alerts ADD CONSTRAINT chk_alerts_source CHECK (source IN ('RULE','AI'));

-- Rebuild type constraint (V26 has 7 values, append AI_ANOMALY)
ALTER TABLE alerts DROP CONSTRAINT IF EXISTS chk_alerts_type;
ALTER TABLE alerts ADD CONSTRAINT chk_alerts_type CHECK (type IN (
    'FENCE_BREACH','FENCE_APPROACH','ZONE_APPROACH','TEMPERATURE_ABNORMAL',
    'DIGESTIVE_ABNORMAL','ESTRUS','EPIDEMIC','AI_ANOMALY'));
