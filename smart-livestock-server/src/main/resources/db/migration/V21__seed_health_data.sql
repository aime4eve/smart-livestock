-- ============================================================
-- V21: Seed Health data — temperature, motility, activity, estrus, snapshots, contacts
-- References: livestock from V9 (id 1-50, farm_id=1), devices/installations from V10
-- ============================================================

CREATE TEMP TABLE capsule_map (device_id BIGINT, livestock_id BIGINT, code TEXT);
INSERT INTO capsule_map VALUES
    (51, (SELECT id FROM livestock WHERE livestock_code='SL-2024-004'), 'SL-2024-004'),
    (52, (SELECT id FROM livestock WHERE livestock_code='SL-2024-008'), 'SL-2024-008'),
    (53, (SELECT id FROM livestock WHERE livestock_code='SL-2024-012'), 'SL-2024-012'),
    (54, (SELECT id FROM livestock WHERE livestock_code='SL-2024-016'), 'SL-2024-016'),
    (55, (SELECT id FROM livestock WHERE livestock_code='SL-2024-020'), 'SL-2024-020'),
    (56, (SELECT id FROM livestock WHERE livestock_code='SL-2024-024'), 'SL-2024-024'),
    (57, (SELECT id FROM livestock WHERE livestock_code='SL-2024-028'), 'SL-2024-028'),
    (58, (SELECT id FROM livestock WHERE livestock_code='SL-2024-032'), 'SL-2024-032'),
    (59, (SELECT id FROM livestock WHERE livestock_code='SL-2024-036'), 'SL-2024-036'),
    (60, (SELECT id FROM livestock WHERE livestock_code='SL-2024-040'), 'SL-2024-040'),
    (61, (SELECT id FROM livestock WHERE livestock_code='SL-2024-044'), 'SL-2024-044'),
    (62, (SELECT id FROM livestock WHERE livestock_code='SL-2024-048'), 'SL-2024-048');

-- ============================================================
-- 1. temperature_logs: 12 capsule livestock × ~1824 samples
-- ============================================================
INSERT INTO temperature_logs (livestock_id, device_id, temperature, baseline_temp, recorded_at)
SELECT
    cm.livestock_id,
    cm.device_id,
    CASE
        WHEN cm.code = 'SL-2024-048' THEN 40.0 + (random() * 1.0)
        WHEN cm.code = 'SL-2024-012' AND d.day_date >= '2026-04-06' THEN 39.5 + (random() * 1.3)
        ELSE 38.2 + (random() * 1.0)
    END,
    38.50,
    ts.ts
FROM capsule_map cm
CROSS JOIN (
    SELECT generate_series('2026-03-01 00:00:00'::timestamp, '2026-04-08 23:30:00'::timestamp, '30 minutes'::interval) AS ts
) ts
CROSS JOIN LATERAL (SELECT ts.ts::date AS day_date) d
WHERE cm.livestock_id IS NOT NULL;

-- ============================================================
-- 2. rumen_motility_logs
-- ============================================================
INSERT INTO rumen_motility_logs (livestock_id, device_id, frequency, intensity, recorded_at)
SELECT
    cm.livestock_id,
    cm.device_id,
    CASE
        WHEN cm.code = 'SL-2024-024' AND d.day_date >= '2026-04-05' THEN 0.8 + (random() * 0.6)
        ELSE 2.5 + (random() * 2.0)
    END,
    CASE
        WHEN cm.code = 'SL-2024-024' AND d.day_date >= '2026-04-05' THEN 25.0 + (random() * 15.0)
        ELSE 40.0 + (random() * 40.0)
    END,
    ts.ts
FROM capsule_map cm
CROSS JOIN (
    SELECT generate_series('2026-03-01 00:00:00'::timestamp, '2026-04-08 23:30:00'::timestamp, '30 minutes'::interval) AS ts
) ts
CROSS JOIN LATERAL (SELECT ts.ts::date AS day_date) d
WHERE cm.livestock_id IS NOT NULL;

-- ============================================================
-- 3. activity_logs: GPS livestock
-- ============================================================
CREATE TEMP TABLE gps_map AS
SELECT d.id AS device_id, inst.livestock_id, ls.livestock_code
FROM devices d
JOIN installations inst ON inst.device_id = d.id AND inst.removed_at IS NULL
JOIN livestock ls ON ls.id = inst.livestock_id
WHERE d.device_type = 'TRACKER' AND d.status = 'ACTIVE' AND d.tenant_id = 1;

