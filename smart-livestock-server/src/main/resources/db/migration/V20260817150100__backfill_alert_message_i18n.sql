-- Backfill the legacy Chinese fence-message format before structured i18n fields existed.
WITH parsed AS (
    SELECT id,
           regexp_match(
                   message,
                   '^牲畜 \\[(.*?)\\] (?:越出|接近)围栏 \\[(.*?)\\]，位置: \\((.*?),(.*?)\\)$'
           ) AS match
    FROM alerts
    WHERE message_key IS NULL
      AND type IN ('FENCE_BREACH', 'FENCE_APPROACH')
)
UPDATE alerts alert
SET message_key = CASE alert.type
                       WHEN 'FENCE_BREACH' THEN 'alert.fence.breach'
                       ELSE 'alert.fence.approach'
                   END,
    message_args = jsonb_build_array(parsed.match[1], parsed.match[2],
                                     parsed.match[3], parsed.match[4])::text
FROM parsed
WHERE alert.id = parsed.id
  AND array_length(parsed.match, 1) = 4;
