-- Preserve the firmware's cumulative gastric motility counter and its per-report
-- positive delta. Real channel rows must not masquerade as validated frequency.
ALTER TABLE device_telemetry_logs
    ADD COLUMN IF NOT EXISTS gastric_motility BIGINT;

ALTER TABLE rumen_motility_logs
    ADD COLUMN IF NOT EXISTS raw_counter BIGINT,
    ADD COLUMN IF NOT EXISTS counter_delta BIGINT;

ALTER TABLE rumen_motility_logs
    ALTER COLUMN frequency DROP NOT NULL,
    ALTER COLUMN intensity DROP NOT NULL;

CREATE INDEX IF NOT EXISTS idx_dtl_gastric_time
    ON device_telemetry_logs(device_id, report_time DESC)
    WHERE gastric_motility IS NOT NULL;

-- Recover the firmware counter from the old temporary /100000 mapping.
UPDATE rumen_motility_logs
SET raw_counter = ROUND(frequency * 100000)
WHERE source IN ('AGENTIC_PLATFORM', 'THINGSBOARD', 'MANUAL_IMPORT')
  AND frequency IS NOT NULL;

UPDATE rumen_motility_logs
SET frequency = NULL,
    intensity = NULL
WHERE source IN ('AGENTIC_PLATFORM', 'THINGSBOARD', 'MANUAL_IMPORT')
  AND raw_counter IS NOT NULL;

-- Backfill operational telemetry so the next live report has a counter baseline.
UPDATE device_telemetry_logs d
SET gastric_motility = (
    SELECT r.raw_counter
    FROM rumen_motility_logs r
    WHERE r.device_id = d.device_id
      AND r.recorded_at = d.report_time
      AND r.source = d.source
    ORDER BY r.id DESC
    LIMIT 1
)
WHERE d.source IN ('AGENTIC_PLATFORM', 'THINGSBOARD', 'MANUAL_IMPORT');

WITH ordered AS (
    SELECT id, raw_counter,
           LAG(raw_counter) OVER (
               PARTITION BY device_id ORDER BY recorded_at, source
           ) AS previous_counter
    FROM rumen_motility_logs
    WHERE raw_counter IS NOT NULL
)
UPDATE rumen_motility_logs r
SET counter_delta = ordered.raw_counter - ordered.previous_counter
FROM ordered
WHERE r.id = ordered.id
  AND ordered.raw_counter > ordered.previous_counter;

-- Real-counter rows no longer represent a validated frequency. If the latest
-- motility row is such a row, remove the synthetic snapshot judgment while
-- retaining the existing NORMAL default required by the schema.
WITH latest AS (
    SELECT DISTINCT ON (livestock_id)
           livestock_id, frequency
    FROM rumen_motility_logs
    WHERE livestock_id IS NOT NULL
    ORDER BY livestock_id, recorded_at DESC, id DESC
)
UPDATE health_snapshots s
SET current_motility = NULL,
    motility_status = 'NORMAL'
FROM latest l
WHERE s.livestock_id = l.livestock_id
  AND l.frequency IS NULL;
