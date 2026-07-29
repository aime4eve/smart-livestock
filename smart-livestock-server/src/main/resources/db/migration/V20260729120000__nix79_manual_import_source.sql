-- NIX-79: add source column to gps_logs + device_telemetry_logs (lesson #11:
-- multiple writers into one table must carry a source marker).
-- Existing rows default to AGENTIC_PLATFORM (the dominant historical writer;
-- dev datagen rows being mislabeled is acceptable, no reliable discriminator).
-- device_telemetry_logs is a partitioned table: ADD COLUMN / CHECK propagate
-- to partitions; PG 11+ fast default avoids a table rewrite.
ALTER TABLE gps_logs
  ADD COLUMN IF NOT EXISTS source VARCHAR(20) NOT NULL DEFAULT 'AGENTIC_PLATFORM';
ALTER TABLE gps_logs
  ADD CONSTRAINT chk_gps_logs_source
  CHECK (source IN ('AGENTIC_PLATFORM','DATAGEN','HTTP','MANUAL_IMPORT'));

ALTER TABLE device_telemetry_logs
  ADD COLUMN IF NOT EXISTS source VARCHAR(20) NOT NULL DEFAULT 'AGENTIC_PLATFORM';
ALTER TABLE device_telemetry_logs
  ADD CONSTRAINT chk_dtl_source
  CHECK (source IN ('AGENTIC_PLATFORM','DATAGEN','HTTP','MANUAL_IMPORT'));
