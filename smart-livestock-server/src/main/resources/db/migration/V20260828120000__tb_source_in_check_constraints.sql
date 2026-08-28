-- NIX-179: allow source='THINGSBOARD' in telemetry tables. The Phase 1
-- source enum grew (TelemetrySource.THINGSBOARD); the DB-side CHECK
-- whitelists must stay in sync with it (source columns added in V20260729120000).
ALTER TABLE device_telemetry_logs DROP CONSTRAINT chk_dtl_source;
ALTER TABLE device_telemetry_logs
  ADD CONSTRAINT chk_dtl_source
  CHECK (source IN ('AGENTIC_PLATFORM','THINGSBOARD','DATAGEN','HTTP','MANUAL_IMPORT'));

ALTER TABLE gps_logs DROP CONSTRAINT chk_gps_logs_source;
ALTER TABLE gps_logs
  ADD CONSTRAINT chk_gps_logs_source
  CHECK (source IN ('AGENTIC_PLATFORM','THINGSBOARD','DATAGEN','HTTP','MANUAL_IMPORT'));
