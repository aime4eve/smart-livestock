-- Health time series can be produced before a device is installed on livestock.
-- Keep device_id as the attribution key; livestock_id is filled only after binding.
ALTER TABLE temperature_logs ALTER COLUMN livestock_id DROP NOT NULL;
ALTER TABLE rumen_motility_logs ALTER COLUMN livestock_id DROP NOT NULL;
ALTER TABLE activity_logs ALTER COLUMN livestock_id DROP NOT NULL;

CREATE INDEX IF NOT EXISTS idx_rumen_motility_logs_device_time
    ON rumen_motility_logs(device_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_logs_device_time
    ON activity_logs(device_id, recorded_at DESC);
