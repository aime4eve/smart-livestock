-- ============================================================
-- Add serial_no column to devices + unify runtime_status length
-- ============================================================

-- New column: device serial number (blade license query parameter)
ALTER TABLE devices ADD COLUMN IF NOT EXISTS serial_no VARCHAR(128);

-- Unify runtime_status column length to VARCHAR(30)
-- History: dev env deployed early (Jul 9) when migration file had VARCHAR(20);
-- test env deployed later (Jul 13) when file already had VARCHAR(30).
-- Flyway does not re-run executed migrations, leaving dev at VARCHAR(20).
ALTER TABLE devices ALTER COLUMN runtime_status TYPE VARCHAR(30);
