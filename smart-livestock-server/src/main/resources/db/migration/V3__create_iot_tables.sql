-- ============================================================
-- V3: IoT Context — devices, device_licenses, installations, gps_logs
-- ============================================================

-- devices (soft delete via deleted_at)
CREATE TABLE devices (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id),
    device_code VARCHAR(50) NOT NULL UNIQUE,
    device_type VARCHAR(20) NOT NULL,
    CONSTRAINT chk_devices_type CHECK (device_type IN ('EAR_TAG', 'TRACKER', 'CAPSULE', 'ACCELEROMETER')),
    status VARCHAR(20) NOT NULL DEFAULT 'INVENTORY',
    CONSTRAINT chk_devices_status CHECK (status IN ('INVENTORY', 'ACTIVE', 'OFFLINE', 'DECOMMISSIONED')),
    battery_level INTEGER,
    firmware_version VARCHAR(50),
    dev_eui VARCHAR(16),
    last_online_at TIMESTAMP,
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_devices_tenant_id ON devices(tenant_id);
CREATE INDEX idx_devices_status ON devices(status);

-- device_licenses
CREATE TABLE device_licenses (
    id BIGSERIAL PRIMARY KEY,
    device_id BIGINT NOT NULL UNIQUE REFERENCES devices(id),
    tenant_id BIGINT NOT NULL REFERENCES tenants(id),
    license_key VARCHAR(100) NOT NULL UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT chk_dl_status CHECK (status IN ('ACTIVE', 'EXPIRED', 'REVOKED')),
    activated_at TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_dl_tenant_id ON device_licenses(tenant_id);

-- installations
-- NOTE: livestock_id is a cross-context reference (Ranch Context) with NO FK constraint.
-- Data consistency is enforced at the application layer only.
CREATE TABLE installations (
    id BIGSERIAL PRIMARY KEY,
    device_id BIGINT NOT NULL REFERENCES devices(id),
    livestock_id BIGINT NOT NULL,
    installed_at TIMESTAMP NOT NULL,
    removed_at TIMESTAMP,
    operator_id BIGINT REFERENCES users(id),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
-- Partial unique index: a device can have at most one active installation (removed_at IS NULL)
CREATE UNIQUE INDEX idx_installations_active ON installations(device_id) WHERE removed_at IS NULL;
CREATE INDEX idx_installations_livestock ON installations(livestock_id);

-- gps_logs
-- JOIN path for livestock position: gps_logs -> devices -> installations (WHERE removed_at IS NULL) -> livestock
CREATE TABLE gps_logs (
    id BIGSERIAL PRIMARY KEY,
    device_id BIGINT NOT NULL REFERENCES devices(id),
    latitude DECIMAL(10,7) NOT NULL,
    longitude DECIMAL(10,7) NOT NULL,
    accuracy DECIMAL(6,2),
    recorded_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_gps_logs_device_time ON gps_logs(device_id, recorded_at DESC);
