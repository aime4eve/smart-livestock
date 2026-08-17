-- Use derived tables for PostgreSQL/Flyway compatibility and cover both legacy fence formats.
UPDATE alerts alert
SET message_key = 'alert.fence.approach',
    message_args = parsed.args
FROM (
    SELECT id,
           jsonb_build_array(match[1], match[2], match[3], match[4])::text AS args
    FROM (
        SELECT id,
               regexp_match(
                       message,
                       '^牲畜 \\[(.*)\\] 接近围栏 \\[(.*)\\]，位置: \\(([^,]+), *(.*)\\)$'
               ) AS match
        FROM alerts
        WHERE message_key IS NULL
          AND type = 'FENCE_APPROACH'
    ) matched
    WHERE array_length(match, 1) = 4
) parsed
WHERE alert.id = parsed.id
  AND parsed.args IS NOT NULL
  AND alert.message_key IS NULL
;

UPDATE alerts alert
SET message_key = 'alert.fence.breach',
    message_args = parsed.args
FROM (
    SELECT id,
           jsonb_build_array(match[1], match[2], match[3], match[4])::text AS args
    FROM (
        SELECT id,
               regexp_match(
                       message,
                       '^牲畜 \\[(.*)\\] 越出围栏 \\[(.*)\\]，位置: \\(([^,]+), *(.*)\\)$'
               ) AS match
        FROM alerts
        WHERE message_key IS NULL
          AND type = 'FENCE_BREACH'
    ) matched
    WHERE array_length(match, 1) = 4
) parsed
WHERE alert.id = parsed.id
  AND parsed.args IS NOT NULL
  AND alert.message_key IS NULL
;
