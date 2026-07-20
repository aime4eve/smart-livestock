-- Remove exact-duplicate rows in gps_logs so that each (device_id, recorded_at)
-- pair appears exactly once, then enforce that invariant with a unique index.
--
-- Background: TelemetryIngestionService.logGps() unconditionally INSERTs every
-- frame it receives. When the agentic-platform sync cursor is null or stale
-- (first sync, cursor reset), AgenticPlatformTelemetrySyncJob re-pulls the whole
-- history and re-inserts every frame, producing up to hundreds of thousands of
-- identical rows for a single (device_id, recorded_at). GPS quality reports then
-- counted the same second thousands of times (e.g. device 125 @ RTK-26 showed
-- ~98813 "effective" points that were really ~219 unique timestamps).
--
-- (1) dedupes existing data; (2) enforces uniqueness; the application layer is
-- changed in parallel to INSERT ... ON CONFLICT so re-syncs become idempotent.

-- 1. For every (device_id, recorded_at) group with more than one row, delete all
--    but the row with the smallest id (the first-inserted copy).
DELETE FROM gps_logs
WHERE (device_id, recorded_at) IN (
    SELECT device_id, recorded_at
    FROM gps_logs
    GROUP BY device_id, recorded_at
    HAVING count(*) > 1
)
AND id NOT IN (
    SELECT min(id)
    FROM gps_logs
    GROUP BY device_id, recorded_at
    HAVING count(*) > 1
);

-- 2. Enforce the invariant going forward.
CREATE UNIQUE INDEX IF NOT EXISTS uq_gps_logs_device_recorded_at
    ON gps_logs (device_id, recorded_at);
