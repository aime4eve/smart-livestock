-- Normalize device EUIs to lowercase: EUIs are case-insensitive identifiers.
-- Case-only duplicate EUIs within a tenant are legacy data issues and must be
-- resolved manually; fail loudly instead of silently merging devices.
DO $$
DECLARE
    conflict_count int;
BEGIN
    SELECT count(*) INTO conflict_count
    FROM (
        SELECT tenant_id, lower(dev_eui)
        FROM devices
        WHERE dev_eui IS NOT NULL AND deleted_at IS NULL
        GROUP BY tenant_id, lower(dev_eui)
        HAVING count(*) > 1
    ) collisions;
    IF conflict_count > 0 THEN
        RAISE EXCEPTION 'dev_eui lowercase collision in % tenant(s): case-only duplicate EUIs must be resolved manually before migrating', conflict_count;
    END IF;
END
$$;

UPDATE devices SET dev_eui = lower(dev_eui)
WHERE dev_eui IS NOT NULL AND dev_eui <> lower(dev_eui);

-- Keep soft-delete filtering semantics from V20260721100000; match on lower(dev_eui)
-- so future writes with mixed case cannot bypass uniqueness.
DROP INDEX IF EXISTS uq_devices_eui_tenant;
CREATE UNIQUE INDEX uq_devices_eui_tenant
    ON devices (lower(dev_eui), tenant_id)
    WHERE dev_eui IS NOT NULL AND deleted_at IS NULL;
