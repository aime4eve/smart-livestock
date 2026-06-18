-- ============================================================
-- V35: Seed normal temperature_logs for estrus livestock (SL-2024-016, SL-2024-032)
--
-- Problem: V31 only seeded temperature_logs for ABNORMAL livestock (048/012/003/004).
--   SL-016 and SL-032 have no temperature_logs, so the fever detail API returns
--   an empty recent72h list and the temperature-trend chart is blank.
--
-- Fix: insert 72h of normal temperature readings (38.0-38.9°C) at 30-min
--   intervals for both estrus livestock using their capsule device IDs.
--   Idempotent: skips if rows already exist in the 72h window.
-- ============================================================

-- SL-2024-016 (capsule dev=54)
INSERT INTO temperature_logs (livestock_id, device_id, temperature, baseline_temp, recorded_at)
SELECT ls.id, 54, 38.0 + random() * 0.9, 38.50, ts
FROM livestock ls
CROSS JOIN (
    SELECT generate_series(now() - interval '72 hours', now(), '30 minutes'::interval) AS ts
) s
WHERE ls.livestock_code = 'SL-2024-016' AND ls.farm_id = 1 AND ls.deleted_at IS NULL
  AND NOT EXISTS (
      SELECT 1 FROM temperature_logs tl
      WHERE tl.livestock_id = ls.id
        AND tl.recorded_at >= now() - interval '72 hours'
  );

-- SL-2024-032 (capsule dev=58)
INSERT INTO temperature_logs (livestock_id, device_id, temperature, baseline_temp, recorded_at)
SELECT ls.id, 58, 38.0 + random() * 0.9, 38.50, ts
FROM livestock ls
CROSS JOIN (
    SELECT generate_series(now() - interval '72 hours', now(), '30 minutes'::interval) AS ts
) s
WHERE ls.livestock_code = 'SL-2024-032' AND ls.farm_id = 1 AND ls.deleted_at IS NULL
  AND NOT EXISTS (
      SELECT 1 FROM temperature_logs tl
      WHERE tl.livestock_id = ls.id
        AND tl.recorded_at >= now() - interval '72 hours'
  );
