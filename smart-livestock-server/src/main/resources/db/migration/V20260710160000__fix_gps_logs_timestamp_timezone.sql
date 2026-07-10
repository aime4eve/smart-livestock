-- Fix: gps_logs.recorded_at was TIMESTAMP WITHOUT TIME ZONE
-- JPA Instant writes UTC but data was stored as local time (UTC+8), causing 8h offset in queries.
-- Convert to TIMESTAMPTZ: interpret existing values as local time (Asia/Shanghai), then store properly.
ALTER TABLE gps_logs ALTER COLUMN recorded_at TYPE TIMESTAMPTZ
  USING recorded_at AT TIME ZONE 'Asia/Shanghai';
