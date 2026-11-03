-- Subscription health thresholds (NIX-324 follow-up): platform-level
-- configurable escalating-banner tiers, replacing the hardcoded 14/7/3 in
-- SubscriptionHealthEvaluator. Single-row table; the seed row keeps the
-- pre-change behaviour identical.
CREATE TABLE subscription_health_settings (
    id           BIGSERIAL PRIMARY KEY,
    warn_days    INT NOT NULL,
    caution_days INT NOT NULL,
    danger_days  INT NOT NULL,
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_by   VARCHAR(100),
    CONSTRAINT subscription_health_settings_ordered CHECK (
        warn_days > 0 AND caution_days > 0 AND danger_days > 0
        AND warn_days > caution_days AND caution_days > danger_days)
);

INSERT INTO subscription_health_settings (warn_days, caution_days, danger_days, updated_by)
VALUES (14, 7, 3, 'seed');
