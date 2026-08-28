-- NIX-179: ThingsBoard telemetry channel device bindings.
-- One row per (device, provider); telemetry_cursor_ms is the per-device
-- "fully processed up to" boundary (epoch ms, monotonically advancing).
CREATE TABLE tb_device_bindings (
    id                   BIGSERIAL PRIMARY KEY,
    tenant_id            BIGINT       NOT NULL,
    device_id            BIGINT       NOT NULL REFERENCES devices(id),
    provider             VARCHAR(20)  NOT NULL,
    device_eui           VARCHAR(32)  NOT NULL,
    external_device_id   VARCHAR(64)  NOT NULL,
    external_device_name VARCHAR(100),
    binding_status       VARCHAR(20)  NOT NULL DEFAULT 'PENDING',
    telemetry_cursor_ms  BIGINT,
    last_event_at        TIMESTAMP,
    last_verified_at     TIMESTAMP,
    created_at           TIMESTAMP    NOT NULL DEFAULT now(),
    updated_at           TIMESTAMP    NOT NULL DEFAULT now(),
    CONSTRAINT uq_tb_bindings_provider_external UNIQUE (provider, external_device_id),
    CONSTRAINT uq_tb_bindings_device_provider UNIQUE (device_id, provider)
);

CREATE INDEX idx_tb_bindings_status ON tb_device_bindings(binding_status);

-- Seed verified bindings. INSERT..SELECT keeps them inert when the local
-- device row does not exist yet (e.g. capsules never synced from blade).
INSERT INTO tb_device_bindings
    (tenant_id, device_id, provider, device_eui, external_device_id, external_device_name, binding_status, last_verified_at)
SELECT d.tenant_id, d.id, 'THINGSBOARD', '00956906000285cf',
       '83921870-8043-11f1-8ac2-9b57e1be74c1', '00956906000285cf', 'RESOLVED', now()
FROM devices d
WHERE d.dev_eui = '00956906000285cf' AND d.deleted_at IS NULL
ON CONFLICT DO NOTHING;

INSERT INTO tb_device_bindings
    (tenant_id, device_id, provider, device_eui, external_device_id, external_device_name, binding_status, last_verified_at)
SELECT d.tenant_id, d.id, 'THINGSBOARD', '001a0103ff00027f',
       '23c574f0-4ebb-11f1-8ac2-9b57e1be74c1', '001a0103ff00027f', 'RESOLVED', now()
FROM devices d
WHERE d.dev_eui = '001a0103ff00027f' AND d.deleted_at IS NULL
ON CONFLICT DO NOTHING;
