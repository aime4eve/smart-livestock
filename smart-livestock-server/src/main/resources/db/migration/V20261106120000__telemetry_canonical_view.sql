-- NIX-369: canonical telemetry read model for business statistics.
--
-- device_telemetry_logs is multi-source by design:
--   * AGENTIC_PLATFORM (agent-platform sync) and THINGSBOARD (TB direct
--     channel) both persist the same physical frame as two rows with
--     millisecond-differing report_time, so the (device_id, report_time)
--     unique index cannot catch them;
--   * DATAGEN rows are intentional AI-training data (never clean them up)
--     but must never leak into business statistics.
--
-- Canonical rule: exclude DATAGEN, keep one row per
-- (device_id, second-truncated report_time), source priority
-- AGENTIC_PLATFORM > THINGSBOARD > HTTP > MANUAL_IMPORT.
--
-- Switched statistics queries live in SpringDataDeviceTelemetryLogRepository.
-- Deliberate NON-readers of this view (keep hitting the base table):
--   * write-path idempotency (existsByDeviceIdAndReportTime) — must see all rows
--   * link diagnostics (recentLinkQualityRow) — keep every reception path's
--     radio observations
--   * latest-value queries, import/export dedup prechecks, partition/retention
--     maintenance, DATAGEN management, AI training reads
--
-- Helper columns beyond the base table: sec (dedup second) and prio (source
-- priority used by DISTINCT ON). Exposed for observability; ignore them.
--
-- NOTE: Postgres snapshots the view column list at CREATE time; a future
-- ALTER TABLE ... ADD COLUMN on the base table needs a follow-up
-- CREATE OR REPLACE VIEW migration.

CREATE OR REPLACE VIEW v_telemetry_canonical AS
SELECT DISTINCT ON (device_id, sec)
       s.*
FROM (
    SELECT t.*,
           date_trunc('second', t.report_time) AS sec,
           CASE t.source
               WHEN 'AGENTIC_PLATFORM' THEN 0
               WHEN 'THINGSBOARD' THEN 1
               WHEN 'HTTP' THEN 2
               ELSE 3
           END AS prio
    FROM device_telemetry_logs t
    WHERE t.source <> 'DATAGEN'
) s
ORDER BY device_id, sec, prio, id;
