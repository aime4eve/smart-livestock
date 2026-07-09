-- ============================================================
-- Phase 3: Update demo devices with agentic-middle-platform linkage
-- Links demo TRACKER devices to real platform device IDs
-- ============================================================

-- Link first two demo TRACKER devices to real platform devices (from PoC verification)
UPDATE devices SET platform_device_id = 2072879090955759616 WHERE id = 1;
UPDATE devices SET platform_device_id = 2072879090955759618 WHERE id = 2;

-- Add operational metrics to demo ACTIVE devices for health score demonstration
UPDATE devices
SET rssi = -55, snr = 11.5, last_gateway = 'GW-DEMO-01',
    anti_disassembly_status = 0, software_version = '1.2.0', hardware_version = 'V2.1'
WHERE id IN (1, 2);

-- Add dev_eui to the two linked devices (matching real platform deviceIdentifier)
UPDATE devices SET dev_eui = '0095690600028ea6' WHERE id = 1 AND (dev_eui IS NULL OR dev_eui = '');
UPDATE devices SET dev_eui = '0095690600028600' WHERE id = 2 AND (dev_eui IS NULL OR dev_eui = '');
