-- ============================================================
-- Clean up low_battery from runtime_status
-- runtimeStatus now only has 'online' and 'offline' (from blade onlineStatus).
-- Existing 'low_battery' values were locally computed, migrate to 'offline'.
-- Next telemetry sync will overwrite with real blade onlineStatus.
-- ============================================================

UPDATE devices SET runtime_status = 'offline' WHERE runtime_status = 'low_battery';
