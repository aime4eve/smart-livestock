-- ============================================================
-- V28: Fix SL-2024-017 health snapshot temperature.
-- In V21, current_temp for SL-2024-017 fell through to the ELSE branch
-- (38.2 + random * 0.8 = 38.2-39.0) while temp_status was set to ELEVATED,
-- making the snapshot internally inconsistent (delta < 1.0 should be NORMAL).
-- Set explicit 39.60 so delta = 1.1 matches ELEVATED per FeverAnalysisService rules.
-- V21 already applied in deployed DBs, so this corrective UPDATE is needed.
-- ============================================================

UPDATE health_snapshots
SET current_temp = 39.60,
    updated_at = now()
WHERE livestock_id = (
    SELECT id FROM livestock WHERE livestock_code = 'SL-2024-017' AND farm_id = 1
)
AND EXISTS (SELECT 1 FROM livestock WHERE livestock_code = 'SL-2024-017' AND farm_id = 1);
