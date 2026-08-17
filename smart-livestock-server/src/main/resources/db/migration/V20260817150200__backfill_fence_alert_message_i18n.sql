-- The initial backfill used non-greedy regex groups, which PostgreSQL regex does
-- not support. Re-run the parse with POSIX greedy groups and explicit separators.
WITH parsed AS (
    SELECT id,
           regexp_match(
                   message,
                   '^牲畜 \\[(.*)\\] 接近围栏 \\[(.*)\\]，位置: \\(([^,]+), *(.*)\\)$'
           ) AS match
    FROM alerts
    WHERE message_key IS NULL
      AND type = 'FENCE_APPROACH'
)
UPDATE alerts alert
SET message_key = 'alert.fence.approach',
    message_args = jsonb_build_array(parsed.match[1], parsed.match[2],
                                     parsed.match[3], parsed.match[4])::text
FROM parsed
WHERE alert.id = parsed.id
  AND array_length(parsed.match, 1) = 4;

WITH parsed AS (
    SELECT id,
           regexp_match(
                   message,
                   '^牲畜 \\[(.*)\\] 越出围栏 \\[(.*)\\]，位置: \\(([^,]+), *(.*)\\)$'
           ) AS match
    FROM alerts
    WHERE message_key IS NULL
      AND type = 'FENCE_BREACH'
)
UPDATE alerts alert
SET message_key = 'alert.fence.breach',
    message_args = jsonb_build_array(parsed.match[1], parsed.match[2],
                                     parsed.match[3], parsed.match[4])::text
FROM parsed
WHERE alert.id = parsed.id
  AND array_length(parsed.match, 1) = 4;
