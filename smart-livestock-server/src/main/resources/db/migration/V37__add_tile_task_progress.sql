-- V37: tile_generation_tasks 加 progress 列（worker 周期写入下载进度，如 "z14 4400/5687 (77%)"）
ALTER TABLE tile_generation_tasks ADD COLUMN IF NOT EXISTS progress VARCHAR(100);
