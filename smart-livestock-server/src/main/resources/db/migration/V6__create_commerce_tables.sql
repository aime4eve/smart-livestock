-- ============================================================
-- V6: Commerce Context — subscriptions, contracts, revenue_periods,
--     subscription_services, feature_gates + notifications (platform infra)
--     + tenant ALTER + seed data
-- ============================================================

-- 1. subscriptions
CREATE TABLE subscriptions (
    id              BIGSERIAL PRIMARY KEY,
    tenant_id       BIGINT NOT NULL REFERENCES tenants(id),
    tier            VARCHAR(20) NOT NULL DEFAULT 'basic',
    billing_model   VARCHAR(20) NOT NULL DEFAULT 'direct',
    status          VARCHAR(30) NOT NULL DEFAULT 'trial',
    billing_cycle   VARCHAR(20) NOT NULL DEFAULT 'monthly',
    started_at      TIMESTAMPTZ NOT NULL,
    expires_at      TIMESTAMPTZ,
    trial_ends_at   TIMESTAMPTZ,
    cancelled_at    TIMESTAMPTZ,
    version         BIGINT NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_subscriptions_tenant UNIQUE (tenant_id),
    CONSTRAINT chk_subscriptions_status CHECK (status IN ('trial', 'free', 'active', 'suspended', 'renewal_failed', 'cancelled', 'expired')),
    CONSTRAINT chk_subscriptions_tier CHECK (tier IN ('basic', 'standard', 'premium', 'enterprise')),
    CONSTRAINT chk_subscriptions_billing_model CHECK (billing_model IN ('direct', 'revenue_share', 'licensed', 'api_usage')),
    CONSTRAINT chk_subscriptions_billing_cycle CHECK (billing_cycle IN ('monthly', 'yearly'))
);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);
CREATE INDEX idx_subscriptions_status_expires ON subscriptions(status, expires_at)
    WHERE status IN ('active', 'trial', 'renewal_failed') AND expires_at IS NOT NULL;
CREATE INDEX idx_subscriptions_trial_expires ON subscriptions(status, trial_ends_at)
    WHERE status = 'trial' AND trial_ends_at IS NOT NULL;

-- 2. contracts
CREATE TABLE contracts (
    id                  BIGSERIAL PRIMARY KEY,
    contract_number     VARCHAR(30) NOT NULL,
    tenant_id           BIGINT NOT NULL REFERENCES tenants(id),
    billing_model       VARCHAR(20) NOT NULL,
    effective_tier      VARCHAR(20) NOT NULL,
    revenue_share_ratio DECIMAL(5,4),
    status              VARCHAR(20) NOT NULL DEFAULT 'draft',
    signed_by           BIGINT REFERENCES users(id),
    signed_at           TIMESTAMPTZ,
    started_at          TIMESTAMPTZ NOT NULL,
    expires_at          TIMESTAMPTZ,
    version             BIGINT NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_contracts_number UNIQUE (contract_number),
    CONSTRAINT chk_contracts_status CHECK (status IN ('draft', 'active', 'suspended', 'expired', 'terminated')),
    CONSTRAINT chk_contracts_billing_model CHECK (billing_model IN ('direct', 'revenue_share', 'licensed', 'api_usage')),
    CONSTRAINT chk_contracts_effective_tier CHECK (effective_tier IN ('basic', 'standard', 'premium', 'enterprise'))
);
CREATE INDEX idx_contracts_tenant ON contracts(tenant_id);
CREATE INDEX idx_contracts_status ON contracts(status);
CREATE INDEX idx_contracts_expires ON contracts(expires_at) WHERE expires_at IS NOT NULL;

-- 3. revenue_periods
CREATE TABLE revenue_periods (
    id                  BIGSERIAL PRIMARY KEY,
    contract_id         BIGINT NOT NULL REFERENCES contracts(id),
    tenant_id           BIGINT NOT NULL REFERENCES tenants(id),
    period_start        DATE NOT NULL,
    period_end          DATE NOT NULL,
    gross_amount        INTEGER NOT NULL,
    platform_share      INTEGER NOT NULL,
    partner_share       INTEGER NOT NULL,
    revenue_share_ratio DECIMAL(5,4) NOT NULL,
    status              VARCHAR(20) NOT NULL DEFAULT 'pending',
    settled_at          TIMESTAMPTZ,
    version             BIGINT NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_revenue_period UNIQUE (contract_id, period_start),
    CONSTRAINT chk_revenue_periods_status CHECK (status IN ('pending', 'platform_confirmed', 'partner_confirmed', 'settled'))
);
CREATE INDEX idx_revenue_periods_tenant ON revenue_periods(tenant_id);
CREATE INDEX idx_revenue_periods_status ON revenue_periods(status);

-- 4. subscription_services
CREATE TABLE subscription_services (
    id                      BIGSERIAL PRIMARY KEY,
    tenant_id               BIGINT NOT NULL REFERENCES tenants(id),
    service_name            VARCHAR(100) NOT NULL,
    service_key_prefix      VARCHAR(8),
    service_key_hash        VARCHAR(64) NOT NULL,
    effective_tier          VARCHAR(20) NOT NULL,
    device_quota            INTEGER,
    status                  VARCHAR(20) NOT NULL DEFAULT 'provisioned',
    last_heartbeat_at       TIMESTAMPTZ,
    grace_ends_at           TIMESTAMPTZ,
    started_at              TIMESTAMPTZ NOT NULL,
    expires_at              TIMESTAMPTZ,
    heartbeat_interval_hrs  INTEGER DEFAULT 24,
    grace_period_days       INTEGER DEFAULT 7,
    version                 BIGINT NOT NULL DEFAULT 0,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_subscription_service_tenant UNIQUE (tenant_id),
    CONSTRAINT chk_subscription_services_status CHECK (status IN ('provisioned', 'active', 'grace_period', 'degraded', 'expired')),
    CONSTRAINT chk_subscription_services_effective_tier CHECK (effective_tier IN ('basic', 'standard', 'premium', 'enterprise'))
);
CREATE INDEX idx_sub_services_status ON subscription_services(status);

