-- ============================================================
-- V33: Fix estrus activity comparison — recent 24h must exceed baseline 24-48h
--
-- Problem: V31 seeded activity_logs for SL-2024-016 and SL-2024-032 with a
--   uniform day/night pattern across the full 7-day window.  The detail-page
--   query compares recent (now-24h) vs older (now-48h .. now-24h), and since
--   both windows share the same distribution, random variance made recent
--   LOWER than baseline — the opposite of what an estrus spike should show.
--
-- Fix: replace the last 48h of activity_logs for both estrus livestock so that
--   the recent 24h window (estrus peak) is ~120% higher than the prior 24h.
--   This aligns the activity-comparison bar chart with the estrus score and
--   the "step increase +120%" metric on the detail page.
--
-- Idempotent: deletes then re-inserts the 48h window, safe to re-run.
-- ============================================================

-- ── SL-2024-016 (score 92, step increase +120%) ──────────────

DELETE FROM activity_logs
WHERE livestock_id = (SELECT id FROM livestock WHERE livestock_code = 'SL-2024-016' AND farm_id = 1)
  AND recorded_at >= now() - interval '48 hours';

-- Baseline window: 24-48h ago — normal activity
INSERT INTO activity_logs (livestock_id, device_id, step_count, activity_index, distance_meters, recorded_at)
SELECT
    ls.id,
    (SELECT inst.device_id FROM installations inst
     JOIN livestock ls2 ON ls2.id = inst.livestock_id
     WHERE ls2.livestock_code = 'SL-2024-016' AND inst.removed_at IS NULL
       AND inst.device_id IN (SELECT id FROM devices WHERE device_type = 'TRACKER') LIMIT 1),
    CASE WHEN EXTRACT(HOUR FROM ts) BETWEEN 6 AND 20 THEN 1800 + (random() * 800)::int ELSE 80 + (random() * 200)::int END,
    CASE WHEN EXTRACT(HOUR FROM ts) BETWEEN 6 AND 20 THEN 50.0 + random() * 20.0 ELSE 8.0 + random() * 12.0 END,
    CASE WHEN EXTRACT(HOUR FROM ts) BETWEEN 6 AND 20 THEN 1000.0 + random() * 500.0 ELSE 15.0 + random() * 30.0 END,
    ts
FROM livestock ls
CROSS JOIN (
    SELECT generate_series(now() - interval '48 hours', now() - interval '24 hours', '1 hour'::interval) AS ts
) s
WHERE ls.livestock_code = 'SL-2024-016' AND ls.farm_id = 1 AND ls.deleted_at IS NULL;

-- Recent window: 0-24h ago — estrus peak (~120% higher than baseline)
INSERT INTO activity_logs (livestock_id, device_id, step_count, activity_index, distance_meters, recorded_at)
SELECT
    ls.id,
    (SELECT inst.device_id FROM installations inst
     JOIN livestock ls2 ON ls2.id = inst.livestock_id
     WHERE ls2.livestock_code = 'SL-2024-016' AND inst.removed_at IS NULL
       AND inst.device_id IN (SELECT id FROM devices WHERE device_type = 'TRACKER') LIMIT 1),
    CASE WHEN EXTRACT(HOUR FROM ts) BETWEEN 6 AND 20 THEN 4200 + (random() * 1800)::int ELSE 200 + (random() * 400)::int END,
    CASE WHEN EXTRACT(HOUR FROM ts) BETWEEN 6 AND 20 THEN 110.0 + random() * 40.0 ELSE 20.0 + random() * 30.0 END,
    CASE WHEN EXTRACT(HOUR FROM ts) BETWEEN 6 AND 20 THEN 2400.0 + random() * 1200.0 ELSE 40.0 + random() * 80.0 END,
    ts
FROM livestock ls
CROSS JOIN (
    SELECT generate_series(now() - interval '24 hours', now(), '1 hour'::interval) AS ts
) s
WHERE ls.livestock_code = 'SL-2024-016' AND ls.farm_id = 1 AND ls.deleted_at IS NULL;

-- ── SL-2024-032 (score 78, step increase +80%) ───────────────

DELETE FROM activity_logs
WHERE livestock_id = (SELECT id FROM livestock WHERE livestock_code = 'SL-2024-032' AND farm_id = 1)
  AND recorded_at >= now() - interval '48 hours';

-- Baseline window: 24-48h ago — normal activity
INSERT INTO activity_logs (livestock_id, device_id, step_count, activity_index, distance_meters, recorded_at)
SELECT
    ls.id,
    (SELECT inst.device_id FROM installations inst
     JOIN livestock ls2 ON ls2.id = inst.livestock_id
     WHERE ls2.livestock_code = 'SL-2024-032' AND inst.removed_at IS NULL
       AND inst.device_id IN (SELECT id FROM devices WHERE device_type = 'TRACKER') LIMIT 1),
    CASE WHEN EXTRACT(HOUR FROM ts) BETWEEN 6 AND 20 THEN 1500 + (random() * 700)::int ELSE 60 + (random() * 180)::int END,
    CASE WHEN EXTRACT(HOUR FROM ts) BETWEEN 6 AND 20 THEN 45.0 + random() * 20.0 ELSE 7.0 + random() * 10.0 END,
    CASE WHEN EXTRACT(HOUR FROM ts) BETWEEN 6 AND 20 THEN 850.0 + random() * 400.0 ELSE 12.0 + random() * 25.0 END,
    ts
FROM livestock ls
CROSS JOIN (
    SELECT generate_series(now() - interval '48 hours', now() - interval '24 hours', '1 hour'::interval) AS ts
) s
WHERE ls.livestock_code = 'SL-2024-032' AND ls.farm_id = 1 AND ls.deleted_at IS NULL;

-- Recent window: 0-24h ago — estrus peak (~80% higher than baseline)
INSERT INTO activity_logs (livestock_id, device_id, step_count, activity_index, distance_meters, recorded_at)
SELECT
    ls.id,
    (SELECT inst.device_id FROM installations inst
     JOIN livestock ls2 ON ls2.id = inst.livestock_id
     WHERE ls2.livestock_code = 'SL-2024-032' AND inst.removed_at IS NULL
       AND inst.device_id IN (SELECT id FROM devices WHERE device_type = 'TRACKER') LIMIT 1),
    CASE WHEN EXTRACT(HOUR FROM ts) BETWEEN 6 AND 20 THEN 2900 + (random() * 1200)::int ELSE 120 + (random() * 280)::int END,
    CASE WHEN EXTRACT(HOUR FROM ts) BETWEEN 6 AND 20 THEN 85.0 + random() * 30.0 ELSE 15.0 + random() * 20.0 END,
    CASE WHEN EXTRACT(HOUR FROM ts) BETWEEN 6 AND 20 THEN 1600.0 + random() * 700.0 ELSE 25.0 + random() * 50.0 END,
    ts
FROM livestock ls
CROSS JOIN (
    SELECT generate_series(now() - interval '24 hours', now(), '1 hour'::interval) AS ts
) s
WHERE ls.livestock_code = 'SL-2024-032' AND ls.farm_id = 1 AND ls.deleted_at IS NULL;
