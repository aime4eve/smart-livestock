-- Keep the outbox source aligned with the Java TelemetrySource enum. An
-- invalid value otherwise becomes a poison task that cannot be loaded or
-- moved to FAILED by the worker.
ALTER TABLE gps_ingestion_tasks
    DROP CONSTRAINT IF EXISTS chk_gps_ingestion_tasks_source;

ALTER TABLE gps_ingestion_tasks
    ADD CONSTRAINT chk_gps_ingestion_tasks_source
    CHECK (source IN ('AGENTIC_PLATFORM', 'DATAGEN', 'HTTP', 'MANUAL_IMPORT'));
