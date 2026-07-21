-- Legacy data governance (spec v3.2 section 8):
-- Reset DECOMMISSIONED devices that never completed platform registration back to INVENTORY
-- (they never actually connected to the platform, so INVENTORY is semantically more accurate).
-- Historical gps_logs / telemetry / quality tests are linked by device_id and unaffected by the status reset.
UPDATE devices SET status = 'INVENTORY', updated_at = NOW()
WHERE status = 'DECOMMISSIONED' AND platform_device_id IS NULL AND deleted_at IS NULL;
