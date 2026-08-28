-- NIX-179: gps_ingestion_tasks got its own source CHECK in V20260822210000;
-- extend it alongside the telemetry/gps fixes in V20260828120000.
ALTER TABLE gps_ingestion_tasks DROP CONSTRAINT chk_gps_ingestion_tasks_source;
ALTER TABLE gps_ingestion_tasks
  ADD CONSTRAINT chk_gps_ingestion_tasks_source
  CHECK (source IN ('AGENTIC_PLATFORM','THINGSBOARD','DATAGEN','HTTP','MANUAL_IMPORT'));
