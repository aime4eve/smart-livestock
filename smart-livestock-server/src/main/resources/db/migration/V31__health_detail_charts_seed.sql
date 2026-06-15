-- ============================================================
-- V31: Health detail charts — refresh recent time-series seed + feature gates + contact_traces extension
--
-- Problem: V21/V10 seed timestamps are fixed at 2026-03-01 ~ 04-08.
-- Detail pages query now()-72h / now()-24h, so charts are empty.
-- This migration inserts now()-relative data so charts render immediately after deploy.
--
-- Livestock reference (farm_id=1):
--   SL-2024-048  Fever CRITICAL (40.5°C)  capsule dev=62
--   SL-2024-012  Fever FEVER     (40.2°C) capsule dev=53
--   SL-2024-003  Fever ELEVATED  (39.6°C) capsule dev=51 (SL-004->51? no: idx*4: 4->51)
--   SL-2024-024  Digestive ABNORMAL          capsule dev=56
--   SL-2024-036  Digestive LOW               capsule dev=59
--   SL-2024-016  Estrus score 92             capsule dev=54 + tracker
--   SL-2024-032  Estrus score 78             capsule dev=58 + tracker
-- ============================================================

-- ----------------------------------------------------------
-- Part 1: temperature_logs — refresh abnormal livestock last 72h
-- ----------------------------------------------------------

-- SL-2024-048 CRITICAL: 40.0-41.0°C
INSERT INTO temperature_logs (livestock_id, device_id, temperature, baseline_temp, recorded_at)
SELECT ls.id, 62, 40.0 + random() * 1.0, 38.50, ts
FROM livestock ls
CROSS JOIN (
    SELECT generate_series(now() - interval '72 hours', now(), '30 minutes'::interval) AS ts
) s
WHERE ls.livestock_code = 'SL-2024-048' AND ls.farm_id = 1 AND ls.deleted_at IS NULL;

-- SL-2024-012 FEVER: 39.5-40.5°C
INSERT INTO temperature_logs (livestock_id, device_id, temperature, baseline_temp, recorded_at)
SELECT ls.id, 53, 39.5 + random() * 1.0, 38.50, ts
FROM livestock ls
CROSS JOIN (
    SELECT generate_series(now() - interval '72 hours', now(), '30 minutes'::interval) AS ts
) s
WHERE ls.livestock_code = 'SL-2024-012' AND ls.farm_id = 1 AND ls.deleted_at IS NULL;

-- SL-2024-003 ELEVATED: 38.8-39.6°C (capsule device for SL-004 is 51, but SL-003 has no capsule)
-- SL-003 has no capsule install (capsule map is idx*4: 4,8,12...48). SL-003 not in capsule_map.
-- Use device_id from its tracker install if any. Device 3 is tracker for SL-003.
-- But temperature requires capsule. Skip SL-003 temp logs (no capsule), its snapshot temp_status is already ELEVATED.

-- SL-2024-017 ELEVATED: same — SL-017 not in capsule_map (17 not divisible by 4). Skip.

-- Also refresh a few normal livestock for comparison charts
-- SL-2024-004 NORMAL: 38.0-38.8°C (capsule dev=51)
INSERT INTO temperature_logs (livestock_id, device_id, temperature, baseline_temp, recorded_at)
SELECT ls.id, 51, 38.0 + random() * 0.8, 38.50, ts
FROM livestock ls
CROSS JOIN (
    SELECT generate_series(now() - interval '72 hours', now(), '30 minutes'::interval) AS ts
) s
WHERE ls.livestock_code = 'SL-2024-004' AND ls.farm_id = 1 AND ls.deleted_at IS NULL;

-- ----------------------------------------------------------
-- Part 2: rumen_motility_logs — extend SL-024 to 72h (V27 only has 24h)
-- ----------------------------------------------------------
INSERT INTO rumen_motility_logs (livestock_id, device_id, frequency, intensity, recorded_at)
SELECT ls.id, 56, 0.8 + random() * 0.6, 25.0 + random() * 15.0, ts
FROM livestock ls
CROSS JOIN (
    SELECT generate_series(now() - interval '72 hours', now(), '30 minutes'::interval) AS ts
) s
WHERE ls.livestock_code = 'SL-2024-024' AND ls.farm_id = 1 AND ls.deleted_at IS NULL;

