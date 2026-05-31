-- ============================================================
-- V19: Health Context — 时序数据表 + 发情评分 + 健康快照 + 接触追踪
-- ============================================================

-- ----------------------------------------------------------
-- temperature_logs — 瘤胃温度时序（按月分区）
-- 数据源: CAPSULE 设备，采样间隔 ~30min
-- ----------------------------------------------------------
CREATE TABLE temperature_logs (
    id BIGSERIAL,
    livestock_id BIGINT NOT NULL,
    device_id BIGINT NOT NULL,
    temperature DECIMAL(5,2) NOT NULL,
    baseline_temp DECIMAL(5,2) NOT NULL DEFAULT 38.50,
    delta DECIMAL(5,2) GENERATED ALWAYS AS (temperature - baseline_temp) STORED,
    recorded_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id, recorded_at)
) PARTITION BY RANGE (recorded_at);

CREATE TABLE temperature_logs_2026_03 PARTITION OF temperature_logs
    FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE temperature_logs_2026_04 PARTITION OF temperature_logs
    FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
CREATE TABLE temperature_logs_2026_05 PARTITION OF temperature_logs
    FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');
CREATE TABLE temperature_logs_2026_06 PARTITION OF temperature_logs
    FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');
CREATE TABLE temperature_logs_2026_07 PARTITION OF temperature_logs
    FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');
CREATE TABLE temperature_logs_2026_08 PARTITION OF temperature_logs
    FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');
CREATE TABLE temperature_logs_default PARTITION OF temperature_logs DEFAULT;

CREATE INDEX idx_temp_logs_livestock_time ON temperature_logs(livestock_id, recorded_at DESC);
CREATE INDEX idx_temp_logs_device_time ON temperature_logs(device_id, recorded_at DESC);
CREATE INDEX idx_temp_logs_delta ON temperature_logs(delta) WHERE delta > 1.0;

-- ----------------------------------------------------------
-- rumen_motility_logs — 瘤胃蠕动时序（按月分区）
-- 数据源: CAPSULE 设备，采样间隔 ~30min
-- ----------------------------------------------------------
CREATE TABLE rumen_motility_logs (
    id BIGSERIAL,
    livestock_id BIGINT NOT NULL,
    device_id BIGINT NOT NULL,
    frequency DECIMAL(5,2) NOT NULL,
    intensity DECIMAL(5,2) NOT NULL,
    recorded_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id, recorded_at)
) PARTITION BY RANGE (recorded_at);

CREATE TABLE rumen_motility_logs_2026_03 PARTITION OF rumen_motility_logs
    FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE rumen_motility_logs_2026_04 PARTITION OF rumen_motility_logs
    FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
CREATE TABLE rumen_motility_logs_2026_05 PARTITION OF rumen_motility_logs
    FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');
CREATE TABLE rumen_motility_logs_2026_06 PARTITION OF rumen_motility_logs
    FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');
CREATE TABLE rumen_motility_logs_2026_07 PARTITION OF rumen_motility_logs
    FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');
CREATE TABLE rumen_motility_logs_2026_08 PARTITION OF rumen_motility_logs
    FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');
CREATE TABLE rumen_motility_logs_default PARTITION OF rumen_motility_logs DEFAULT;

CREATE INDEX idx_motility_logs_livestock_time ON rumen_motility_logs(livestock_id, recorded_at DESC);

-- ----------------------------------------------------------
-- activity_logs — 活动量时序（按月分区）
-- 数据源: TRACKER (步数) + ACCELEROMETER (活动指数)
-- 采样间隔 ~1h
-- ----------------------------------------------------------
CREATE TABLE activity_logs (
    id BIGSERIAL,
    livestock_id BIGINT NOT NULL,
    device_id BIGINT NOT NULL,
    step_count INTEGER,
    activity_index DECIMAL(5,2),
    distance_meters DECIMAL(8,2),
    recorded_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id, recorded_at)
) PARTITION BY RANGE (recorded_at);

