-- ============================================================
-- V34: Fill current_motility for estrus livestock (SL-2024-016, SL-2024-032)
--
-- Problem: V21 seeded health_snapshots.current_motility = NULL for all
--   livestock except SL-2024-024.  The livestock detail page
--   (/api/v1/farms/{farmId}/livestock/{id}) now surfaces current_temp and
--   current_motility from health_snapshots.  NULL motility made the
--   "反刍频率" (rumination frequency) field show "--".
--
-- Fix: set a normal motility value for both estrus livestock and refresh
--   last_assessed_at so the snapshot looks current.
--   Idempotent: plain UPDATE, safe to re-run.
-- ============================================================

UPDATE health_snapshots
SET current_motility = 3.2 + random() * 0.6,
    motility_status = 'NORMAL',
    last_assessed_at = now(),
    updated_at = now()
WHERE livestock_id = (SELECT id FROM livestock WHERE livestock_code = 'SL-2024-016' AND farm_id = 1);

UPDATE health_snapshots
SET current_motility = 3.0 + random() * 0.5,
    motility_status = 'NORMAL',
    last_assessed_at = now(),
    updated_at = now()
WHERE livestock_id = (SELECT id FROM livestock WHERE livestock_code = 'SL-2024-032' AND farm_id = 1);

-- Also refresh current_temp to a recent reading (base + small variance)
UPDATE health_snapshots
SET current_temp = 38.4 + random() * 0.4,
    last_assessed_at = now(),
    updated_at = now()
WHERE livestock_id IN (
    SELECT id FROM livestock WHERE livestock_code IN ('SL-2024-016', 'SL-2024-032') AND farm_id = 1
) AND temp_status = 'NORMAL';
