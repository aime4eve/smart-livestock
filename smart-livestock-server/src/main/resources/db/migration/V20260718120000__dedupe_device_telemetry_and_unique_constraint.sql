-- Remove exact-duplicate rows in device_telemetry_logs so that each
-- (device_id, report_time) pair appears exactly once, then enforce that
-- invariant with a unique index on the partitioned table.
--
-- Background: telemetry ingestion has no idempotency guard, so retries /
-- concurrent sync workers produced up to hundreds of thousands of identical
-- rows for a single (device_id, report_time). Any join against this table
-- (e.g. GPS quality comparison) then exploded the result set and timed out.
--
-- The partition key is report_time, and (device_id, report_time) includes it,
-- so a UNIQUE index on (device_id, report_time) is valid on the partitioned table.

-- 1. For every (device_id, report_time) group with more than one row, delete all
--    but the row with the smallest id (the first-inserted copy). Driven by the
--    small duplicate-group set (~hundreds) so it uses the (device_id, report_time)
--    index instead of an O(n^2) self-join.
DELETE FROM device_telemetry_logs
WHERE (device_id, report_time) IN (
    SELECT device_id, report_time
    FROM device_telemetry_logs
    GROUP BY device_id, report_time
    HAVING count(*) > 1
)
AND id NOT IN (
    SELECT min(id)
    FROM device_telemetry_logs
    GROUP BY device_id, report_time
    HAVING count(*) > 1
);

-- 2. Enforce the invariant going forward. The index must include report_time
--    (the partition key) to be valid on the partitioned parent table.
CREATE UNIQUE INDEX IF NOT EXISTS uq_dtl_device_report_time
    ON device_telemetry_logs (device_id, report_time);
