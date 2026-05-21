-- ============================================================
-- V2: Ranch Context — livestock, fences, alerts
-- ============================================================

-- livestock (soft delete via deleted_at)
CREATE TABLE livestock (
    id BIGSERIAL PRIMARY KEY,
    farm_id BIGINT NOT NULL REFERENCES farms(id),
    livestock_code VARCHAR(50) NOT NULL,
    breed VARCHAR(50),
    gender VARCHAR(10) CONSTRAINT chk_livestock_gender CHECK (gender IN ('MALE', 'FEMALE')),
    birth_date DATE,
    weight DECIMAL(7,2),
    health_status VARCHAR(20) NOT NULL DEFAULT 'HEALTHY',
    CONSTRAINT chk_livestock_health CHECK (health_status IN ('HEALTHY', 'WARNING', 'CRITICAL')),
    last_latitude DECIMAL(10,7),
    last_longitude DECIMAL(10,7),
    last_position_at TIMESTAMP,
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_livestock_farm_id ON livestock(farm_id);
CREATE INDEX idx_livestock_health ON livestock(health_status);
-- Partial unique index: livestock codes must be unique within a farm among non-deleted livestock
CREATE UNIQUE INDEX uq_livestock_farm_code_active ON livestock(farm_id, livestock_code) WHERE deleted_at IS NULL;

-- fences
CREATE TABLE fences (
    id BIGSERIAL PRIMARY KEY,
    farm_id BIGINT NOT NULL REFERENCES farms(id),
    name VARCHAR(100) NOT NULL,
    vertices JSONB NOT NULL,
    color VARCHAR(7),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT chk_fences_status CHECK (status IN ('ACTIVE', 'DISABLED')),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_fences_farm_id ON fences(farm_id);

-- alerts
CREATE TABLE alerts (
    id BIGSERIAL PRIMARY KEY,
    farm_id BIGINT NOT NULL REFERENCES farms(id),
    livestock_id BIGINT REFERENCES livestock(id),
    fence_id BIGINT REFERENCES fences(id),
    type VARCHAR(30) NOT NULL,
    CONSTRAINT chk_alerts_type CHECK (type IN ('FENCE_BREACH', 'TEMPERATURE_ABNORMAL', 'BEHAVIOR_ABNORMAL', 'ESTRUS', 'EPIDEMIC')),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    CONSTRAINT chk_alerts_status CHECK (status IN ('PENDING', 'ACKNOWLEDGED', 'HANDLED', 'ARCHIVED')),
    severity VARCHAR(10) NOT NULL DEFAULT 'WARNING',
    CONSTRAINT chk_alerts_severity CHECK (severity IN ('INFO', 'WARNING', 'CRITICAL')),
    message TEXT,
    acknowledged_by BIGINT REFERENCES users(id),
    acknowledged_at TIMESTAMP,
    handled_by BIGINT REFERENCES users(id),
    handled_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_alerts_farm_id ON alerts(farm_id);
CREATE INDEX idx_alerts_status ON alerts(status);
CREATE INDEX idx_alerts_type ON alerts(type);
