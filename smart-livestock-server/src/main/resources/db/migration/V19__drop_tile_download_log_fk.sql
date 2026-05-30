-- V19: Remove FK constraint on tile_download_logs.farm_tile_task_id
-- Original design intended no FK (comment in TileJourneyTest: "无 FK 约束").
-- The FK prevents inserting logs for non-existent tasks, breaking the download log endpoint.

ALTER TABLE tile_download_logs DROP CONSTRAINT IF EXISTS tile_download_logs_farm_tile_task_id_fkey;
