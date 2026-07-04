-- =====================================================
-- Open API Service Database Schema
-- Database: PostgreSQL
-- =====================================================

-- 1. 集成方应用表
CREATE TABLE IF NOT EXISTS open_app (
    id              BIGSERIAL       PRIMARY KEY,
    app_id          VARCHAR(64)     NOT NULL UNIQUE,
    app_secret_hash VARCHAR(255)    NOT NULL,
    name            VARCHAR(128)    NOT NULL,
    description     VARCHAR(512)    DEFAULT NULL,
    status          VARCHAR(16)     NOT NULL DEFAULT 'active',
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_open_app_status ON open_app(status);

-- 2. API Key 表
CREATE TABLE IF NOT EXISTS open_api_key (
    id              BIGSERIAL       PRIMARY KEY,
    app_id          BIGINT          NOT NULL REFERENCES open_app(id),
    key_id          VARCHAR(64)     NOT NULL UNIQUE,
    api_key_hash    VARCHAR(255)    NOT NULL,
    description     VARCHAR(256)    DEFAULT NULL,
    scope           VARCHAR(16)     NOT NULL,
    status          VARCHAR(16)     NOT NULL DEFAULT 'active',
    expires_at      TIMESTAMPTZ     DEFAULT NULL,
    last_used_at    TIMESTAMPTZ     DEFAULT NULL,
    internal_user_id BIGINT         DEFAULT 1,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    rotated_at      TIMESTAMPTZ     DEFAULT NULL
);

CREATE INDEX IF NOT EXISTS idx_open_api_key_app ON open_api_key(app_id);
CREATE INDEX IF NOT EXISTS idx_open_api_key_hash ON open_api_key(api_key_hash);
CREATE INDEX IF NOT EXISTS idx_open_api_key_status ON open_api_key(status);
CREATE INDEX IF NOT EXISTS idx_open_api_key_expires ON open_api_key(expires_at) WHERE expires_at IS NOT NULL;

-- 3. 审计日志表
CREATE TABLE IF NOT EXISTS open_api_audit_log (
    id              BIGSERIAL       PRIMARY KEY,
    app_id          BIGINT          NOT NULL,
    key_id          BIGINT          DEFAULT NULL,
    http_method     VARCHAR(8)      NOT NULL,
    request_path    VARCHAR(512)    NOT NULL,
    response_status SMALLINT        NOT NULL,
    client_ip       VARCHAR(64)     DEFAULT NULL,
    request_duration INTEGER        DEFAULT NULL,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_log_app ON open_api_audit_log(app_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_created ON open_api_audit_log(created_at);
