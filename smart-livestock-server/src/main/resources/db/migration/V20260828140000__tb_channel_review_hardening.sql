-- NIX-179 review hardening: keep DB source/status domains in sync with the
-- ThingsBoard channel and its downstream event consumers.
ALTER TABLE tb_device_bindings
  ADD CONSTRAINT chk_tb_bindings_status
  CHECK (binding_status IN ('PENDING', 'RESOLVED', 'INVALID'));

ALTER TABLE temperature_logs DROP CONSTRAINT chk_temperature_logs_source;
ALTER TABLE temperature_logs
  ADD CONSTRAINT chk_temperature_logs_source
  CHECK (source IN ('AGENTIC_PLATFORM','THINGSBOARD','DATAGEN','HTTP','MANUAL_IMPORT','UNKNOWN'));

ALTER TABLE rumen_motility_logs DROP CONSTRAINT chk_rumen_motility_logs_source;
ALTER TABLE rumen_motility_logs
  ADD CONSTRAINT chk_rumen_motility_logs_source
  CHECK (source IN ('AGENTIC_PLATFORM','THINGSBOARD','DATAGEN','HTTP','MANUAL_IMPORT','UNKNOWN'));

ALTER TABLE activity_logs DROP CONSTRAINT chk_activity_logs_source;
ALTER TABLE activity_logs
  ADD CONSTRAINT chk_activity_logs_source
  CHECK (source IN ('AGENTIC_PLATFORM','THINGSBOARD','DATAGEN','HTTP','MANUAL_IMPORT','UNKNOWN'));

ALTER TABLE estrus_scores DROP CONSTRAINT chk_estrus_scores_source;
ALTER TABLE estrus_scores
  ADD CONSTRAINT chk_estrus_scores_source
  CHECK (source IN ('AGENTIC_PLATFORM','THINGSBOARD','DATAGEN','HTTP','MANUAL_IMPORT','UNKNOWN'));
