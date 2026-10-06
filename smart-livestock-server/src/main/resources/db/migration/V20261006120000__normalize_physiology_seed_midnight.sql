-- Migration: normalize_physiology_seed_midnight
-- Date: 2026-10-06
-- Context: Health

-- NIX-258 m-o: the V20261004120000 demo seed wrote occurred_at as
-- NOW() - INTERVAL '128 days', i.e. the deploy-time instant with a
-- wall-clock component. B3 semantics require event instants to sit at
-- the midnight of their Asia/Shanghai calendar day — exactly what the
-- write path stores for a user-entered "yyyy-MM-dd": parseOccurredAt
-- maps the date to Asia/Shanghai midnight and Hibernate writes the
-- Instant as UTC wall-clock, so Shanghai 2026-09-10 lands at
-- 2026-09-09 16:00:00 (verified by PhysiologyEventJourneyTest).
--
-- Filter: source='MANUAL' AND created_by IS NULL matches only the two
-- seed rows — every API-created row carries the acting user's id
-- (JwtAuthenticationFilter puts the user id in the principal), so user
-- data is never touched. V20261004120000 itself is left untouched to
-- preserve its Flyway checksum on existing databases.
--
-- The expression deliberately avoids date_trunc on a timestamptz value
-- (which truncates in the *session* timezone — UTC in our containers;
-- the naive "date_trunc('day', ts AT TIME ZONE 'Asia/Shanghai')"
-- form would drift by 8 hours) and instead chains explicit zone
-- conversions on session-independent wall-clock values:
-- UTC wall-clock -> instant -> Shanghai wall-clock -> day truncation
-- -> instant -> UTC wall-clock.

UPDATE physiology_events
SET occurred_at = date_trunc('day', occurred_at AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Shanghai')
                        AT TIME ZONE 'Asia/Shanghai' AT TIME ZONE 'UTC'
WHERE source = 'MANUAL' AND created_by IS NULL;
