-- ============================================================
-- NIX-68 fix: allow track_line_id = NULL on LINE tests
--
-- V20260728100000 made chk_test_type_truth require track_line_id
-- NOT NULL for LINE, but the FK is ON DELETE SET NULL (D4: history
-- survives candidate deletion via snapshots). Deleting a candidate
-- then violated the CHECK. track_line_id is a live reference only;
-- the truth travels with the snapshot tables, so relax the LINE
-- branch to allow NULL (same shape as TRAJECTORY).
-- ============================================================

ALTER TABLE gps_quality_tests DROP CONSTRAINT chk_test_type_truth;
ALTER TABLE gps_quality_tests ADD CONSTRAINT chk_test_type_truth CHECK (
    (test_type = 'STATIC'     AND rtk_point_id IS NOT NULL AND route_id IS NULL  AND track_line_id IS NULL) OR
    (test_type = 'DYNAMIC'    AND route_id IS NOT NULL AND rtk_point_id IS NULL  AND track_line_id IS NULL) OR
    (test_type = 'TRAJECTORY' AND rtk_point_id IS NULL AND route_id IS NULL      AND track_line_id IS NULL) OR
    (test_type = 'LINE'       AND rtk_point_id IS NULL AND route_id IS NULL)
);
