-- NIX ruling 2026-10-12: device EUI is a globally unique code (LoRaWAN DevEUI).
-- Tenant-scoped uniqueness allowed the same physical device to be registered
-- under two tenants; ownership must stay 1:1 (a tenant only sees devices
-- registered to it, collection is by EUI through the shared TB tenant).
-- Soft-deleted rows keep occupying their EUI: revive/matching semantics
-- (findAllByDevEui*IncludeDeleted) treat the EUI as still claimed.
-- Pre-checked on dev (56/56) and test (216/216): zero duplicate EUIs incl. soft-deleted.

DROP INDEX IF EXISTS uq_devices_eui_tenant;

CREATE UNIQUE INDEX IF NOT EXISTS uq_devices_eui_global
    ON devices(dev_eui)
    WHERE dev_eui IS NOT NULL;
