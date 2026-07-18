-- NIX-21: Ensure dev_eui is unique within a tenant
-- Prevents duplicate device records from batch import failures
CREATE UNIQUE INDEX IF NOT EXISTS uq_devices_eui_tenant
    ON devices(dev_eui, tenant_id)
    WHERE dev_eui IS NOT NULL;
