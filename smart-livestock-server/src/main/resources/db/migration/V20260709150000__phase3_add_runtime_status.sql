-- V20260709150000: phase3 add runtime status columns to devices table
-- (reconstructed from deployed state — original was deployed but not committed)
ALTER TABLE devices ADD COLUMN IF NOT EXISTS runtime_status VARCHAR(30);
ALTER TABLE devices ADD COLUMN IF NOT EXISTS platform_device_id BIGINT;
ALTER TABLE devices ADD COLUMN IF NOT EXISTS rssi INTEGER;
ALTER TABLE devices ADD COLUMN IF NOT EXISTS snr DECIMAL(6,2);
ALTER TABLE devices ADD COLUMN IF NOT EXISTS last_gateway VARCHAR(100);
ALTER TABLE devices ADD COLUMN IF NOT EXISTS anti_disassembly_status INTEGER;
ALTER TABLE devices ADD COLUMN IF NOT EXISTS software_version VARCHAR(50);
ALTER TABLE devices ADD COLUMN IF NOT EXISTS hardware_version VARCHAR(50);
ALTER TABLE devices ADD COLUMN IF NOT EXISTS work_mode VARCHAR(20);
ALTER TABLE devices ADD COLUMN IF NOT EXISTS last_telemetry_synced_at TIMESTAMP;
