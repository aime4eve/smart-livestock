-- Device soft delete: convert unique constraints to partial indexes (active rows only).
-- Follows the livestock V2 precedent: uniqueness only constrains non-deleted rows.

-- device_code: column-level constraint -> partial unique index
-- (constraint name devices_device_code_key is PG default; verify on dev/test before deploy)
ALTER TABLE devices DROP CONSTRAINT IF EXISTS devices_device_code_key;
CREATE UNIQUE INDEX uq_devices_code_active ON devices(device_code) WHERE deleted_at IS NULL;

-- dev_eui + tenant: rebuild with deleted_at filter
DROP INDEX IF EXISTS uq_devices_eui_tenant;
CREATE UNIQUE INDEX uq_devices_eui_tenant ON devices(dev_eui, tenant_id)
    WHERE dev_eui IS NOT NULL AND deleted_at IS NULL;

-- platform_device_id: rebuild with deleted_at filter
DROP INDEX IF EXISTS idx_devices_platform_device_id;
CREATE UNIQUE INDEX idx_devices_platform_device_id ON devices(platform_device_id)
    WHERE platform_device_id IS NOT NULL AND deleted_at IS NULL;
