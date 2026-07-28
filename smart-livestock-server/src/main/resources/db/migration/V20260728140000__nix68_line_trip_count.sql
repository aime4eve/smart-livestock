-- ============================================================
-- NIX-68: trip count on LINE results (spatial matching)
--
-- Matching switched from time-window to spatial (corridor + trip
-- segmentation): gps_quality_line_results gains trip_count = number
-- of valid trip segments the samples were merged from. Existing rows
-- were computed under the old window semantics and keep 0.
-- ============================================================

ALTER TABLE gps_quality_line_results
    ADD COLUMN trip_count INTEGER NOT NULL DEFAULT 0;
