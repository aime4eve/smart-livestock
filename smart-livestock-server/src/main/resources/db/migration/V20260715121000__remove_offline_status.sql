-- ============================================================
-- Remove OFFLINE from device status enum
-- Online/offline is now expressed by runtimeStatus, not status.
-- ============================================================

-- 1. Migrate existing OFFLINE devices to ACTIVE
--    (runtime online/offline will be determined by blade onlineStatus via runtimeStatus)
UPDATE devices SET status = 'ACTIVE' WHERE status = 'OFFLINE';

-- 2. Drop all status-related CHECK constraints (name may vary by PG version)
DO $$
DECLARE
    con_name text;
BEGIN
    FOR con_name IN
        SELECT conname FROM pg_constraint
        WHERE conrelid = 'devices'::regclass AND contype = 'c'
          AND pg_get_constraintdef(oid) ILIKE '%status%'
    LOOP
        EXECUTE 'ALTER TABLE devices DROP CONSTRAINT IF EXISTS ' || con_name;
    END LOOP;
END $$;

-- 3. Recreate constraint without OFFLINE
ALTER TABLE devices ADD CONSTRAINT chk_devices_status
    CHECK (status IN ('INVENTORY', 'ACTIVE', 'DECOMMISSIONED'));
