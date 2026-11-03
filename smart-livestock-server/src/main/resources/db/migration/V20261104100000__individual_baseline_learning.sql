-- Individual baseline auto-learning (plan 2026-11-03): per-animal temperature
-- baseline learning columns. Additive-only migration — new columns are added
-- with IF NOT EXISTS guards and NO existing data is rewritten. Historical rows
-- keep the DEFAULT baseline behavior; baseline_source = NULL on estrus_scores
-- marks pre-learning (legacy) scoring rows.

-- health_snapshots: learned-baseline state (source flag, sample evidence,
-- event-time window, computed band, algorithm version for audit/rollback).
ALTER TABLE health_snapshots
    ADD COLUMN IF NOT EXISTS baseline_source VARCHAR(12) NOT NULL DEFAULT 'DEFAULT';
ALTER TABLE health_snapshots DROP CONSTRAINT IF EXISTS chk_health_snapshots_baseline_source;
ALTER TABLE health_snapshots ADD CONSTRAINT chk_health_snapshots_baseline_source
    CHECK (baseline_source IN ('DEFAULT','LEARNED'));

ALTER TABLE health_snapshots
    ADD COLUMN IF NOT EXISTS baseline_sample_count INTEGER;
ALTER TABLE health_snapshots
    ADD COLUMN IF NOT EXISTS baseline_qualified_days INTEGER;
ALTER TABLE health_snapshots
    ADD COLUMN IF NOT EXISTS baseline_window_start TIMESTAMP;
ALTER TABLE health_snapshots
    ADD COLUMN IF NOT EXISTS baseline_computed_at TIMESTAMP;
ALTER TABLE health_snapshots
    ADD COLUMN IF NOT EXISTS baseline_band_low DECIMAL(5,2);
ALTER TABLE health_snapshots
    ADD COLUMN IF NOT EXISTS baseline_band_high DECIMAL(5,2);
ALTER TABLE health_snapshots
    ADD COLUMN IF NOT EXISTS baseline_algorithm_version VARCHAR(16);

-- temperature_logs: which baseline produced each log's baseline_temp/delta
-- (partitioned table; plain ALTER TABLE per the V20260817160000 pattern).
ALTER TABLE temperature_logs
    ADD COLUMN IF NOT EXISTS baseline_source VARCHAR(12) NOT NULL DEFAULT 'DEFAULT';
ALTER TABLE temperature_logs DROP CONSTRAINT IF EXISTS chk_temperature_logs_baseline_source;
ALTER TABLE temperature_logs ADD CONSTRAINT chk_temperature_logs_baseline_source
    CHECK (baseline_source IN ('DEFAULT','LEARNED'));

-- estrus_scores: audit trail of the baseline used at scoring time. Nullable on
-- purpose — NULL means the row predates learning (legacy fixed 38.50 baseline).
ALTER TABLE estrus_scores
    ADD COLUMN IF NOT EXISTS baseline_used DECIMAL(5,2);
ALTER TABLE estrus_scores
    ADD COLUMN IF NOT EXISTS baseline_source VARCHAR(12);
ALTER TABLE estrus_scores DROP CONSTRAINT IF EXISTS chk_estrus_scores_baseline_source;
ALTER TABLE estrus_scores ADD CONSTRAINT chk_estrus_scores_baseline_source
    CHECK (baseline_source IN ('DEFAULT','LEARNED'));
ALTER TABLE estrus_scores
    ADD COLUMN IF NOT EXISTS baseline_computed_at TIMESTAMP;
ALTER TABLE estrus_scores
    ADD COLUMN IF NOT EXISTS baseline_algorithm_version VARCHAR(16);
