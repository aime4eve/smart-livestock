-- ============================================================
-- V32: Fix rumen_motility_logs — fill the missing 0-24h window for SL-024 and SL-036
--
-- Problem: V31 generated motility data for SL-024 and SL-036 using
--   generate_series(now() - 72h, now() - 24h, ...)
-- The most recent data point was exactly 24h ago, so the detail-page query
--   WHERE recorded_at BETWEEN now()-24h AND now()
-- returned an empty list → the "rumen motility frequency" chart was blank.
--
-- Fix: insert the missing 0-24h window (48 rows per livestock at 30-min intervals).
-- Idempotent: skips rows that already exist within the window.
-- ============================================================

-- SL-2024-024 ABNORMAL: frequency 0.8-1.4, intensity 25-40
INSERT INTO rumen_motility_logs (livestock_id, device_id, frequency, intensity, recorded_at)
SELECT ls.id, 56, 0.8 + random() * 0.6, 25.0 + random() * 15.0, ts
FROM livestock ls
CROSS JOIN (
    SELECT generate_series(
        now() - interval '24 hours',
        now(),
        '30 minutes'::interval
    ) AS ts
) s
WHERE ls.livestock_code = 'SL-2024-024' AND ls.farm_id = 1 AND ls.deleted_at IS NULL
  AND NOT EXISTS (
      SELECT 1 FROM rumen_motility_logs rml
      WHERE rml.livestock_id = ls.id
        AND rml.recorded_at >= now() - interval '24 hours'
  );

-- SL-2024-036 LOW: frequency 1.6-2.0, intensity 30-50
INSERT INTO rumen_motility_logs (livestock_id, device_id, frequency, intensity, recorded_at)
SELECT ls.id, 59, 1.6 + random() * 0.4, 30.0 + random() * 20.0, ts
FROM livestock ls
CROSS JOIN (
    SELECT generate_series(
        now() - interval '24 hours',
        now(),
        '30 minutes'::interval
    ) AS ts
) s
WHERE ls.livestock_code = 'SL-2024-036' AND ls.farm_id = 1 AND ls.deleted_at IS NULL
  AND NOT EXISTS (
      SELECT 1 FROM rumen_motility_logs rml
      WHERE rml.livestock_id = ls.id
        AND rml.recorded_at >= now() - interval '24 hours'
  );