-- 5. feature_gates
CREATE TABLE feature_gates (
    id              BIGSERIAL PRIMARY KEY,
    tier            VARCHAR(20) NOT NULL,
    feature_key     VARCHAR(50) NOT NULL,
    gate_type       VARCHAR(10) NOT NULL,
    limit_value     INTEGER,
    retention_days  INTEGER,
    is_enabled      BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_feature_gates_tier_feature UNIQUE (tier, feature_key),
    CONSTRAINT chk_feature_gates_gate_type CHECK (gate_type IN ('none', 'lock', 'limit', 'filter')),
    CONSTRAINT chk_feature_gates_tier CHECK (tier IN ('basic', 'standard', 'premium', 'enterprise'))
);

-- 6. notifications (platform infrastructure, not Commerce-private)
CREATE TABLE notifications (
    id          BIGSERIAL PRIMARY KEY,
    tenant_id   BIGINT NOT NULL REFERENCES tenants(id),
    user_id     BIGINT REFERENCES users(id),
    type        VARCHAR(50) NOT NULL,
    title       VARCHAR(200) NOT NULL,
    content     TEXT,
    is_read     BOOLEAN DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_notifications_tenant_unread ON notifications(tenant_id, is_read) WHERE is_read = FALSE;

-- 7. Tenant table alterations
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS type VARCHAR(20);
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS billing_model VARCHAR(20) DEFAULT 'direct';
ALTER TABLE tenants ADD CONSTRAINT chk_tenants_type CHECK (type IN ('rancher', 'reseller', 'enterprise', 'developer'));
ALTER TABLE tenants ADD CONSTRAINT chk_tenants_billing_model CHECK (billing_model IN ('direct', 'revenue_share', 'licensed', 'api_usage'));
UPDATE tenants SET type = 'rancher', billing_model = 'direct' WHERE type IS NULL;

-- ============================================================
-- Seed data
-- ============================================================

-- feature_gates seed: 4 tiers x 7 feature keys
-- gate_type values: 'none' (unrestricted), 'lock' (boolean gate), 'limit' (numeric cap), 'filter' (data range)

-- basic tier
INSERT INTO feature_gates (tier, feature_key, gate_type, limit_value, retention_days, is_enabled) VALUES
    ('basic', 'livestock_management', 'limit', 50, NULL, TRUE),
    ('basic', 'fence_management', 'limit', 5, NULL, TRUE),
    ('basic', 'alert_management', 'lock', NULL, NULL, FALSE),
    ('basic', 'advanced_analytics', 'lock', NULL, NULL, FALSE),
    ('basic', 'api_access', 'lock', NULL, NULL, FALSE),
    ('basic', 'worker_management', 'limit', 3, NULL, TRUE),
    ('basic', 'health_monitoring', 'lock', NULL, NULL, FALSE);

-- standard tier
INSERT INTO feature_gates (tier, feature_key, gate_type, limit_value, retention_days, is_enabled) VALUES
    ('standard', 'livestock_management', 'limit', 200, NULL, TRUE),
    ('standard', 'fence_management', 'limit', 20, NULL, TRUE),
    ('standard', 'alert_management', 'none', NULL, NULL, TRUE),
    ('standard', 'advanced_analytics', 'filter', NULL, 30, TRUE),
    ('standard', 'api_access', 'lock', NULL, NULL, FALSE),
    ('standard', 'worker_management', 'limit', 10, NULL, TRUE),
    ('standard', 'health_monitoring', 'none', NULL, NULL, TRUE);

-- premium tier
INSERT INTO feature_gates (tier, feature_key, gate_type, limit_value, retention_days, is_enabled) VALUES
    ('premium', 'livestock_management', 'limit', 1000, NULL, TRUE),
    ('premium', 'fence_management', 'limit', 100, NULL, TRUE),
    ('premium', 'alert_management', 'none', NULL, NULL, TRUE),
    ('premium', 'advanced_analytics', 'none', NULL, NULL, TRUE),
    ('premium', 'api_access', 'none', NULL, NULL, TRUE),
    ('premium', 'worker_management', 'limit', 50, NULL, TRUE),
    ('premium', 'health_monitoring', 'none', NULL, NULL, TRUE);

-- enterprise tier
INSERT INTO feature_gates (tier, feature_key, gate_type, limit_value, retention_days, is_enabled) VALUES
    ('enterprise', 'livestock_management', 'none', NULL, NULL, TRUE),
    ('enterprise', 'fence_management', 'none', NULL, NULL, TRUE),
    ('enterprise', 'alert_management', 'none', NULL, NULL, TRUE),
    ('enterprise', 'advanced_analytics', 'none', NULL, NULL, TRUE),
    ('enterprise', 'api_access', 'none', NULL, NULL, TRUE),
    ('enterprise', 'worker_management', 'none', NULL, NULL, TRUE),
    ('enterprise', 'health_monitoring', 'none', NULL, NULL, TRUE);

-- Default trial subscription for demo tenant (id=1)
INSERT INTO subscriptions (tenant_id, tier, billing_model, status, billing_cycle, started_at, trial_ends_at)
VALUES (1, 'basic', 'direct', 'trial', 'monthly', now(), now() + INTERVAL '30 days');
