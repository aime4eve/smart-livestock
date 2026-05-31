-- ============================================================
-- V22: Analytics + API Portal Context
--   - Extend api_keys with scopes, rate limiting, description
--   - Create api_call_logs for per-request logging
--   - Create api_usage_daily for aggregated statistics
-- ============================================================

-- 1. Extend api_keys table with Portal fields
ALTER TABLE api_keys
    ADD COLUMN IF NOT EXISTS scopes VARCHAR(500) DEFAULT 'livestock:read,fence:read,alert:read,device:read,gps:read',
    ADD COLUMN IF NOT EXISTS requests_per_minute INT DEFAULT 60,
    ADD COLUMN IF NOT EXISTS daily_quota INT DEFAULT 0,
    ADD COLUMN IF NOT EXISTS description VARCHAR(500);

-- Update status constraint to include DISABLED
ALTER TABLE api_keys DROP CONSTRAINT IF EXISTS chk_api_keys_status;
ALTER TABLE api_keys ADD CONSTRAINT chk_api_keys_status
    CHECK (status IN ('ACTIVE', 'REVOKED', 'DISABLED'));

-- 2. API call logs — per-request records for analytics
CREATE TABLE api_call_logs (
    id BIGSERIAL PRIMARY KEY,
    api_key_id BIGINT REFERENCES api_keys(id) ON DELETE SET NULL,
    tenant_id BIGINT NOT NULL,
    endpoint VARCHAR(200) NOT NULL,
    method VARCHAR(10) NOT NULL,
    status_code INT NOT NULL,
    response_time_ms INT,
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    farm_id BIGINT,
    requested_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_call_logs_key_date ON api_call_logs(api_key_id, requested_at DESC);
CREATE INDEX idx_call_logs_tenant_date ON api_call_logs(tenant_id, requested_at DESC);
CREATE INDEX idx_call_logs_requested_at ON api_call_logs(requested_at DESC);

-- 3. Daily usage aggregation
CREATE TABLE api_usage_daily (
    id BIGSERIAL PRIMARY KEY,
    api_key_id BIGINT NOT NULL REFERENCES api_keys(id) ON DELETE CASCADE,
    tenant_id BIGINT NOT NULL,
    usage_date DATE NOT NULL,
    total_calls INT NOT NULL DEFAULT 0,
    success_calls INT NOT NULL DEFAULT 0,
    error_calls INT NOT NULL DEFAULT 0,
    avg_response_ms INT,
    p95_response_ms INT,
    top_endpoints JSONB DEFAULT '{}',
    UNIQUE(api_key_id, usage_date)
);

CREATE INDEX idx_usage_daily_tenant_date ON api_usage_daily(tenant_id, usage_date DESC);
