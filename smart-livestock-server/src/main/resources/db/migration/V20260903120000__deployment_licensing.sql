-- ============================================================
-- NIX-184 T1: deployment licensing data model (design section 6)
--   deployment_installations  one row per tenant host registration
--   deployment_licenses       imported offline license records + last validation
--   deployment_license_states per-tenant runtime state (tamper / rollback guard)
--   deployment_license_events audit trail of licensing lifecycle events
-- No usable license payload is seeded here: the migration itself must never
-- become a license bypass entry point.
-- ============================================================

-- 1. deployment_installations
CREATE TABLE deployment_installations (
    id              BIGSERIAL PRIMARY KEY,
    tenant_id       BIGINT NOT NULL REFERENCES tenants(id),
    installation_id UUID NOT NULL,
    fingerprint_hash VARCHAR(64),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_deployment_installations_tenant UNIQUE (tenant_id),
    CONSTRAINT uq_deployment_installations_installation UNIQUE (installation_id)
);

-- 2. deployment_licenses
CREATE TABLE deployment_licenses (
    id                  BIGSERIAL PRIMARY KEY,
    license_id          UUID NOT NULL,
    tenant_id           BIGINT REFERENCES tenants(id),
    installation_id     UUID,
    fingerprint_hash    VARCHAR(64),
    key_id              VARCHAR(64),
    license_type        VARCHAR(20),
    tier                VARCHAR(20),
    effective_tier      VARCHAR(20),
    issued_at           TIMESTAMPTZ,
    expires_at          TIMESTAMPTZ,
    payload_sha256      VARCHAR(64),
    raw_license         TEXT,
    status              VARCHAR(30),
    accepted_at         TIMESTAMPTZ,
    last_validated_at   TIMESTAMPTZ,
    last_result         VARCHAR(20),
    last_error_code     VARCHAR(50),
    replaces_license_id UUID,
    CONSTRAINT uq_deployment_licenses_license UNIQUE (license_id)
);

CREATE INDEX idx_deployment_licenses_tenant_status_expires
    ON deployment_licenses(tenant_id, status, expires_at);

-- 3. deployment_license_states (one row per tenant, tenant_id is the PK)
CREATE TABLE deployment_license_states (
    tenant_id         BIGINT PRIMARY KEY REFERENCES tenants(id),
    current_license_id UUID,
    runtime_status    VARCHAR(30),
    max_observed_at   TIMESTAMPTZ,
    last_validated_at TIMESTAMPTZ,
    last_error_code   VARCHAR(50),
    protection_reason VARCHAR(50),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. deployment_license_events
CREATE TABLE deployment_license_events (
    id              BIGSERIAL PRIMARY KEY,
    license_id      UUID,
    tenant_id       BIGINT REFERENCES tenants(id),
    event_type      VARCHAR(50) NOT NULL,
    result          VARCHAR(20),
    error_code      VARCHAR(50),
    details         JSONB,
    operator_user_id BIGINT REFERENCES users(id),
    occurred_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_deployment_license_events_tenant_occurred
    ON deployment_license_events(tenant_id, occurred_at);

-- ============================================================
-- Seed: device_management feature gates for all four tiers
-- Idempotent: keep the existing row if a rerun or a prior seed already set it.
-- ============================================================

INSERT INTO feature_gates (tier, feature_key, gate_type, limit_value, retention_days, is_enabled) VALUES
    ('basic', 'device_management', 'limit', 50, NULL, TRUE),
    ('standard', 'device_management', 'limit', 200, NULL, TRUE),
    ('premium', 'device_management', 'limit', 1000, NULL, TRUE),
    ('enterprise', 'device_management', 'none', NULL, NULL, TRUE)
ON CONFLICT (tier, feature_key) DO NOTHING;
