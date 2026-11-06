-- ============================================================
-- NIX-381: Calving prediction service — DDL (plan 2026-11-06)
-- Four additive sections:
--   1. health_snapshots.calving_risk_score (NULL = never assessed)
--   2. calving_predictions history table (mirrors estrus_scores, V20)
--   3. chk_alerts_type rebuild: 14 -> 15 values (+ CALVING_WARNING)
--   4. feature_gates seed: calving_warning (tiering aligned with estrus_detect)
-- ============================================================

-- ----------------------------------------------------------
-- Part 1: health_snapshots — calving risk column
-- NULL means the animal has never been assessed by the calving
-- predictor (distinct from 0 = assessed and found not at risk).
-- Written only via the targeted updateCalvingRiskScore UPDATE —
-- never through whole-entity saves (concurrent writers on the
-- snapshot row: telemetry ingestion, baseline learning).
-- ----------------------------------------------------------
ALTER TABLE health_snapshots ADD COLUMN calving_risk_score INT;

-- ----------------------------------------------------------
-- Part 2: calving_predictions — calving risk evaluation history
-- Mirrors the estrus_scores shape (V20): farm-scoped score rows,
-- no FK on livestock_id, CHECK-bounded score, DESC time indexes
-- plus a partial index over the alert-grade band. Baseline audit
-- columns are inlined from day one (V20261104100000 had to backfill
-- them onto estrus_scores afterwards).
-- ----------------------------------------------------------
CREATE TABLE calving_predictions (
    id BIGSERIAL PRIMARY KEY,
    farm_id BIGINT NOT NULL REFERENCES farms(id),
    livestock_id BIGINT NOT NULL,
    risk_score INTEGER NOT NULL CONSTRAINT chk_calving_score CHECK (risk_score BETWEEN 0 AND 100),
    temp_drop_celsius DECIMAL(4,2),
    activity_ratio DECIMAL(5,2),
    prior_enabled BOOLEAN,
    expected_window_start TIMESTAMP,
    expected_window_end TIMESTAMP,
    expected_calving_at TIMESTAMP,
    predicted_at TIMESTAMP NOT NULL,
    baseline_used DECIMAL(5,2),
    baseline_source VARCHAR(12) CONSTRAINT chk_calving_baseline_source CHECK (baseline_source IN ('DEFAULT','LEARNED')),
    baseline_computed_at TIMESTAMP,
    baseline_algorithm_version VARCHAR(16),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_calving_farm_time ON calving_predictions(farm_id, predicted_at DESC);
CREATE INDEX idx_calving_livestock_time ON calving_predictions(livestock_id, predicted_at DESC);
CREATE INDEX idx_calving_high_score ON calving_predictions(risk_score) WHERE risk_score >= 70;

-- ----------------------------------------------------------
-- Part 3: alerts type check — rebuild with the new CALVING_WARNING
-- value (same DROP-then-ADD pattern as V20260925100000).
-- ----------------------------------------------------------
ALTER TABLE alerts DROP CONSTRAINT IF EXISTS chk_alerts_type;
ALTER TABLE alerts ADD CONSTRAINT chk_alerts_type CHECK (type IN (
    'FENCE_BREACH', 'FENCE_APPROACH', 'ZONE_APPROACH', 'TEMPERATURE_ABNORMAL',
    'DIGESTIVE_ABNORMAL', 'ESTRUS', 'EPIDEMIC', 'AI_ANOMALY',
    'DEVICE_TAMPER', 'DEVICE_LOW_BATTERY', 'DEVICE_OFFLINE',
    'LINK_QUALITY', 'OUTLIER', 'RETURN_HOME', 'CALVING_WARNING'));

-- ----------------------------------------------------------
-- Part 4: feature_gates — calving_warning premium gate (NIX-381).
-- Tiering aligned with estrus_detect (V31 Part 6): basic/standard
-- locked, premium/enterprise open. retention_days is NULL — this
-- gate does not own a data-retention window. Reuses the health
-- subscription ACL (HealthSubscriptionPort -> subscriptions
-- .effective_tier -> feature_gates); active trials resolve to
-- PREMIUM via Subscription.effectiveTier(), consistent with the
-- other gates.
-- ----------------------------------------------------------
INSERT INTO feature_gates (tier, feature_key, gate_type, limit_value, retention_days, is_enabled) VALUES
    ('basic', 'calving_warning', 'lock', NULL, NULL, FALSE),
    ('standard', 'calving_warning', 'lock', NULL, NULL, FALSE),
    ('premium', 'calving_warning', 'none', NULL, NULL, TRUE),
    ('enterprise', 'calving_warning', 'none', NULL, NULL, TRUE)
ON CONFLICT (tier, feature_key) DO UPDATE SET
    gate_type = EXCLUDED.gate_type,
    limit_value = EXCLUDED.limit_value,
    retention_days = EXCLUDED.retention_days,
    is_enabled = EXCLUDED.is_enabled;
