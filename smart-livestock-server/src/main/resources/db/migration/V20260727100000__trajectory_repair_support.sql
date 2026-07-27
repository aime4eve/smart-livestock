ALTER TABLE gps_quality_track_points
    ADD COLUMN IF NOT EXISTS nearest_gps_log_seconds INTEGER;
ALTER TABLE gps_quality_track_points
    ALTER COLUMN tolerance_seconds SET DEFAULT 300;
