-- ============================================================
-- V25: Fix Farm 1 coordinates + Remove ACCELEROMETER devices
-- ============================================================

-- 1. Fix Farm 1 coordinates to align with fence/livestock seed data
UPDATE farms SET latitude = 28.2290000, longitude = 112.9380000
WHERE id = 1 AND name = '主牧场';

-- 2. Delete installations referencing ACCELEROMETER devices (if any)
DELETE FROM installations
WHERE device_id IN (SELECT id FROM devices WHERE device_type = 'ACCELEROMETER');

-- 3. Revoke and delete ACCELEROMETER device licenses
UPDATE device_licenses SET status = 'REVOKED'
WHERE device_id IN (SELECT id FROM devices WHERE device_type = 'ACCELEROMETER')
  AND status != 'REVOKED';

DELETE FROM device_licenses
WHERE device_id IN (SELECT id FROM devices WHERE device_type = 'ACCELEROMETER');

-- 4. Delete ACCELEROMETER devices entirely
DELETE FROM devices WHERE device_type = 'ACCELEROMETER';

-- 5. Narrow the CHECK constraint to exclude ACCELEROMETER
ALTER TABLE devices DROP CONSTRAINT chk_devices_type;
ALTER TABLE devices ADD CONSTRAINT chk_devices_type
    CHECK (device_type IN ('EAR_TAG', 'TRACKER', 'CAPSULE'));