-- SL-2024-036 LOW: extend to 72h
INSERT INTO rumen_motility_logs (livestock_id, device_id, frequency, intensity, recorded_at)
SELECT ls.id, 59, 1.6 + random() * 0.4, 30.0 + random() * 20.0, ts
FROM livestock ls
CROSS JOIN (
    SELECT generate_series(now() - interval '72 hours', now(), '30 minutes'::interval) AS ts
) s
WHERE ls.livestock_code = 'SL-2024-036' AND ls.farm_id = 1 AND ls.deleted_at IS NULL;

-- SL-2024-004 NORMAL: for comparison chart
INSERT INTO rumen_motility_logs (livestock_id, device_id, frequency, intensity, recorded_at)
SELECT ls.id, 51, 2.5 + random() * 2.0, 40.0 + random() * 40.0, ts
FROM livestock ls
CROSS JOIN (
    SELECT generate_series(now() - interval '24 hours', now(), '30 minutes'::interval) AS ts
) s
WHERE ls.livestock_code = 'SL-2024-004' AND ls.farm_id = 1 AND ls.deleted_at IS NULL;

-- ----------------------------------------------------------
-- Part 3: activity_logs — refresh estrus livestock last 7d
-- ----------------------------------------------------------

-- SL-2024-016 high activity (estrus, tracker device from installation)
INSERT INTO activity_logs (livestock_id, device_id, step_count, activity_index, distance_meters, recorded_at)
SELECT
    ls.id,
    (SELECT inst.device_id FROM installations inst
     JOIN livestock ls2 ON ls2.id = inst.livestock_id
     WHERE ls2.livestock_code = 'SL-2024-016' AND inst.removed_at IS NULL
       AND inst.device_id IN (SELECT id FROM devices WHERE device_type = 'TRACKER') LIMIT 1),
    CASE WHEN EXTRACT(HOUR FROM ts) BETWEEN 6 AND 20 THEN 2500 + (random() * 1500)::int ELSE 100 + (random() * 300)::int END,
    CASE WHEN EXTRACT(HOUR FROM ts) BETWEEN 6 AND 20 THEN 70.0 + random() * 30.0 ELSE 10.0 + random() * 20.0 END,
    CASE WHEN EXTRACT(HOUR FROM ts) BETWEEN 6 AND 20 THEN 1500.0 + random() * 1000.0 ELSE 20.0 + random() * 50.0 END,
    ts
FROM livestock ls
CROSS JOIN (
    SELECT generate_series(now() - interval '7 days', now(), '1 hour'::interval) AS ts
) s
WHERE ls.livestock_code = 'SL-2024-016' AND ls.farm_id = 1 AND ls.deleted_at IS NULL;

-- SL-2024-032 moderate activity
INSERT INTO activity_logs (livestock_id, device_id, step_count, activity_index, distance_meters, recorded_at)
SELECT
    ls.id,
    (SELECT inst.device_id FROM installations inst
     JOIN livestock ls2 ON ls2.id = inst.livestock_id
     WHERE ls2.livestock_code = 'SL-2024-032' AND inst.removed_at IS NULL
       AND inst.device_id IN (SELECT id FROM devices WHERE device_type = 'TRACKER') LIMIT 1),
    CASE WHEN EXTRACT(HOUR FROM ts) BETWEEN 6 AND 20 THEN 2000 + (random() * 1200)::int ELSE 80 + (random() * 250)::int END,
    CASE WHEN EXTRACT(HOUR FROM ts) BETWEEN 6 AND 20 THEN 55.0 + random() * 30.0 ELSE 8.0 + random() * 15.0 END,
    CASE WHEN EXTRACT(HOUR FROM ts) BETWEEN 6 AND 20 THEN 1000.0 + random() * 800.0 ELSE 15.0 + random() * 40.0 END,
    ts
FROM livestock ls
CROSS JOIN (
    SELECT generate_series(now() - interval '7 days', now(), '1 hour'::interval) AS ts
) s
WHERE ls.livestock_code = 'SL-2024-032' AND ls.farm_id = 1 AND ls.deleted_at IS NULL;

-- ----------------------------------------------------------
-- Part 4: estrus_scores — refresh timestamps + add 7d trend
-- ----------------------------------------------------------

-- Update existing high-score records to now()
UPDATE estrus_scores SET scored_at = now()
WHERE livestock_id = (SELECT id FROM livestock WHERE livestock_code = 'SL-2024-016' AND farm_id = 1)
  AND score >= 90;

UPDATE estrus_scores SET scored_at = now() - interval '6 hours'
WHERE livestock_id = (SELECT id FROM livestock WHERE livestock_code = 'SL-2024-032' AND farm_id = 1)
  AND score >= 70;