CREATE TABLE activity_logs_2026_03 PARTITION OF activity_logs
    FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE activity_logs_2026_04 PARTITION OF activity_logs
    FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
CREATE TABLE activity_logs_2026_05 PARTITION OF activity_logs
    FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');
CREATE TABLE activity_logs_2026_06 PARTITION OF activity_logs
    FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');
CREATE TABLE activity_logs_2026_07 PARTITION OF activity_logs
    FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');
CREATE TABLE activity_logs_2026_08 PARTITION OF activity_logs
    FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');
CREATE TABLE activity_logs_default PARTITION OF activity_logs DEFAULT;

CREATE INDEX idx_activity_logs_livestock_time ON activity_logs(livestock_id, recorded_at DESC);

-- ----------------------------------------------------------
-- estrus_scores — 发情评分快照
-- ----------------------------------------------------------
CREATE TABLE estrus_scores (
    id BIGSERIAL PRIMARY KEY,
    farm_id BIGINT NOT NULL REFERENCES farms(id),
    livestock_id BIGINT NOT NULL,
    score INTEGER NOT NULL CONSTRAINT chk_estrus_score CHECK (score BETWEEN 0 AND 100),
    step_increase_percent INTEGER,
    temp_delta DECIMAL(5,2),
    distance_delta DECIMAL(5,2),
    advice TEXT,
    scored_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_estrus_farm_time ON estrus_scores(farm_id, scored_at DESC);
CREATE INDEX idx_estrus_livestock_time ON estrus_scores(livestock_id, scored_at DESC);
CREATE INDEX idx_estrus_high_score ON estrus_scores(score) WHERE score >= 70;

-- ----------------------------------------------------------
-- health_snapshots — 每头牲畜当前健康状态聚合
-- ----------------------------------------------------------
CREATE TABLE health_snapshots (
    id BIGSERIAL PRIMARY KEY,
    livestock_id BIGINT NOT NULL UNIQUE,
    farm_id BIGINT NOT NULL REFERENCES farms(id),
    baseline_temp DECIMAL(5,2) NOT NULL DEFAULT 38.50,
    current_temp DECIMAL(5,2),
    temp_status VARCHAR(20) NOT NULL DEFAULT 'NORMAL'
        CONSTRAINT chk_temp_status CHECK (temp_status IN ('NORMAL', 'ELEVATED', 'FEVER', 'CRITICAL')),
    motility_baseline DECIMAL(5,2) DEFAULT 3.0,
    current_motility DECIMAL(5,2),
    motility_status VARCHAR(20) NOT NULL DEFAULT 'NORMAL'
        CONSTRAINT chk_motility_status CHECK (motility_status IN ('NORMAL', 'LOW', 'ABNORMAL')),
    estrus_score INTEGER DEFAULT 0,
    activity_status VARCHAR(20) NOT NULL DEFAULT 'NORMAL'
        CONSTRAINT chk_activity_status CHECK (activity_status IN ('NORMAL', 'ELEVATED', 'LOW', 'ABNORMAL')),
    last_assessed_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_health_snap_farm ON health_snapshots(farm_id);
CREATE INDEX idx_health_snap_temp_status ON health_snapshots(temp_status);
CREATE INDEX idx_health_snap_motility_status ON health_snapshots(motility_status);

-- ----------------------------------------------------------
-- contact_traces — 接触追踪记录
-- ----------------------------------------------------------
CREATE TABLE contact_traces (
    id BIGSERIAL PRIMARY KEY,
    farm_id BIGINT NOT NULL REFERENCES farms(id),
    from_livestock_id BIGINT NOT NULL,
    to_livestock_id BIGINT NOT NULL,
    proximity_meters DECIMAL(6,2) NOT NULL,
    contact_duration_minutes INTEGER NOT NULL DEFAULT 0,
    last_contact_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_contact_farm_time ON contact_traces(farm_id, last_contact_at DESC);
CREATE INDEX idx_contact_from ON contact_traces(from_livestock_id);
CREATE INDEX idx_contact_to ON contact_traces(to_livestock_id);
