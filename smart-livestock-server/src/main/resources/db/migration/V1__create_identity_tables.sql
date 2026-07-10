-- ============================================================
-- V1: Identity Context — tenants, farms, users, user_farm_assignments, api_keys
-- ============================================================

-- tenants
CREATE TABLE tenants (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contact_name VARCHAR(100),
    contact_phone VARCHAR(20),
    phase VARCHAR(10) NOT NULL DEFAULT 'SAMPLE',
    CONSTRAINT chk_tenants_phase CHECK (phase IN ('SAMPLE', 'BATCH')),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- farms (soft delete via deleted_at)
CREATE TABLE farms (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id),
    name VARCHAR(100) NOT NULL,
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    area_hectares DECIMAL(10,2),
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_farms_tenant_id ON farms(tenant_id);
-- Partial unique index: farm names must be unique within a tenant among non-deleted farms
CREATE UNIQUE INDEX uq_farms_tenant_name_active ON farms(tenant_id, name) WHERE deleted_at IS NULL;

-- users
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    password_hash VARCHAR(100) NOT NULL,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    role VARCHAR(30) NOT NULL,
    CONSTRAINT chk_users_role CHECK (role IN ('OWNER', 'WORKER', 'PLATFORM_ADMIN', 'B2B_ADMIN', 'API_CONSUMER')),
    tenant_id BIGINT REFERENCES tenants(id),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_login_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_users_tenant_id ON users(tenant_id);
CREATE INDEX idx_users_role ON users(role);

-- user_farm_assignments
CREATE TABLE user_farm_assignments (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    farm_id BIGINT NOT NULL REFERENCES farms(id),
    role VARCHAR(30) NOT NULL,
    CONSTRAINT chk_ufa_role CHECK (role IN ('OWNER', 'WORKER')),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT chk_ufa_status CHECK (status IN ('ACTIVE', 'DISABLED')),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_user_farm UNIQUE (user_id, farm_id)
);
CREATE INDEX idx_ufa_farm_id ON user_farm_assignments(farm_id);

-- api_keys (minimal Phase 1 table for demo/testing)
CREATE TABLE api_keys (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id),
    key_name VARCHAR(100) NOT NULL,
    key_hash VARCHAR(64) NOT NULL UNIQUE,
    key_prefix VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT chk_api_keys_status CHECK (status IN ('ACTIVE', 'REVOKED')),
    expires_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_api_keys_tenant_id ON api_keys(tenant_id);
