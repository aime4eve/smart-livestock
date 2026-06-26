-- V38: datagen 限界上下文 — 合成数据场景 + ground-truth 标签表
-- 合成场景
CREATE TABLE IF NOT EXISTS synthesis_scenarios (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT'
        CHECK (status IN ('DRAFT','RUNNING','STOPPED')),
    pattern VARCHAR(40) NOT NULL,
    penetration_rate DECIMAL(3,2) NOT NULL DEFAULT 1.0,
    window_start TIMESTAMP NOT NULL,
    window_end TIMESTAMP NOT NULL,
    interval_seconds INTEGER NOT NULL DEFAULT 30,
    target_livestock_ids TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
-- Ground-truth 标签（核心表）
CREATE TABLE IF NOT EXISTS ground_truth_labels (
    id BIGSERIAL PRIMARY KEY,
    livestock_id BIGINT NOT NULL,
    pattern VARCHAR(40) NOT NULL,
    period_start TIMESTAMP NOT NULL,
    period_end TIMESTAMP NOT NULL,
    source VARCHAR(10) NOT NULL DEFAULT 'SYNTHETIC'
        CHECK (source IN ('SYNTHETIC','MANUAL')),
    severity DECIMAL(3,2),
    labeled_by BIGINT,
    labeled_at TIMESTAMP,
    note TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_gtl_livestock_period ON ground_truth_labels (livestock_id, period_start, period_end);
CREATE INDEX IF NOT EXISTS idx_gtl_pattern ON ground_truth_labels (pattern, period_start);
CREATE INDEX IF NOT EXISTS idx_ss_status ON synthesis_scenarios (status);
-- 默认场景：替代原 telemetry.simulator.enabled=true 行为
INSERT INTO synthesis_scenarios (name, status, pattern, penetration_rate, window_start, window_end, interval_seconds)
SELECT '默认持续合成', 'RUNNING', 'NORMAL', 1.0, NOW(), NOW() + INTERVAL '365 days', 30
WHERE NOT EXISTS (SELECT 1 FROM synthesis_scenarios WHERE name = '默认持续合成');
