-- ============================================================
-- V20260710140000: Clean up invalid GPS logs (0,0) and stop datagen
-- ============================================================

-- 1. Delete all GPS logs with (0,0) coordinates (no GPS fix)
DELETE FROM gps_logs WHERE latitude = 0.0 AND longitude = 0.0;

-- 2. Stop all RUNNING synthesis scenarios (real telemetry replaces datagen)
UPDATE synthesis_scenarios SET status = 'STOPPED' WHERE status = 'RUNNING';
