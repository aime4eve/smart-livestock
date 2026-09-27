-- Signal API requires a credible recorded time for every current metric value.

WITH targets AS (
    SELECT livestock_id, current_temp
    FROM health_snapshots
    WHERE current_temp IS NOT NULL
      AND (current_temp_recorded_at IS NULL OR current_temp_source IS NULL)
),
matches AS (
    SELECT
        targets.livestock_id,
        tl.recorded_at,
        CASE
            WHEN tl.source IN ('AGENTIC_PLATFORM', 'THINGSBOARD', 'DATAGEN', 'HTTP', 'MANUAL_IMPORT')
                THEN tl.source
            ELSE NULL
        END AS source
    FROM targets
    CROSS JOIN LATERAL (
        SELECT recorded_at, source
        FROM temperature_logs tl
        WHERE tl.livestock_id = targets.livestock_id
          AND tl.temperature = targets.current_temp
          AND tl.temperature BETWEEN 20 AND 45
          AND tl.recorded_at <= NOW()
        ORDER BY tl.recorded_at DESC
        LIMIT 1
    ) tl
)
UPDATE health_snapshots AS hs
SET current_temp_recorded_at = matches.recorded_at,
    current_temp_source = matches.source
FROM matches
WHERE hs.livestock_id = matches.livestock_id;

WITH targets AS (
    SELECT livestock_id, current_motility
    FROM health_snapshots
    WHERE current_motility IS NOT NULL
      AND (current_motility_recorded_at IS NULL OR current_motility_source IS NULL)
),
matches AS (
    SELECT
        targets.livestock_id,
        rml.recorded_at,
        CASE
            WHEN rml.source IN ('AGENTIC_PLATFORM', 'THINGSBOARD', 'DATAGEN', 'HTTP', 'MANUAL_IMPORT')
                THEN rml.source
            ELSE NULL
        END AS source
    FROM targets
    CROSS JOIN LATERAL (
        SELECT recorded_at, source
        FROM rumen_motility_logs rml
        WHERE rml.livestock_id = targets.livestock_id
          AND rml.frequency = targets.current_motility
          AND rml.frequency IS NOT NULL
          AND rml.recorded_at <= NOW()
        ORDER BY rml.recorded_at DESC
        LIMIT 1
    ) rml
)
UPDATE health_snapshots AS hs
SET current_motility_recorded_at = matches.recorded_at,
    current_motility_source = matches.source
FROM matches
WHERE hs.livestock_id = matches.livestock_id;
