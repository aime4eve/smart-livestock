-- ============================================================
-- V27: Insert recent motility logs so digestive detail chart is not empty.
-- Only for abnormal livestock (SL-2024-024) + one LOW livestock (SL-2024-036).
-- Uses now()-interval so data is always recent relative to deployment.
-- ============================================================

-- Abnormal: SL-2024-024 — frequency ~1.0 (well below baseline 3.0 × 0.5 = 1.5)
INSERT INTO rumen_motility_logs (livestock_id, device_id, frequency, intensity, recorded_at)
SELECT
    (SELECT id FROM livestock WHERE livestock_code = 'SL-2024-024' AND farm_id = 1),
    56,
    0.8 + random() * 0.6,
    25.0 + random() * 15.0,
    ts
FROM (
    SELECT generate_series(
        now() - interval '24 hours',
        now(),
        '30 minutes'::interval
    ) AS ts
) sub
WHERE EXISTS (SELECT 1 FROM livestock WHERE livestock_code = 'SL-2024-024' AND farm_id = 1);

-- LOW: SL-2024-036 — frequency ~2.0 (between baseline × 0.5=1.5 and × 0.7=2.1)
INSERT INTO rumen_motility_logs (livestock_id, device_id, frequency, intensity, recorded_at)
SELECT
    (SELECT id FROM livestock WHERE livestock_code = 'SL-2024-036' AND farm_id = 1),
    59,
    1.6 + random() * 0.4,
    30.0 + random() * 20.0,
    ts
FROM (
    SELECT generate_series(
        now() - interval '24 hours',
        now(),
        '30 minutes'::interval
    ) AS ts
) sub
WHERE EXISTS (SELECT 1 FROM livestock WHERE livestock_code = 'SL-2024-036' AND farm_id = 1);

-- Update health_snapshot for SL-2024-036 to LOW status
UPDATE health_snapshots
SET current_motility = 1.90,
    motility_status = 'LOW',
    last_assessed_at = now(),
    updated_at = now()
WHERE livestock_id = (SELECT id FROM livestock WHERE livestock_code = 'SL-2024-036' AND farm_id = 1)
  AND EXISTS (SELECT 1 FROM livestock WHERE livestock_code = 'SL-2024-036' AND farm_id = 1);

-- Refresh SL-2024-024 snapshot timestamp too
UPDATE health_snapshots
SET last_assessed_at = now(),
    updated_at = now()
WHERE livestock_id = (SELECT id FROM livestock WHERE livestock_code = 'SL-2024-024' AND farm_id = 1);
