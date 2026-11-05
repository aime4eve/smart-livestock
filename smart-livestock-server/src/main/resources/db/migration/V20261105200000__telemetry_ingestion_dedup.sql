-- ============================================================
-- V20261105200000: telemetry ingestion dedup (NIX-370) — parking
-- TelemetryIngestionDedup范式移植（04-smart-parking V88 同构）。
--
-- 背景：TB 上游链路（NS→OC 桥接→TB 写入）对同一物理帧重复写入两份
-- 完整数据（result×2 + dataHex×2，ts 平均差 134ms，payload/无线参数
-- 完全相同，生产 30 天 769 组/5 台）——provider_event_ts 不同，现有
-- (device_id, report_time) 唯一索引与精确 ts 幂等均拦不住，业务表双行。
--
-- 本表只登记观测、不落业务数据：每次 TB 直连观测先在此仲裁
-- （canonical / 近邻±2s+核心字段指纹相同→duplicate），仅 CANONICAL
-- 才允许写 device_telemetry_logs（仲裁与落库同一事务，失败整体回滚）。
-- 历史双行不清理；中台(AGENTIC_PLATFORM)与 TB 的设计性双轨不受影响
-- ——去重只挂在 THINGSBOARD 写入路径。
-- ============================================================

CREATE TABLE telemetry_ingestion_dedup (
    id BIGSERIAL PRIMARY KEY,
    provider VARCHAR(20) NOT NULL,
    channel VARCHAR(12) NOT NULL,
    CONSTRAINT chk_dedup_provider CHECK (provider IN ('THINGSBOARD')),
    CONSTRAINT chk_dedup_channel CHECK (channel IN ('tb-rest')),
    device_id BIGINT NOT NULL REFERENCES devices(id),
    external_device_id VARCHAR(64) NOT NULL,
    event_ts TIMESTAMPTZ NOT NULL,
    provider_event_ts BIGINT NOT NULL,
    canonical_key VARCHAR(64) NOT NULL,
    core_fields_fingerprint VARCHAR(64),
    is_canonical BOOLEAN NOT NULL DEFAULT FALSE,
    matched_canonical_key VARCHAR(64),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Same-source idempotency: one observation per provider/device/ts/channel.
CREATE UNIQUE INDEX uq_dedup_source_observation
    ON telemetry_ingestion_dedup(provider, external_device_id, provider_event_ts, channel);
-- One canonical event per canonical key (partial — duplicates stay non-canonical).
CREATE UNIQUE INDEX uq_dedup_canonical_event
    ON telemetry_ingestion_dedup(canonical_key) WHERE is_canonical;
CREATE INDEX idx_dedup_device_time ON telemetry_ingestion_dedup(device_id, event_ts DESC);

COMMENT ON TABLE telemetry_ingestion_dedup IS
    'NIX-370 observation registry for upstream duplicate writes (parking V88 pattern); canonical rows gate device_telemetry_logs inserts on the THINGSBOARD path';
COMMENT ON COLUMN telemetry_ingestion_dedup.provider_event_ts IS
    'TB frame ts (ms); duplicates differ by ~134ms so exact-ts idempotency cannot catch them';
COMMENT ON COLUMN telemetry_ingestion_dedup.core_fields_fingerprint IS
    'SHA-256 of sorted core business fields; wireless params (rssi/snr) deliberately excluded — the observed duplicates differ only there';