-- Add 7-day historical trend for SL-2024-016 (rising scores)
INSERT INTO estrus_scores (farm_id, livestock_id, score, step_increase_percent, temp_delta, distance_delta, scored_at)
SELECT 1, ls.id,
    CASE day_offset
        WHEN 6 THEN 25 + (random() * 10)::int
        WHEN 5 THEN 35 + (random() * 10)::int
        WHEN 4 THEN 45 + (random() * 10)::int
        WHEN 3 THEN 55 + (random() * 10)::int
        WHEN 2 THEN 68 + (random() * 8)::int
        WHEN 1 THEN 80 + (random() * 5)::int
        ELSE 92
    END,
    (random() * 100)::int,
    random() * 0.3,
    random() * 200,
    now() - (day_offset * interval '1 day')
FROM livestock ls
CROSS JOIN (SELECT generate_series(6, 1, -1) AS day_offset) d
WHERE ls.livestock_code = 'SL-2024-016' AND ls.farm_id = 1 AND ls.deleted_at IS NULL;

-- Add 7-day trend for SL-2024-032
INSERT INTO estrus_scores (farm_id, livestock_id, score, step_increase_percent, temp_delta, distance_delta, scored_at)
SELECT 1, ls.id,
    CASE day_offset
        WHEN 6 THEN 15 + (random() * 10)::int
        WHEN 5 THEN 25 + (random() * 10)::int
        WHEN 4 THEN 35 + (random() * 10)::int
        WHEN 3 THEN 42 + (random() * 8)::int
        WHEN 2 THEN 55 + (random() * 10)::int
        WHEN 1 THEN 68 + (random() * 5)::int
        ELSE 78
    END,
    (random() * 80)::int,
    random() * 0.25,
    random() * 150,
    now() - (day_offset * interval '1 day')
FROM livestock ls
CROSS JOIN (SELECT generate_series(6, 1, -1) AS day_offset) d
WHERE ls.livestock_code = 'SL-2024-032' AND ls.farm_id = 1 AND ls.deleted_at IS NULL;

-- ----------------------------------------------------------
-- Part 5: contact_traces — extend table + seed epidemic data
-- ----------------------------------------------------------

ALTER TABLE contact_traces ADD COLUMN IF NOT EXISTS disease_type VARCHAR(50);
ALTER TABLE contact_traces ADD COLUMN IF NOT EXISTS marked_at TIMESTAMP;
ALTER TABLE contact_traces ADD COLUMN IF NOT EXISTS risk_score INT DEFAULT 0;
ALTER TABLE contact_traces ADD COLUMN IF NOT EXISTS risk_level VARCHAR(10) DEFAULT 'LOW';

-- Mark SL-2024-048 as disease source via contact_traces (disease_type set on outgoing traces)
-- Refresh existing SL-048 contact times to now()-relative
UPDATE contact_traces
SET last_contact_at = now() - interval '3 hours',
    disease_type = '口蹄疫疑似',
    marked_at = now() - interval '2 hours',
    risk_score = 82,
    risk_level = 'HIGH'
WHERE from_livestock_id = (SELECT id FROM livestock WHERE livestock_code = 'SL-2024-048' AND farm_id = 1);

-- 24h window contacts (HIGH risk: close + long duration)
INSERT INTO contact_traces (farm_id, from_livestock_id, to_livestock_id, proximity_meters, contact_duration_minutes, last_contact_at, disease_type, marked_at, risk_score, risk_level)
SELECT 1,
    (SELECT id FROM livestock WHERE livestock_code = 'SL-2024-048' AND farm_id = 1),
    ls.id,
    3.0 + random() * 2.0,
    45,
    now() - interval '3 hours',
    '口蹄疫疑似',
    now() - interval '2 hours',
    82,
    'HIGH'
FROM livestock ls
WHERE ls.livestock_code = 'SL-2024-012' AND ls.farm_id = 1 AND ls.deleted_at IS NULL
  AND NOT EXISTS (
    SELECT 1 FROM contact_traces ct
    WHERE ct.from_livestock_id = (SELECT id FROM livestock WHERE livestock_code = 'SL-2024-048')
      AND ct.to_livestock_id = ls.id
  );

-- 48h window contacts (MEDIUM risk)
INSERT INTO contact_traces (farm_id, from_livestock_id, to_livestock_id, proximity_meters, contact_duration_minutes, last_contact_at, disease_type, marked_at, risk_score, risk_level)
SELECT 1,
    (SELECT id FROM livestock WHERE livestock_code = 'SL-2024-048' AND farm_id = 1),
    ls.id,
    15.0 + random() * 5.0,
    18,
    now() - interval '36 hours',
    '口蹄疫疑似',
    now() - interval '2 hours',
    58,
    'MEDIUM'
