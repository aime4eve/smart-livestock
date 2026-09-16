-- NIX-214: platform-level TB device profile allowlist, replacing the two
-- hardcoded constants in TbDeviceProvisioningService. Seed rows keep the
-- pre-change behaviour identical.
CREATE TABLE device_profile_rules (
    id           BIGSERIAL PRIMARY KEY,
    profile_name VARCHAR(128) NOT NULL UNIQUE,
    device_type  VARCHAR(32)  NOT NULL,
    enabled      BOOLEAN      NOT NULL DEFAULT TRUE,
    remark       VARCHAR(255),
    created_by   BIGINT,
    updated_by   BIGINT,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ  NOT NULL DEFAULT now()
);

INSERT INTO device_profile_rules (profile_name, device_type, enabled, remark) VALUES
('瘤胃胶囊-OC-配置-v2', 'CAPSULE', TRUE, '现行 OC 链路（自硬编码白名单迁移）'),
('牛羊追踪器-OC-配置-v2', 'TRACKER', TRUE, '现行 OC 链路（自硬编码白名单迁移）');
