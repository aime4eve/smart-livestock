-- GPS quality checks: bound legacy open-ended windows.
--
-- Manual creation used to allow a NULL ended_at; report generation then fell
-- back to "now + 8h" as the upper bound, so every view re-scanned (and
-- returned) the device's entire history since started_at — the payload grew
-- forever as live syncs added points. Creation now requires ended_at, and
-- report generation caps open windows at the device's last point + 8h, but
-- the persisted ended_at stays the canonical bound: give every test that is
-- still open its last known GPS point as the end (fallback: start + 1h so a
-- data-less test keeps a small non-empty window).

UPDATE gps_quality_tests t
SET ended_at = COALESCE((
        SELECT max(gl.recorded_at)
        FROM gps_logs gl
        WHERE gl.device_id = t.device_id
          AND gl.recorded_at >= t.started_at
    ), t.started_at + interval '1 hour')
WHERE t.ended_at IS NULL;