FROM livestock ls
WHERE ls.livestock_code = 'SL-2024-004' AND ls.farm_id = 1 AND ls.deleted_at IS NULL
  AND NOT EXISTS (
    SELECT 1 FROM contact_traces ct
    WHERE ct.from_livestock_id = (SELECT id FROM livestock WHERE livestock_code = 'SL-2024-048')
      AND ct.to_livestock_id = ls.id
  );

-- 72h window contacts (LOW risk)
INSERT INTO contact_traces (farm_id, from_livestock_id, to_livestock_id, proximity_meters, contact_duration_minutes, last_contact_at, disease_type, marked_at, risk_score, risk_level)
SELECT 1,
    (SELECT id FROM livestock WHERE livestock_code = 'SL-2024-048' AND farm_id = 1),
    ls.id,
    45.0 + random() * 10.0,
    5,
    now() - interval '60 hours',
    '口蹄疫疑似',
    now() - interval '2 hours',
    28,
    'LOW'
FROM livestock ls
WHERE ls.livestock_code = 'SL-2024-008' AND ls.farm_id = 1 AND ls.deleted_at IS NULL
  AND NOT EXISTS (
    SELECT 1 FROM contact_traces ct
    WHERE ct.from_livestock_id = (SELECT id FROM livestock WHERE livestock_code = 'SL-2024-048')
      AND ct.to_livestock_id = ls.id
  );

-- ----------------------------------------------------------
-- Part 6: feature_gates — health module fine-grained feature keys
-- ----------------------------------------------------------
INSERT INTO feature_gates (tier, feature_key, gate_type, limit_value, retention_days, is_enabled) VALUES
    -- basic: basic monitoring only, 7-day retention
    ('basic', 'temperature_monitor', 'none', NULL, 7, TRUE),
    ('basic', 'peristaltic_monitor', 'none', NULL, 7, TRUE),
    ('basic', 'health_score', 'lock', NULL, NULL, FALSE),
    ('basic', 'estrus_detect', 'lock', NULL, NULL, FALSE),
    ('basic', 'epidemic_alert', 'lock', NULL, NULL, FALSE),
    -- standard: unlock depth analysis, 30-day retention
    ('standard', 'temperature_monitor', 'none', NULL, 30, TRUE),
    ('standard', 'peristaltic_monitor', 'none', NULL, 30, TRUE),
    ('standard', 'health_score', 'none', NULL, 30, TRUE),
    ('standard', 'estrus_detect', 'lock', NULL, NULL, FALSE),
    ('standard', 'epidemic_alert', 'lock', NULL, NULL, FALSE),
    -- premium: unlock estrus + epidemic, 365-day retention
    ('premium', 'temperature_monitor', 'none', NULL, 365, TRUE),
    ('premium', 'peristaltic_monitor', 'none', NULL, 365, TRUE),
    ('premium', 'health_score', 'none', NULL, 365, TRUE),
    ('premium', 'estrus_detect', 'none', NULL, 365, TRUE),
    ('premium', 'epidemic_alert', 'none', NULL, 365, TRUE),
    -- enterprise: all unlocked, 3-year retention
    ('enterprise', 'temperature_monitor', 'none', NULL, 1095, TRUE),
    ('enterprise', 'peristaltic_monitor', 'none', NULL, 1095, TRUE),
    ('enterprise', 'health_score', 'none', NULL, 1095, TRUE),
    ('enterprise', 'estrus_detect', 'none', NULL, 1095, TRUE),
    ('enterprise', 'epidemic_alert', 'none', NULL, 1095, TRUE)
ON CONFLICT (tier, feature_key) DO UPDATE SET
    gate_type = EXCLUDED.gate_type,
    retention_days = EXCLUDED.retention_days,
    is_enabled = EXCLUDED.is_enabled;

-- ----------------------------------------------------------
-- Part 7: update health_snapshots timestamps
-- ----------------------------------------------------------
UPDATE health_snapshots SET last_assessed_at = now(), updated_at = now()
WHERE farm_id = 1;

-- Reset sequences
SELECT setval('estrus_scores_id_seq', (SELECT COALESCE(MAX(id), 1) FROM estrus_scores));
SELECT setval('contact_traces_id_seq', (SELECT COALESCE(MAX(id), 1) FROM contact_traces));