INSERT INTO activity_logs (livestock_id, device_id, step_count, activity_index, distance_meters, recorded_at)
SELECT
    gm.livestock_id,
    gm.device_id,
    CASE
        WHEN gm.livestock_code = 'SL-2024-016' AND d.day_date = '2026-04-07' AND EXTRACT(HOUR FROM ts.ts) BETWEEN 6 AND 20 THEN 3200 + (random() * 1500)::int
        WHEN gm.livestock_code = 'SL-2024-032' AND d.day_date = '2026-04-06' AND EXTRACT(HOUR FROM ts.ts) BETWEEN 6 AND 20 THEN 2800 + (random() * 1200)::int
        WHEN EXTRACT(HOUR FROM ts.ts) BETWEEN 6 AND 20 THEN 800 + (random() * 1700)::int
        ELSE 50 + (random() * 250)::int
    END,
    CASE WHEN EXTRACT(HOUR FROM ts.ts) BETWEEN 6 AND 20 THEN 40.0 + random() * 45.0 ELSE 5.0 + random() * 15.0 END,
    CASE
        WHEN gm.livestock_code = 'SL-2024-016' AND d.day_date = '2026-04-07' AND EXTRACT(HOUR FROM ts.ts) BETWEEN 6 AND 20 THEN 2000.0 + random() * 1500.0
        WHEN gm.livestock_code = 'SL-2024-032' AND d.day_date = '2026-04-06' AND EXTRACT(HOUR FROM ts.ts) BETWEEN 6 AND 20 THEN 180.0 + random() * 120.0
        WHEN EXTRACT(HOUR FROM ts.ts) BETWEEN 6 AND 20 THEN 200.0 + random() * 600.0
        ELSE 10.0 + random() * 40.0
    END,
    ts.ts
FROM gps_map gm
CROSS JOIN (
    SELECT generate_series('2026-03-01 00:00:00'::timestamp, '2026-04-08 23:00:00'::timestamp, '1 hour'::interval) AS ts
) ts
CROSS JOIN LATERAL (SELECT ts.ts::date AS day_date) d;

-- ============================================================
-- 4. estrus_scores
-- ============================================================
INSERT INTO estrus_scores (farm_id, livestock_id, score, step_increase_percent, temp_delta, distance_delta, advice, scored_at)
SELECT 1, ls.id, 92, 310, 0.35, 280.00, '发情评分较高，建议 12 小时内安排配种', '2026-04-07 14:00:00'
FROM livestock ls WHERE ls.livestock_code = 'SL-2024-016' AND ls.farm_id = 1;

INSERT INTO estrus_scores (farm_id, livestock_id, score, step_increase_percent, temp_delta, distance_delta, advice, scored_at)
SELECT 1, ls.id, 78, 250, 0.28, 210.00, '发情评分中等偏高，建议持续观察并准备配种', '2026-04-06 14:00:00'
FROM livestock ls WHERE ls.livestock_code = 'SL-2024-032' AND ls.farm_id = 1;

INSERT INTO estrus_scores (farm_id, livestock_id, score, step_increase_percent, temp_delta, distance_delta, scored_at)
SELECT 1, cm.livestock_id,
    5 + (random() * 35)::int,
    (random() * 40)::int,
    random() * 0.3,
    random() * 99,
    d.dt
FROM capsule_map cm
CROSS JOIN (SELECT generate_series('2026-03-15 14:00:00'::timestamp, '2026-04-08 14:00:00'::timestamp, '1 day'::interval) AS dt) d
JOIN livestock ls ON ls.id = cm.livestock_id AND ls.gender = 'FEMALE'
WHERE cm.livestock_id IS NOT NULL AND cm.code NOT IN ('SL-2024-016', 'SL-2024-032');

-- ============================================================
-- 5. health_snapshots
-- ============================================================
INSERT INTO health_snapshots (livestock_id, farm_id, baseline_temp, current_temp, temp_status,
    motility_baseline, current_motility, motility_status, estrus_score, activity_status, last_assessed_at)
