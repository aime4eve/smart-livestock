-- Platform display settings (NIX-389 Task 1): platform-level configuration
-- of how subscription-locked health tiles are presented, single-row table
-- following the subscription_health_settings pattern (V20261103100000).
-- SHOW_LOCKED (default) renders locked tiles with a lock affordance;
-- HIDE removes them from the payload consumers render. The seed row keeps
-- the pre-change behaviour identical.
CREATE TABLE platform_display_settings (
    id                BIGSERIAL PRIMARY KEY,
    locked_tile_policy VARCHAR(20) NOT NULL DEFAULT 'SHOW_LOCKED',
    CONSTRAINT chk_platform_display_policy CHECK (locked_tile_policy IN ('SHOW_LOCKED','HIDE')),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_by        VARCHAR(100)
);

INSERT INTO platform_display_settings (locked_tile_policy, updated_by) VALUES ('SHOW_LOCKED', 'seed');
