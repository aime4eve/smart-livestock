-- 1. Fence table extensions
ALTER TABLE fences ADD COLUMN IF NOT EXISTS version INT NOT NULL DEFAULT 1;
ALTER TABLE fences ADD COLUMN IF NOT EXISTS fence_type VARCHAR(20) NOT NULL DEFAULT 'sub';

-- 2. tile_regions — server-side MBTiles file registry
CREATE TABLE tile_regions (
    id           BIGSERIAL PRIMARY KEY,
    name         VARCHAR(100) NOT NULL UNIQUE,
    min_lon      DOUBLE PRECISION NOT NULL,
    min_lat      DOUBLE PRECISION NOT NULL,
    max_lon      DOUBLE PRECISION NOT NULL,
    max_lat      DOUBLE PRECISION NOT NULL,
    min_zoom     INT NOT NULL DEFAULT 11,
    max_zoom     INT NOT NULL DEFAULT 15,
    file_name    VARCHAR(255),
    file_size    BIGINT,
    md5          VARCHAR(32),
    generated_at TIMESTAMPTZ,
    status       VARCHAR(20) NOT NULL DEFAULT 'pending',
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. tile_generation_tasks — MBTiles generation jobs
CREATE TABLE tile_generation_tasks (
    id              BIGSERIAL PRIMARY KEY,
    region_id       BIGINT REFERENCES tile_regions(id),
    min_lon         DOUBLE PRECISION NOT NULL,
    min_lat         DOUBLE PRECISION NOT NULL,
    max_lon         DOUBLE PRECISION NOT NULL,
    max_lat         DOUBLE PRECISION NOT NULL,
    min_zoom        INT NOT NULL DEFAULT 11,
    max_zoom        INT NOT NULL DEFAULT 15,
    region_name     VARCHAR(100) NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'pending',
    triggered_by    VARCHAR(50),
    tile_count      INT,
    file_size_mb    DOUBLE PRECISION,
    error_message   TEXT,
    coverage_ratio  DOUBLE PRECISION,
    is_custom_region BOOLEAN NOT NULL DEFAULT false,
    started_at      TIMESTAMPTZ,
    finished_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. farm_tile_tasks — per-farm per-region download status (many-to-many)
CREATE TABLE farm_tile_tasks (
    id           BIGSERIAL PRIMARY KEY,
    farm_id      BIGINT NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    region_id    BIGINT NOT NULL REFERENCES tile_regions(id),
    status       VARCHAR(30) NOT NULL DEFAULT 'pending',
    file_size    BIGINT,
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(farm_id, region_id)
);

-- 5. tile_download_logs — client download history
CREATE TABLE tile_download_logs (
    id                BIGSERIAL PRIMARY KEY,
    farm_tile_task_id BIGINT NOT NULL REFERENCES farm_tile_tasks(id),
    user_id           BIGINT NOT NULL REFERENCES users(id),
    device_info       VARCHAR(255),
    bytes_downloaded  BIGINT,
    started_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    finished_at       TIMESTAMPTZ
);

-- 6. Indexes
CREATE INDEX idx_farm_tile_tasks_farm ON farm_tile_tasks(farm_id);
CREATE INDEX idx_farm_tile_tasks_status ON farm_tile_tasks(status);
CREATE INDEX idx_tile_gen_tasks_status ON tile_generation_tasks(status);
CREATE INDEX idx_tile_download_logs_user ON tile_download_logs(user_id);

-- 7. API Keys table extensions
ALTER TABLE api_keys ADD COLUMN IF NOT EXISTS role VARCHAR(20) NOT NULL DEFAULT 'admin';
ALTER TABLE api_keys ADD COLUMN IF NOT EXISTS last_used_at TIMESTAMPTZ;