SELECT
    ls.id, ls.farm_id, 38.50,
    CASE
        WHEN ls.livestock_code = 'SL-2024-048' THEN 40.50
        WHEN ls.livestock_code = 'SL-2024-012' THEN 40.20
        WHEN ls.livestock_code = 'SL-2024-003' THEN 39.60
        ELSE 38.2 + random() * 0.8
    END,
    CASE
        WHEN ls.livestock_code = 'SL-2024-048' THEN 'CRITICAL'
        WHEN ls.livestock_code = 'SL-2024-012' THEN 'FEVER'
        WHEN ls.livestock_code IN ('SL-2024-003', 'SL-2024-017') THEN 'ELEVATED'
        ELSE 'NORMAL'
    END,
    3.00,
    CASE WHEN ls.livestock_code = 'SL-2024-024' THEN 1.10 ELSE NULL END,
    CASE
        WHEN ls.livestock_code = 'SL-2024-024' THEN 'ABNORMAL'
        ELSE 'NORMAL'
    END,
    CASE
        WHEN ls.livestock_code = 'SL-2024-016' THEN 92
        WHEN ls.livestock_code = 'SL-2024-032' THEN 78
        ELSE 0
    END,
    CASE
        WHEN ls.health_status = 'CRITICAL' THEN 'LOW'
        WHEN ls.health_status = 'WARNING' THEN 'ELEVATED'
        ELSE 'NORMAL'
    END,
    '2026-04-08 14:00:00'
FROM livestock ls
WHERE ls.farm_id = 1 AND ls.deleted_at IS NULL;

-- ============================================================
-- 6. contact_traces
-- ============================================================
INSERT INTO contact_traces (farm_id, from_livestock_id, to_livestock_id, proximity_meters, contact_duration_minutes, last_contact_at)
SELECT 1,
    (SELECT id FROM livestock WHERE livestock_code='SL-2024-048'),
    (SELECT id FROM livestock WHERE livestock_code='SL-2024-049'),
    3.0 + random() * 5.0, 120, '2026-04-08 10:30:00'
WHERE EXISTS (SELECT 1 FROM livestock WHERE livestock_code='SL-2024-048');

INSERT INTO contact_traces (farm_id, from_livestock_id, to_livestock_id, proximity_meters, contact_duration_minutes, last_contact_at)
SELECT 1,
    (SELECT id FROM livestock WHERE livestock_code='SL-2024-048'),
    (SELECT id FROM livestock WHERE livestock_code='SL-2024-050'),
    6.0 + random() * 5.0, 90, '2026-04-08 09:15:00'
WHERE EXISTS (SELECT 1 FROM livestock WHERE livestock_code='SL-2024-048');

INSERT INTO contact_traces (farm_id, from_livestock_id, to_livestock_id, proximity_meters, contact_duration_minutes, last_contact_at)
SELECT 1,
    (SELECT id FROM livestock WHERE livestock_code='SL-2024-049'),
    (SELECT id FROM livestock WHERE livestock_code='SL-2024-050'),
    4.0 + random() * 4.0, 180, '2026-04-08 11:00:00'
WHERE EXISTS (SELECT 1 FROM livestock WHERE livestock_code='SL-2024-049');

-- Grazing zone contacts
INSERT INTO contact_traces (farm_id, from_livestock_id, to_livestock_id, proximity_meters, contact_duration_minutes, last_contact_at)
SELECT 1, ls1.id, ls2.id,
    2.0 + random() * 8.0,
    30 + (random() * 150)::int,
    '2026-04-08 14:00:00'
FROM livestock ls1
JOIN livestock ls2 ON ls1.id < ls2.id AND ls1.farm_id = ls2.farm_id
WHERE ls1.farm_id = 1
  AND ls1.livestock_code IN ('SL-2024-001','SL-2024-003','SL-2024-005','SL-2024-012')
  AND ls2.livestock_code IN ('SL-2024-002','SL-2024-004','SL-2024-010','SL-2024-017')
  AND ls1.deleted_at IS NULL AND ls2.deleted_at IS NULL
LIMIT 6;

-- ============================================================
-- 7. Update livestock health_status
-- ============================================================
UPDATE livestock SET health_status = 'WARNING', updated_at = NOW() WHERE livestock_code = 'SL-2024-012' AND farm_id = 1;
UPDATE livestock SET health_status = 'CRITICAL', updated_at = NOW() WHERE livestock_code = 'SL-2024-048' AND farm_id = 1;

-- Cleanup
DROP TABLE capsule_map;
DROP TABLE gps_map;

-- Reset sequences
SELECT setval('estrus_scores_id_seq', (SELECT COALESCE(MAX(id), 1) FROM estrus_scores));
SELECT setval('health_snapshots_id_seq', (SELECT COALESCE(MAX(id), 1) FROM health_snapshots));
SELECT setval('contact_traces_id_seq', (SELECT COALESCE(MAX(id), 1) FROM contact_traces));
