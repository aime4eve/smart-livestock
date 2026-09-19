-- NIX-219 / NIX-220: gateway registry (globally unique coordinates), RSSI-to-distance
-- quantile profiles per gateway, and GPS data-governance flag aggregates.
-- See docs/superpowers/specs/2026-09-18-gateway-position-distance-requirements.md
-- and docs/superpowers/plans/2026-09-18-gateway-position-distance-plan.md.

-- Globally unique gateway position registry. A gateway is a physical entity with one
-- position; a later marker overwrites the previous one (overwriting requires UI confirm).
CREATE TABLE gateway_registry (
    id          BIGSERIAL PRIMARY KEY,
    gateway_id  VARCHAR(128) NOT NULL UNIQUE,
    latitude    DECIMAL(10, 7) NOT NULL,
    longitude   DECIMAL(10, 7) NOT NULL,
    -- who marked it last (user id); source: APP / SEED / IMPORT
    marked_by   BIGINT,
    marked_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    source      VARCHAR(32) NOT NULL DEFAULT 'APP',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE gateway_registry IS 'LoRaWAN gateway position registry, one row per gateway_id (NIX-219)';

-- Per-gateway RSSI-to-distance quantile map (plan B inference, WiMOB19-style dynamic
-- mapping). bucket_rssi is the RSSI bucket centre in dBm (5 dB granularity, negative).
CREATE TABLE gateway_distance_profiles (
    id             BIGSERIAL PRIMARY KEY,
    gateway_id     VARCHAR(128) NOT NULL,
    bucket_rssi    INT NOT NULL,
    sample_count   INT NOT NULL,
    -- distance quantiles in metres computed from GPS-valid calibration frames
    dist_p50_m     DECIMAL(10, 2) NOT NULL,
    dist_p90_m     DECIMAL(10, 2) NOT NULL,
    window_days    INT NOT NULL DEFAULT 30,
    computed_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (gateway_id, bucket_rssi)
);

COMMENT ON TABLE gateway_distance_profiles IS 'RSSI bucket -> distance quantiles per gateway, rebuilt daily from GPS-valid frames (NIX-219 plan B)';

-- Aggregated governance flags per device/rule/day (counts only; raw frames are never
-- modified -- gps_logs keeps full history per NIX-9 spec 6.4).
CREATE TABLE gps_quality_flags (
    id           BIGSERIAL PRIMARY KEY,
    device_id    BIGINT NOT NULL,
    rule_name    VARCHAR(64) NOT NULL,
    flag_day     DATE NOT NULL,
    flag_count   INT NOT NULL DEFAULT 0,
    last_reason  VARCHAR(255),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (device_id, rule_name, flag_day)
);

CREATE INDEX idx_gps_quality_flags_day ON gps_quality_flags (flag_day);
CREATE INDEX idx_gateway_distance_profiles_gw ON gateway_distance_profiles (gateway_id);

-- F6 roaming-radius daily aggregates per device (health-profile dimension).
CREATE TABLE livestock_roam_daily (
    id               BIGSERIAL PRIMARY KEY,
    device_id        BIGINT NOT NULL,
    roam_day         DATE NOT NULL,
    max_distance_m   DECIMAL(10, 2),
    mean_distance_m  DECIMAL(10, 2),
    frame_count      INT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (device_id, roam_day)
);

CREATE INDEX idx_livestock_roam_daily_device ON livestock_roam_daily (device_id, roam_day);
